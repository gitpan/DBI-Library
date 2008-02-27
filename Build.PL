use strict;
use Module::Build;
use vars qw( $settings $skip);
my $class = Module::Build->subclass(class => "Module::Build::Custom", code => <<'END');
use lib("lib");
sub ACTION_build {
        my $self = shift;
        open OUT, ">t/config.pl" or die $!;
        print OUT "\$db = '$self->{'properties'}{dbname}';\$host = '$self->{'properties'}{sqlhost}';\$user = '$self->{'properties'}{dbuser}';\$password ='$self->{'properties'}{dbpass}';";
        close OUT;
        $self->SUPER::ACTION_build;
}

sub ACTION_install {
        my $self = shift;
        my %conf = (name => $self->{'properties'}{dbname}, host => $self->{'properties'}{sqlhost}, user => $self->{'properties'}{dbuser},);
        $conf{password} = $self->{'properties'}{dbpass} unless $self->{'properties'}{dbpass} =~ /^$/;
        use DBI::Library;
        my ($database,$dbH) = new DBI::Library(\%conf);
        $database->void(
                q/CREATE TABLE IF NOT EXISTS querys (
title varchar(100) NOT NULL default '',
description text NOT NULL,
`sql` text NOT NULL,
`return` varchar(100) NOT NULL default 'fetch_array',
`id` int(11) NOT NULL auto_increment,
PRIMARY KEY  (id)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;/
        );
        $self->SUPER::ACTION_install;
}

sub ACTION_uninstall {
        my $self = shift;
        my %conf = (name => $self->{'properties'}{dbname}, host => $self->{'properties'}{sqlhost}, user => $self->{'properties'}{dbuser},);
        use DBI::Library;
        my ($database,$dbH) = new DBI::Library(\%conf);
        $conf{password} = $self->{'properties'}{dbpass} unless $self->{'properties'}{dbpass} =~ /^$/;
        $database->void(" DROP TABLE `querys`");
}

sub ACTION_realclean {
        my $self = shift;
        unlink('t/config.pl');
        $self->SUPER::ACTION_realclean;
}

sub ACTION_test {
        print "run testdb after installation $/
Don`t forgot do run realclean after testing,$/
setup will save settings as cleantext $/
";
}

sub ACTION_testdb {
        my $self = shift;
        $self->SUPER::ACTION_test;
}
END
my $inctance = $class->new(
        get_options => {skip => {store => \$skip},},
        module_name => 'DBI::Library',
        requires => {'DBI' => ">=1.50", 'Test::More' => ">=0.7", 'Module::Build' => ">=0.2808", 'Test::Pod' => ">=1.26", 'Test::Pod::Coverage' => ">=0.55",},
        ($] >= 5.005 ? (AUTHOR => 'Dirk Lindner <lze@cpan.org>') : ()),
        dist_abstract      => "A simple DBI subclass",
        license            => "lgpl",
        create_makefile_pl => 'passthrough',
);
eval 'use CGI::QuickApp::Settings qw($settings loadSettings saveSettings)';
unless ($@) {
        loadSettings();
        *settings = \$CGI::QuickApp::Settings::settings;
        $inctance->{properties}{dbname}  = $settings->{database}{name} ? $settings->{database}{name} : 'LZE';
        $inctance->{properties}{dbuser}  = $settings->{database}{user}     ? $settings->{database}{user} : 'root';
        $inctance->{properties}{sqlhost} = $settings->{database}{host}     ? $settings->{database}{host}     : 'localhost';
        $inctance->{properties}{dbpass}  = $settings->{database}{password} ? $settings->{database}{password} : '';
}

$inctance->{properties}{dbname}  = $inctance->args('dbname')  if $inctance->args('dbname');
$inctance->{properties}{dbuser}  = $inctance->args('dbuser')  if $inctance->args('dbuser');
$inctance->{properties}{sqlhost} = $inctance->args('sqlhost') if $inctance->args('sqlhost');
$inctance->{properties}{dbpass}  = $inctance->args('dbpass')  if $inctance->args('dbpass');

unless ($skip) {
        $inctance->{properties}{dbname}  = Module::Build->prompt("Enter your Database Name:",     $inctance->{properties}{dbname});
        $inctance->{properties}{dbuser}  = Module::Build->prompt("Enter your User Name:",         $inctance->{properties}{dbuser});
        $inctance->{properties}{sqlhost} = Module::Build->prompt("Enter your host:",              $inctance->{properties}{sqlhost});
        $inctance->{properties}{dbpass}  = Module::Build->prompt("Enter your Database password:", $inctance->{properties}{dbpass});
}

$inctance->create_build_script;
print "
run ./Build && sudo ./Build install && ./Build testdb && ./Build realclean
Don`t forgot do run realclean after testing,
setup will save settings as plaintext
";
