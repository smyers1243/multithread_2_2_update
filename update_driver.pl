#!perl -w

=pod

=head1 Name

update_driver.pl

=head1 Description

This is the master script for running all other upgrade scripts.  It groups the
scripts together by the first three digits of the scripts' name.  Each group 
is run in parallel.  All children of a previous group finish before the next 
group is run.  This is so you can have scripts that depend on other scripts 
executing first.

=cut

use strict;
use warnings;
use utf8;
use v5.8;

=head1 Modules

Modules used and what for.

Note: to load a new module into your local system, execute

	$ perl -MCPAN -e shell
	cpan> Module::Name
	cpan> quit

=over

=item DBI

All interactions with the database and SQL.

=item DBD::Pg

Specific protocol for PostGreSQL.

=item Parallel::ForkManager

Runs up to I<n> number of processes in parallel.  I<n> is set by B<--max-processes>.

=item Try::Tiny

Use a try/catch form of statement. 

=item File::Basename

Use basename() to strip off path and extention of a file name.

=item Getopt::Long

Retrieve long command line options (e.g. --xxx) and do simple validation.

=item Term::ReadKey

Used to hide console echoing while typing in passwords.

=item Pod::Usage

Used to display usage messages that are pulled from the program's POD.

=back

=cut

use DBI;
use DBD::Pg;
use Parallel::ForkManager;
use Try::Tiny;
use File::Basename;
use Getopt::Long;
use Term::ReadKey;
use Pod::Usage;

=head1 Usage

	update_driver.pl [--dir <directory>] [--finished-dir <dir>]
		[--database <db_name>] [--host <host_name>] 
		[--user <user_name>] [--password <password>] 
		[--exit-on-error] [--max-processes <number>]

=head1 Arguments

=over

=item B<dir>

The directory containing the update scripts.  It defaults to the current 
directory.

=item B<finished-dir>

The directory where the scripts are moved to when they finish correctly.  It 
defaults to a folder called 'finished'.

=item B<database>

The database name.

=item B<host>

The host name or IP address for the database.

=item B<user>

The user name for the database.

=item B<password>

The password for the database.  If none is provided, it will ask for one.

=item B<exit-on-error>

Flag: should the script stop when it encounters an SQL error?  If not, it will
continue processing.  Regardless, an error file is created with the extension
'.err' that holds the error message.

=item B<max-processes>

Number: what is the maximum number of processes to run in parallel?  The 
default is four.

=item B<help>

Display usage and exit.

=back  

=cut

my $dir      		= '.';
my $finished_dir	= 'finished';
my $database 		= '';
my $host     		= '';
my $user     		= '';
my $password 		= '';
my $max_processes 	= 4;
my $help;
my $exit_on_error;

# Use Getopt::Long to get the command line options.  Use the POD section
# "Usage" if an option is entered incorrectly
GetOptions(
		'help!'      		=> \$help, 			# default is false...
		'exit-on-error!'	=> \$exit_on_error,	
		'dir=s'      		=> \$dir,			# strings...
		'finished-dir=s'	=> \$finished_dir,
		'database=s' 		=> \$database,
		'host=s'     		=> \$host,
		'user=s'    		=> \$user,
		'password=s' 		=> \$password,
		'max-processes=i'	=> \$max_processes	# numeric
) or pod2usage( -verbose => 99, -sections => [ 'Usage' ], -exitval => 2 );

# Print the POD Usage and Arguments sections if the help flag is up
if ($help) {
	pod2usage( 
		-verbose  => 99, 
		-sections => [ 'Usage', 'Arguments' ], 
		-exitval  => 1 );
}

=head1 Pre-loop

Get command line options.  Get password if none is supplied.  Exit if B<dir> 
does not exist.  If B<finished_dir> does not exist, create it.  Setup database 
parameters.  Test database parameters to see if they connect correctly.  If 
B<exit_on_error> is set, make a callback for the parent process so it will die 
if a child processes returns an error code.  Remove all error files.  These 
would have been created by a previous run.

=cut

# Get password if not supplied
unless ($password) {
	print "Type your password: ";
	ReadMode('noecho'); # don't display characters while typing
	chomp($password = <STDIN>);
	ReadMode(0);        # back to normal
	print "\n";
}

