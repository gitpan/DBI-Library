package DBI::Library;
use strict;
use warnings;
use vars qw( $dbh $dsn $DefaultClass $settings  @EXPORT_OK @ISA %functions $style $right $tbl);
$DefaultClass = 'DBI::Library' unless defined $DBI::Library::DefaultClass;
@DBI::Library::EXPORT_OK = qw( useexecute quote void fetch_hashref fetch_AoH fetch_array updateModules deleteexecute editexecute addexecute tableLength tableExists initDB $dsn $dbh selectTable);
%DBI::Library::EXPORT_TAGS = (
                              'all'         => [qw( useexecute quote void fetch_hashref fetch_AoH fetch_array updateModules deleteexecute editexecute addexecute tableLength tableExists initDB selectTable)],
                              'dynamic'     => [qw( useexecute void fetch_hashref fetch_AoH fetch_array updateModules deleteexecute editexecute addexecute selectTable)],
                              'independent' => [qw(tableLength tableExists initDB useexecute void fetch_hashref fetch_AoH fetch_array updateModules deleteexecute editexecute addexecute selectTable)],
);
$DBI::Library::VERSION = '0.27';
$tbl                   = 'querys';
require Exporter;
use DBI;

# @DBI::Library::ISA = qw( Exporter DBI);

use base qw/Exporter DBI/;

# use Exporter qw/import/;

=head1 NAME

DBI::Library

=head1 SYNOPSIS

FO Syntax

use DBI::Library qw(:all);

my $dbh = initDB({name => 'LZE',host => 'localhost',user => 'root',password =>'',style=> 'Crystal'});



OO Syntax

use DBI::Library;

        my $database = new DBI::Library(

                {

                name =>'LZE',

                host => 'localhost',

                user => 'root',

                password =>'',

                style=> 'Crystal'

                }

        );

        my %execute  = (

                title => 'showTables',

                description => 'description',

                sql => "show tables",

                return => "fetch_array",

        );

        $database->addexecute(\%execute);

        $database->showTables();

=head2 Export Tags

:all 
        execute useexecute quote void fetch_hashref fetch_AoH fetch_array updateModules deleteexecute editexecute       addexecute tableLength tableExists initDB

:dynamic execute useexecute void fetch_hashref fetch_AoH fetch_array updateModules deleteexecute editexecute addexecute

independent: tableLength tableExists initDB :dynamic

=head1 DESCRIPTION

DBI::Library is a DBI subclass providing a SQL Libary.

This Module is mainly written for CGI::QuickApp::Blog,

but there is no reason to use it not standalone.

Also it is much more easier

to update, test and distribute the parts standalone.


=head2 new()

        my $database = new DBI::Library();

        if y
        my ($database,$dbh) = new DBI::Library(

                                        {

                                        name => $db,

                                        host => $host,

                                        user => $user,

                                        password => $password,

                                        }

        );

=cut

sub new {
        my ($class, @initializer) = @_;
        my $self = {};
        my $dbh;
        bless $self, ref $class || $class || $DefaultClass;
        $dbh = $self->initDB(@initializer) if(@initializer);
        return ($self, $dbh) if $dbh;
        return $self;
}

=head2 initDB()

        my $dbh = initDB(

                {

                name => 'LZE',

                host => 'localhost',

                user => 'root',

                password =>'',

                }
        );

=cut

sub initDB {
        my ($self, @p) = getSelf(@_);
        my $hash     = $p[0];
        my $database = defined $hash->{name} ? $hash->{name} : 'LZE';
        my $host     = defined $hash->{host} ? $hash->{host} : 'localhost';
        my $user     = defined $hash->{user} ? $hash->{user} : 'root';
        my $pass     = defined $hash->{password} ? $hash->{password} : '';
        my $install  = defined $hash->{install} ? $hash->{install} : 0;
        $style = defined $hash->{style} ? $hash->{style} : 'Crystal';
        $dsn   = "DBI:mysql:database=$database;host=$host";
        $dbh   = DBI::Library->connect($dsn, $user, $pass, {RaiseError => 1, PrintError => 0, AutoCommit => 1,}) or warn "DBI::Library::errs";

        unless ($install) {
                my @q = $self->fetch_array("select title from querys");
                $functions{$_} = $_ foreach (@q);
        }
        return $dbh;
}

=head1 independent functions

=head2  tableExists()

$bool =  $database->tableExists($table);

=cut

sub tableExists {
        my ($self, @p) = getSelf(@_);
        my $table     = $dbh->quote($p[0]);
        my $db_clause = "";
        ($db_clause, $table) = (" FROM $1", $2) if $table =~ /(.*)\.(.*)/;
        return ($dbh->selectrow_array("SHOW TABLES $db_clause LIKE $table"));
}

