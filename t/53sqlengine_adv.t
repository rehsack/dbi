#!perl -w
$| = 1;

use strict;
use warnings;

require DBD::DBM;

use File::Path;
use File::Spec;
use Test::More;
use Cwd;
use Config qw(%Config);
use Storable qw(dclone);

my $using_dbd_gofer = ( $ENV{DBI_AUTOPROXY} || '' ) =~ /^dbi:Gofer.*transport=/i;
plan skip_all => "Modifying driver state won't compute running behind Gofer" if($using_dbd_gofer);

use DBI;

# <[Sno]> what I could do is create a new test case where inserting into a DBD::DBM and after that clone the meta into a DBD::File $dbh
# <[Sno]> would that help to get a better picture?

do "t/lib.pl";
my $dir = test_dir();

my $dbm_dbh = DBI->connect( 'dbi:DBM:', undef, undef, {
      f_dir               => $dir,
      sql_identifier_case => 2,      # SQL_IC_LOWER
    }
);

ok( $dbm_dbh->do(q/create table FRED (a integer, b integer)/), q/create table FRED (a integer, b integer)/);
ok( $dbm_dbh->do(q/insert into fRED (a,b) values(1,2)/), q/insert into fRED (a,b) values(1,2)/);
ok( $dbm_dbh->do(q/insert into FRED (a,b) values(2,1)/), q/insert into FRED (a,b) values(2,1)/);

my $f_dbh = DBI->connect( 'dbi:File:', undef, undef, {
      f_dir               => $dir,
      sql_identifier_case => 2,      # SQL_IC_LOWER
    }
);

ok( my $dbm_fred_meta = $dbm_dbh->f_get_meta("fred", [qw(dbm_type)]), q/$dbm_dbh->f_get_meta/);
note("Switching from \$dbm_dbh to \$f_dbh");
ok( $f_dbh->f_new_meta( "fred", {sql_table_class => "DBD::DBM::Table"} ), q/$f_dbh->f_new_meta/);

my $r = $f_dbh->selectall_arrayref(q/select * from Fred/);
ok( @$r == 2, 'rows found via mixed case table' );

done_testing();
