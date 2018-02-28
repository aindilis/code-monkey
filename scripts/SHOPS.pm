package SHOPS;

use SHOPS::Util;

use BOSS::Config;

use IO::Socket;
use IO::Select;
use IO::Handle;
use Net::hostent;
use DBI;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [
    qw / Conf DBH PosHome PosVar PosSrc PosConf Debug_Mode_On
      Shoppix_Demo_Mode_On Sourceforge_Mode_On Telnet_Server_Mode_On
      ScannerDevice ScannerType InvoiceTemplateFile Invoice1File
      SalesTemplateFile Sale1File Prompt StoreName Logged_On_User
      CurrentMenu Print_Agent /
  ];

sub init {
    my ( $self, %args ) = ( shift, @_ );
    $specification = "
	-s <loc>		Start location
	-e <loc>		Finish location
	-t <time>		Start time
	-T <time>		End time
	-D <day>		Day
	-d <files>...		Data files
	-u [<host> <port>]	Run as a UniLang agent
	-r <report>		Report type
	-o <file>		Output file
	--all			Show all segments

";
    $self->Conf(
        BOSS::Config->new(
            Spec     => $specification,
            ConfFile => ""
        )
    );
    my $conf = $self->Conf->CLIConfig;

    # CONNECT TO DATABASE
    $self->DHB(
        DBI->connect(
            "DBI:mysql:database=$databaseversion;host=localhost",
            "root", "", { 'RaiseError' => 1 }
        )
    );
}

sub Start {
    my ( $self, %args ) = ( shift, @_ );

    # TELNET SERVER OPTIONS

    # If told to,  become a telnet server, normally  used with to interact
    # with testharness.pl
    if ($telnet_server_mode_on) {
        $PORT   = 9000;
        $server = IO::Socket::INET->new(
            Proto     => 'tcp',
            LocalPort => $PORT,
            Listen    => SOMAXCONN,
            Reuse     => 1
        );

        die "can't setup server" unless $server;
        print "[Server $0 accepting clients]\n";
    }

    # CALL PREMAIN
    if ($telnet_server_mode_on) {
        $self->StartServer();
    }
    else {
        $client   = STDOUT;
        $clientin = STDIN;
        $self->Premain();
    }

}

# TELNET (PREMAIN) LOOP
sub StartServer () {
    my ( $self, %args ) = ( shift, @_ );
    while ( $client = $server->accept() ) {
        $clientin = $client;
        $client->autoflush(1);
        print $client $pending;
        print $client "Welcome to SHOPS server: $0.\n";
        $hostinfo = gethostbyaddr( $client->peeraddr );
        printf "[Connect from %s]\n", $hostinfo->name || $client->peerhost;
        print $client "SHOPS: Version $version\n";

        premain();
        close $client;
    }
    return 1;
}

# PRELOADER
sub Premain {
    my ( $self, %args ) = ( shift, @_ );
    load_fields();
    log_on() unless ( $debug_mode_on || $sourceforge_mode_on );
    $self->Main();
}

# MAIN LOOP
sub Main {
    my ( $self, %args ) = ( shift, @_ );
    menu();
    while ( $response = read_from_prompt() ) {
        chomp $response;
        if ( ( $response =~ /^[0-9]+$/ )
            && element_of(
                ( $response, ( 1 .. @{ $mainmenus{$currentmenu} } ) ) ) )
        {
            my $state = $mainmenus{$currentmenu}[ $response - 1 ];
            my $match = 0;
            foreach my $key ( keys %mainmenus ) {
                $match += ( $key =~ /^$state$/ );
            }
            if ($match) {
                $currentmenu = $state;
            }
            message("$state");
            eval "$state()\n";
        }
        menu();
    }
}

################################################################################
# configuration stuff
################################################################################