=head2 tableLength

$length  = $database->tableLength($table);

=cut

sub tableLength {
        my ($self, @p) = getSelf(@_);
        my $table = $dbh->quote_identifier($p[0]);
        my $sql   = "select count(*) from $table";
        if($self->tableExists($p[0])) {
                my $sth = $dbh->prepare($sql) or warn $dbh->errstr;
                $sth->execute() or warn $dbh->errstr;
                my $length = $sth->fetchrow_array;
                $sth->finish();
                return $length;
        } else {
                return 0;
        }
}

=head1 dynamic statements

=head2  addexecute()

add sql statments to yourdatabase for later use witdh useexecute();

        my %execute  = (

                title => 'showTables',

                description => 'description',

                sql => "show tables",

                return => "fetch_array",

        );

        $database->addexecute(\%execute);

        print join '<br/>' ,$database->showTables();

Fo Syntax:

        print join '<br/>' , useexecute('showTables');

=cut

sub addexecute {
        my ($self, @p) = getSelf(@_);
        my $hash        = $p[0];
        my $title       = ((defined $hash->{title})) ? $hash->{title} : 0;
        my $sql         = $hash->{sql} if((defined $hash->{sql}));
        my $description = $hash->{description} if(defined $hash->{description});
        my $return      = $hash->{'return'} if(defined $hash->{'return'});
        unless ($functions{$title}) {
                my $sql_addexecute = qq/INSERT INTO querys(`title`,`sql`,`description`,`return`) VALUES(?,?,?,?);/;
                my $sth            = $dbh->prepare($sql_addexecute);
                $sth->execute($title, $sql, $description, $return) or warn $dbh->errstr;
                $sth->finish();
                $self->updateModules();
        } else {
                return 0;
        }
}

=head2 editexecute

        my %hash = (

                title => 'Titel',

                newTitle => 'New Titel',

                description => 'querys Abfragen',

                sql => "sql statement",

                return => 'fetch_hashref', #subname

        );

        editexecute(\%hash);

=cut

sub editexecute {
        my ($self, @p) = getSelf(@_);
        my $hash        = $p[0];
        my $title       = ((defined $hash->{title})) ? $hash->{title} : 0;
        my $newTitle    = ((defined $hash->{newTitle})) ? $hash->{newTitle} : $title;
        my $sql         = $hash->{sql} if((defined $hash->{sql}));
        my $description = $hash->{description} if(defined $hash->{description});
        my $return      = (defined $hash->{'return'}) ? $hash->{'return'} : 'array';

        if($functions{$title}) {
                my $sql_edit = qq(update querys set title = ?, sql=? ,description=?,return=? where title = ? );
                my $sth      = $dbh->prepare($sql_edit);
                $sth->execute($newTitle, $sql, $description, $return, $title) or warn $dbh->errstr;
                $sth->finish();

        } else {
                return 0;
        }
}

