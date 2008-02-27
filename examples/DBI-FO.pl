#!/usr/bin/perl -w
use strict;
use DBI::Library qw(:independent );
use vars qw($db $user $host $password $settings);
use CGI::QuickApp qw(header init);
use strict;
init();
*settings = \$CGI::QuickApp::settings;
print header;
my $dbh = initDB({name => $settings->{db}{name}, host => $settings->{db}{host}, user => $settings->{db}{user}, password => $settings->{db}{password},});
addexecute({title => 'select', description => 'show query', sql => "select *from <TABLE> where `title` = ?", return => "fetch_hashref",});
my $showQuery = useexecute('select', 'select');
local $/ = "<br/>\n";

foreach my $key (keys %{$showQuery}) {
        print "$key: ", $showQuery->{$key}, $/;
}