sub ReadCMDLineOptions {

    # CONFIGURE PATHS
    if ($debug_mode_on) {
        $poshome = "/home/clerk/shh/shops" if !defined $poshome;
        $posvar  = "$poshome/var";
        $possrc  = "$poshome/src";
        $posconf = "$poshome/shops.conf";
    }
    elsif ( -d "/home/knoppix/.shoppix/var/lib/shops" ) {
        $poshome = "/usr/share/shops";
        $posvar  = "/home/knoppix/.shoppix/var/lib/shops";
        $possrc  = "/usr/share/shops/src";
        $posconf = "/home/knoppix/.shoppix/etc/shops/shops.conf";
    }
    else {
        $poshome = "/usr/share/shops";
        $posvar  = "/var/lib/shops";
        $possrc  = "/usr/share/shops/src";
        $posconf = "/etc/shops/shops.conf";
    }
}

sub ReadConfigFile {
    print "Using $posconf\n";
    $conf = new Config::General($posconf);
    my %config = $conf->getall;

    $self->Version( get_conf( $config{"release"}->{"version"}, "0.9.5" ) );
    $safeversion = $self->Version;
    $safeversion =~ s/\./_/g;
    $self->SafeVersion($safeversion);

    $debug_mode_on = get_conf( $config{"modes"}->{"debug_mode_on"}, 0 );
    $shoppix_demo_mode_on =
      get_conf( $config{"modes"}->{"shoppix_demo_mode_on"}, 1 );
    $sourceforge_mode_on =
      get_conf( $config{"modes"}->{"sourceforge_mode_on"}, 0 );
    $telnet_server_mode_on =
      get_conf( $config{"modes"}->{"telnet_server_mode_on"}, 0 );

    $scannerdevice =
      get_conf( $config{"hardware"}->{"scanner"}->{"device"}, 0 );
    $scannertype = get_conf( $config{"hardware"}->{"scanner"}->{"type"}, 0 );

    $thisfilename        = "$poshome/src/main.pl";
    $invoicetemplatefile = "$poshome/templates/invoice_template.html";
    $invoice1file        = "/tmp/invoice1.html";
    $salestemplatefile   = "$poshome/templates/sales_template.html";
    $sale1file           = "/tmp/sale1.html";

    $prompt = get_conf( $config{"look"}->{"prompt"}, "SHOPS> " );
    $storename =
      get_conf( $config{"look"}->{"store"}->{"name"}, "The Home Outlet" );
    $logged_on_user =
      get_conf( $config{"accounts"}->{"logged_on_user"}, "demo" );
    $currentmenu = get_conf( $config{"look"}->{"currentmenu"}, "main" );
    $print_agent =
      get_conf( $config{"hardware"}->{"printer"}->{'print_agent'}, "gv" );
}

sub get_conf {
    defined $_[0] ? return $_[0] : return $_[1];
}

sub SelectDatabase {
    $publicdb    = "public_shops_$safeversion";
    $privatedb   = "private_shops_$safeversion";
    $permanentdb = "permanent_shops_$safeversion";
    $testingdb   = "testing_shops_$safeversion";

    if ($debug_mode_on) {
        $databaseversion = $testingdb;    # if so, set database to that
    }
    elsif ( -d "/home/knoppix/.shoppix/var/lib/mysql/$permanentdb" ) {

        # check if permanent db dir exists
        $databaseversion = $permanentdb;    # if so, set database to that
    }
    else {
        if ($shoppix_demo_mode_on) {
            $pending .=
                "Run '/usr/bin/shops-installdb' as superuser to install"
              . " a permanent, writeable database.\n";
        }
        if ( -d "/var/lib/mysql/$privatedb" ) {    # private db?
            $pending .= "MESS: Using private database.\n";
            $databaseversion = $privatedb;         # if so, set database to that
        }
        else {    # otherwise, default to public version
            $pending .= "MESS: Using public database.\n";
            $databaseversion = $publicdb;    # if so, set database to that
        }
    }
    $databaseversion = $permanentdb;
}

sub ConfigureHardware {
    configure_scanner();
}

1;