=head2 useexecute()

        useexecute($title,optional hashref {identifier => {1 => 'news', 2 => 'querys'}  , @parameter);

example:

        my %execute = (

                title => 'joins',

                description => 'description',

                sql => 'select * from table_1 JOIN  table_2 ',

                return => "fetch_hashref"

        );

        $database->addexecute(\%execute5);

        my $ref = $database->joins({identifier => {1 => 'news', 2 => 'querys'}});

=cut

sub useexecute {
        my ($self, @p) = getSelf(@_);
        my $title = shift(@p);
        my $ref;
        if(ref $p[0] eq 'HASH') {
                $ref = shift(@p);
        }
        my $sql = "select `sql`,`return` from querys where `title` = ?";
        my $sth = $dbh->prepare($sql);
        $sth->execute($title) or warn $dbh->errstr;
        my ($sqlexec, $return) = $sth->fetchrow_array();
        $sqlexec =~ s/<TABLE>/$tbl/g;
        if(ref $ref eq 'HASH') {
                foreach my $key (keys %{$ref->{identifier}}) {
                        $sqlexec =~ s/table_$key/$dbh->quote_identifier($ref->{identifier}{$key})/ge;
                }
        }
        $sth->finish();
        return eval(" \$self->$return(\$sqlexec,\@p)");
}

=head2 deleteexecute()

        deleteexecute($title);

=cut

sub deleteexecute {
        my ($self, @p) = getSelf(@_);
        my $id         = $p[0];
        my $sql_delete = "DELETE FROM querys Where title  = ?";
        my $sth        = $dbh->prepare($sql_delete);
        $sth->execute($id) or warn $dbh->errstr;
        $sth->finish();
}

=head2 fetch_array()

        @A = $database->fetch_array($sql);

=cut

sub fetch_array {
        my ($self, @p) = getSelf(@_);
        my $sql = shift @p;
        my @r;
        eval('
my $sth = $dbh->prepare($sql);
if(defined $p[0]) {
$sth->execute(@p) or warn $dbh->errstr;
}else {
$sth->execute() or warn $dbh->errstr;
}
while(my @comms = $sth->fetchrow_array()) {
push(@r, @comms);
}
$sth->finish();');
        @r = $@ if $@;
        return @r;
}

=head2 fetch_AoH()

@aoh = $database->fetch_AoH($sql)

=cut

sub fetch_AoH {
        my ($self, @p) = getSelf(@_);
        my $sql = shift @p;
        my @r;
        eval('
my $sth = $dbh->prepare($sql);
if(defined $p[0]) {
$sth->execute(@p) or warn $dbh->errstr;
} else {
$sth->execute() or warn $dbh->errstr;
}
while(my $h = $sth->fetchrow_hashref) {
push(@r, $h);
}
$sth->finish();');
        @r = $@ if $@;
        return @r;
}

=head2 fetch_hashref()

$hashref = $database->fetch_hashref($sql)

=cut

sub fetch_hashref {
        my ($self, @p) = getSelf(@_);
        my $sql = shift @p;
        my $h;
        eval('
my $sth = $dbh->prepare($sql);
if(defined $p[0]) {
$sth->execute(@p) or warn $dbh->errstr;
} else {
$sth->execute() or warn $dbh->errstr;
}
my @r;
$h = $sth->fetchrow_hashref();
$sth->finish();
');
        $h = "$@" if $@;
        return $h;
}

=head2 void()

void(sql)

=cut

sub void {
        my ($self, @p) = getSelf(@_);
        my $sql = shift @p;
        my $sth = $dbh->prepare($sql);
        eval('
if(defined $p[0]) {
$sth->execute(@p) or warn $dbh->errstr;
} else {
$sth->execute() or warn $dbh->errstr;
}');
        $sth->finish();
        return "$@" if $@;
}

=head2 quote()

        $quotedString = $database->quote($sql);

=cut

sub quote {
        my ($self, @p) = getSelf(@_);
        my $sql = $p[0];
        return $dbh->quote($sql);
}

=head2 selectTable

set a placeholder wihich is usesd by dynmaic statements.

<TABLE> will be replaced width this value.

default : querys;

=cut

sub selectTable {
        my ($self, @p) = getSelf(@_);
        $tbl = $dbh->quote_identifier($p[0]);
}

=head1 Privat

=head2 updateModules()

=cut

sub updateModules {
        my ($self, @p) = getSelf(@_);
        my @q = $self->fetch_array("select title from querys");
        $functions{$_} = $_ foreach (@q);
}

=head2 getSelf()

=cut

sub getSelf {
        return @_ if defined($_[0]) && (!ref($_[0])) && ($_[0] eq 'DBI::Library');
        return (defined($_[0]) && (ref($_[0]) eq 'DBI::Library' || UNIVERSAL::isa($_[0], 'DBI::Library'))) ? @_ : ($DBI::Library::DefaultClass->new, @_);
}

=head2 AUTOLOAD()

statements add by addexecute can called like 

$database->showTables()

=cut

sub AUTOLOAD {
        my ($self, @p) = getSelf(@_);
        our $AUTOLOAD;
        if($AUTOLOAD =~ /.*::(\w+)$/ and grep $1 eq $_, %functions) {
                my $attr = $1;
                {
                        no strict 'refs';
                        *{$AUTOLOAD} = sub {
                                $self->useexecute($attr, @p);
                        };
                }
                goto &{$AUTOLOAD};
        }
}

package DBI::Library::db;
use vars qw(@ISA);
@ISA = qw(DBI::db);

=head2 prepare()


=cut

sub prepare {
        my ($dbh, @args) = @_;
        my $sth = $dbh->SUPER::prepare(@args) or return;
        return $sth;
}

package DBI::Library::st;
use vars qw(@ISA);
@ISA = qw(DBI::st);

=head2 execute()


=cut

sub execute {
        my ($sth, @args) = @_;
        my $rv;
        eval('$rv = $sth->SUPER::execute(@args)');
        return "$@" if $@;
        return $rv;
}

=head2 fetch()


=cut

sub fetch {
        my ($sth, @args) = @_;
        my $row = $sth->SUPER::fetch(@args) or return;
        return $row;
}

=head1 AUTHOR

Dirk Lindner <lze@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Hr. Dirk Lindner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation; 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

=cut

1;