# Check the directories
$dir =~ s|\\|/|g; # backslashes to slashes
$dir =~ s|/$||;   # remove trailing slash
$finished_dir =~ s|\\|/|; 
$finished_dir =~ s|/$||;  

unless ( -d $dir ) {
	die "$dir does not exist\n";
}

unless ( -d $finished_dir ) {
	mkdir $finished_dir or die "Could not create $finished_dir\n$!\n";
}

# Database connect info
my $db_params = {
		platform => 'Pg', 	# Always PostGreSQL
		database => $database, 
		host     => $host, 
		port     => '5432',	# PostGres's default port
		user     => $user, 
		pw       => $password 
};	

# Check that database info is correct
my $test_dbh = get_db_handle( $db_params );
$test_dbh->disconnect;

my $pm = Parallel::ForkManager->new($max_processes);

# Callback that checks the exit status of the children.
# If we should exit on error, tell the parent to die.
if ($exit_on_error) {
	$pm->run_on_finish(
		sub { 
			my ($pid, $exit_code, $ident) = @_;
			
			if ($exit_code == 1) {
				die "Child process encountered an error in the SQL\n";
			} elsif ($exit_code == 2) {
				die "Child process encountered an error during rename\n";
			} elsif ($exit_code == 3) {
				die "Child process encounted an error opening the script file\n";
			}
		}
	);
}

print "Removing error files...\n";
unlink glob "$dir/*.err";	

=head1 Main

Slurp all files in the form 000xxx.sql, where 000 is three digits and xxx is any 
text.  Execute all files that start with 000 in parallel, then all the files 
that start with 001, then 002, etc.  All children of one group will finish 
before the childern of the next group start.  If any "digit" does not contain 
any files, it is ignored.

The files are assumed to be valid PostGreSQL files that are non-SELECT.  The 
first comment of the SQL file (--) is taken to be the description.  If the SQL
executes without error the script is moved to the finished directory.

=cut

print "Begin executing update scripts...\n";
my $time = time();

# Get a group of files to run in parallel
foreach my $digit (0..999) {

	# Group files as 000xxx.sql
	my $formatted_digit = sprintf( "%03d", $digit );
	my @files = glob "$dir/$formatted_digit*.sql";
	
	# All of these processes will run in parallel, up to $max_processes
	foreach my $file (@files) {
	
		# Forks and returns the pid for the child
		my $pid = $pm->start and next;
		
		# Open file and get SQL statement
		unless ( open (FH, '<', $file) ) {
			
			# Log error on failure
			my $system_error = $!;
			my ( $fail_fh, $error_file ) = get_error_file( $file );
			print $fail_fh "Unable to open $file for reading\n";
			print $fail_fh "$system_error\n";
			close $fail_fh or warn "Could not close $error_file\n$!\n";
			warn "Unable to open $file for reading\n";
			
			# Signal the parent that the child could not open the file
			$pm->finish(3);
		}
		
		my $sql = '';
		my $desc = '';
		
		# String SQL statement together
		while (<FH>) {
			$sql .= $_;
			
			# First comment is the description
			if ( $desc eq '' && /^\s*--\s*/ ) {
				chomp;
				s/^\s*--\s*//; # strip off dashes and leading whitespace
				$desc = $_;
			} 
		}
		
		close FH or warn "Could not close $file\n$!\n";
		
		# Execute the SQL
		print "\t$file: $desc ($pid)\n";

		if ( run_sql($db_params, $sql, $file, $desc ) ) {
		
			# Succesful finish, move script
			my $base = basename $file;
			my $finish_name = "$finished_dir/$base";
			
			if ( rename $file, $finish_name ) {
				
				# Normal termination of the child process
				$pm->finish; 
			} else {
				
				# Exit with error (rename)
				$pm->finish(2);
			}
		} else {
			
			# Exit with error (script)
			$pm->finish(1);
		}
			
	} # foreach file
	
	# Wait for all the children to finish
	$pm->wait_all_children;
	
} # foreach digit

print_time( $time );

print "Finished\n";

=head1 Subroutines

=head2 get_db_handle

Get a database handle

=over

=item Parameters 

B<$db_params> - reference to several DB parameters

=item Returns 

B<$dbh> - database handle or zero

=back

=cut

sub get_db_handle {
	my $db_params = shift || return 0;
	
	my $platform = $db_params->{platform};
	my $database = $db_params->{database};
	my $host     = $db_params->{host};
	my $port     = $db_params->{port};
	my $user     = $db_params->{user};
	my $pw       = $db_params->{pw};
	
	my $dsn = "dbi:$platform:dbname = $database; host = $host; port = $port";

	my $dbh = DBI->connect( $dsn, $user, $pw, { 
			'PrintError' => 1, 
			'RaiseError' => 1,
			'PrintWarn'  => 1, 
			'AutoCommit' => 0 # Auto commit off so we can commit/rollback
	}) or die "Unable to connect: " . $DBI::errstr . "\n";
	
	return $dbh;
}

=head2 run_sql

Execute a non-SELECT SQL statement and capture any error output

=over

=item Parameters

B<$db_params> - the DB parameters (ref to hash)

B<$sql> - the SQL statement

B<$file> - the file name

B<$desc> - a description of the task (first comment)

=item Returns

1 = success, 0 = failure

=item Side Effects

Creates a file with the extension .err if there is an error executing the SQL

=back

=cut

sub run_sql {
	my $db_params = shift;
	my $sql       = shift;
	my $file      = shift;
	my $desc      = shift || 'SQL Script';
	
	my $dbh = get_db_handle($db_params);
	
	unless (utf8::is_utf8($sql)){
		utf8::encode($sql);
	}
	
	try {
		
		$dbh->do($sql);

	} catch {
		
		# Log SQL error
		my $err = $dbh->errstr;
		$dbh->rollback;
		my $rollback_err = $dbh->errstr;
		warn "*** $file rolled back\n" unless $rollback_err;
		$dbh->disconnect;
		my $disconnect_err = $dbh->errstr;
		my ( $fail_fh, $error_file ) = get_error_file( $file );
				
		print $fail_fh "Can't execute SQL statement!\n";
		print $fail_fh "$file: $desc\n";
		print $fail_fh "$err\n";
		print $fail_fh "Rollback error: $rollback_err\n" if $rollback_err;
		print $fail_fh "Disconnect error: $disconnect_err\n" if $disconnect_err;
		close $fail_fh or warn "Could not close $error_file\n$!\n";
		warn "*** Can't execute SQL statement! $file: $desc\n";
		
		return 0;
	};
	
	# SQL execute succeeds, return true
	$dbh->commit;
	$dbh->disconnect;
		
	return 1;
		
}

=head2 get_error_file

Create and open an error file.  Put in a timestamp.  The error file name is
the file name with the extention of .err.

=over

=item Parameters

B<$file> - the file name to create the error file for

=item Returns

An array in list context; a reference to an array in scalar context

[0] B<$fail_fh> - the file handle of the openned error file

[1] B<$error_file> - the error file name

=back

=cut

sub get_error_file {
	my $file = shift || 'unknown';
	
	my ($sec, $min, $hour, $mday, $mon, $year) = (localtime(time))[0..5];
	my $timestamp = "$hour:$min:$sec " . ($mon + 1) . "-$mday-" . ($year + 1900);
	my ( $basename, $dir ) = fileparse( $file, '.sql' );
	my $error_file = "$dir$basename.err";
	my $fail_fh;
	
	open ($fail_fh, '>', $error_file)
			or die "Could not open $error_file for writing\n";
	print $fail_fh "$timestamp\n";
	my @return_data = ( $fail_fh, $error_file );
	
	return wantarray ? @return_data : \@return_data;
}

=head2 print_time

Print time elapsed in hours, minutes, and seconds

=over

=item Parameters

B<$start> - the start time, taken from the I<time()> function

=item Side Effects

Prints elasped time to the standand out

=back

=cut

sub print_time {
	use integer;
	
	my $start = shift || 0;
	my $elapsed = time() - $start;
	my $hours = $elapsed / (60 * 60);
	my $seconds = $elapsed % 60;
	my $minutes = ($elapsed - $hours * 60 * 60) / 60;
	
	print "Time elapsed: ";
	print "$hours hours, " if $hours;
	print "$minutes minutes, " if $minutes;
	print "$seconds seconds\n";
}

__END__
