#!perl -w

=pod

=head1 Name

data_update_driver.pl

=head1 Description

The purpose for this script is to take SQL statements that act on a lot of
data (e.g. long UPDATEs) and break them into reasonable sized chunks.  The
first partition is by the number of processes you want to run.  The size is
the total number of keys in the table divided by the number of processes.

The second partition is the number of rows you want to process at a time
within a first partition.  For instance, the number of keys and processes
may create a first partition of 10,000.  Within that, you might want to
process 500 rows at a time.

The script will start a new child process for each of the first partitions
and within those, will process I<n> number of rows, I<n> and processes 
being configurable.

=cut

use strict;
use warnings;
use v5.8;
use integer;

=head1 Modules

Modules used and what for.

Note: to load a new module into your local system, execute

	perl -MCPAN -e shell
	cpan> Module::Name
	cpan> quit

=over 4

=item DBI

All interactions with the database and SQL.

=item DBD::Pg

Specific protocol for PostGreSQL.

=item Parallel::ForkManager

Runs up to I<n> number of processes in parallel.  I<n> is set by B<--max-processes>.

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
use File::Basename;
use Getopt::Long;
use Term::ReadKey;
use Pod::Usage;

=head1 Usage

	post_update_driver.pl [--dir <directory>] [--finished-dir <dir>]
		[--database <db_name>] [--host <host_name>] 
		[--user <user_name>] [--password <password>] 
		[--exit-on-error] [--max-processes <number>] 
		[--rows <number>]

=head1 Arguments

=over 4

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

=item B<rows>

The number of rows the SQL script should process at a time.  The default
is 500.

=item B<help>

Display usage and exit.

=back  

=cut

$| = 1; #auto flush

my $dir      		= '.';
my $finished_dir	= 'finished';
my $database 		= '';
my $host     		= '';
my $user     		= '';
my $password 		= '';
my $max_processes 	= 6;
my $rows            = 500;
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
		'max-processes=i'	=> \$max_processes,	# numeric
		'rows=i'            => \$rows
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
			}
		}
	);
}

print "Removing error files...\n";
unlink glob "$dir/*.err";	

=head1 Main

Roll through each data file in B<dir> that ends with _data.sql.  Read the 
file line by line.  The first comment (--) is the script's description.
The first line that begins "SELECT MAX" is considered the id min and max 
SQL, all in one line.  The id ranges are determined by
executing this SQL.  The partition size is determined by diving the total
number of keys by B<max-process>.  

This script is responsible for creating its own wrapper function to be called
with a start id and end id, if needed.  When the script encounters a data line 
that begins
"CREATE [OR REPLACE] FUNCTION", it will start collecting lines.  It will end
when it finds a line that starts with "$$ LANGUAGE".  All of the lines between
these two, inclusive, are the create wrapper function script.  The wrapper
function should call the update function passing starting and ending ID.  You 
may not need a wrapper function if you are calling an UPDATE direectly.

The data line that starts with "DROP FUNCTION" is considered SQL to drop the
wrapper function, if needed.  It should be one line only.  You do not need this
SQL if you are not using the CREATE FUNCTION SQL.

If a data line starts with "ALTER TABLE", it is considered the enable/disable
triggers SQL statement.  All triggers are disable before running the updates
and enabled afterward.

After all of the above lines
are removed from consideration, what remains is the actual SQL update.  It is
often just a SELECT statement that calls the wrapper function with the place
holders "~start_id~" and "~end_id~".  This script will replace them with the 
values it calculates.

Comments and blank lines are ignored.

Then, start a loop for each partition size and
start a child process for each one.  Within each partision, execute the SQL
on only B<rows> number of rows.  This is determined by setting the starting 
and ending ID.  Since IDs aren't always sequential, there may be less that
B<rows> number of rows updated. 

After all partitions execute the file script is moved 
to the B<finished_dir> folder.  File scripts that encountered errors stay in
B<dir> with their error files.  Triggers are enabled.

A sample data file might look like this:

	SELECT MAX(id), MIN(id) from schema.some_table;
	
	ALTER TABLE schema.some_table DISABLE TRIGGER ALL;
	
	UPDATE schema.some_table SET col_name = something 
	WHERE id >= ~start_id~ AND id < ~end_id~;

A sample file that updates using a standard function in Evergreen might look 
like this:

	CREATE OR REPLACE FUNCTION schema.wrapper_function(start_id BIGINT, end_id BIGINT) 
	RETURNS void AS $$
	DECLARE
		rec RECORD;
	BEGIN
		FOR rec IN SELECT id, some_col FROM schema.table_to_update WHERE id >= start_id AND id < end_id 
		LOOP
			PERFORM schema.update_function( rec.id, rec.some_col );
		END LOOP;
	END;
	$$ LANGUAGE plpgsql;
	
	DROP FUNCTION IF EXISTS schema.wrapper_function(BIGINT, BIGINT);
	
	SELECT MAX(id), MIN(id) from schema.table_to_update;
	
	ALTER TABLE schema.some_table DISABLE TRIGGER ALL;
	
	SELECT schema.wrapper_function(~start_id~, ~end_id~);

=cut

print "Begin creating helper functions...\n";
my $time = time();
my @drop_func = create_helper_func( $dir, $db_params );

print "Begin executing post update scripts...\n";
my $error;

# All of these processes will run in parallel, up to $max_processes
foreach my $file ( glob "$dir/*_data.sql" ) {
	my $input_fh;
	
	# Open file 
	unless ( open ($input_fh, '<', $file) ) {
		
		# Log error on failure
		my $system_error = $!;
		my ( $fail_fh, $error_file ) = get_error_file( $file );
		print $fail_fh "Unable to open $file for reading\n";
		print $fail_fh "$system_error\n";
		close $fail_fh or warn "Could not close $error_file\n$!\n";
		warn "Unable to open $file for reading\n";
		
		next;
	}
	
	# Parse input for different SQL statements
	my ($sql, $desc, $range_sql, $create_func_sql, $drop_func_sql, $able_trigger, $truncate_sql) =
			parse_input_file( $input_fh, $file );
	
	#Truncate Table statement
	if ($truncate_sql) {
		next unless run_sql( $db_params, $truncate_sql, $file, $desc );
	}
	
	# Disable all triggers for this table
	print "Disabling triggers...\n";
	able_all_triggers( 'DISABLE', $able_trigger, $file, $db_params );
	
	# Create the function that will get called with an id range
	if ($create_func_sql) {
		next unless run_sql( $db_params, $create_func_sql, $file, $desc );
	}
	
	# Get the id ranges for this table
	print "Getting id ranges...\n";
	unless ($range_sql) { die "*** Bad input script $file, no id ranges\n" } 
	my ($max_id, $min_id) = run_select_sql( $db_params, $range_sql, $file, $desc );
	
	unless ( defined $max_id and defined $min_id ) {
		my ( $fail_fh ) = get_error_file( $file );
		print $fail_fh "Could not determine the id ranges\n"; 
		next;
	}
	
	# Break table into partitions based on id ranges and processes
	my $count = $max_id - $min_id;
	my $part_size = $count / $max_processes; # int div because of use integer
	my $print_file = basename $file;
	
	for ( my $part = 0; $part < $count; $part += $part_size ) {
		my $pid = $pm->start and next;
		print "\t$file, part $part ($pid)\n";
		my $print_file = basename $file;
			
		# Execute SQL in ranges of ids based on min/max ids
		for ( my $start_id = $part; $start_id < $part + $part_size; $start_id += $rows ) {
			
			# Set the start id in a copy of the SQL string
			(my $exec_sql = $sql) =~ s/~start_id~/$start_id/i;
						
			# The last limit will probably not be the exact rows amount
			my $left = $count - $start_id + 1;
			my $this_rows = $rows <= $left ? $rows : $left;
			$exec_sql =~ s/~end_id~/$start_id + $this_rows/ie;
			
			# Execute the SQL
			if ( run_sql($db_params, $exec_sql, $file, $desc, $start_id ) ) {
				print "\t$start_id, " . ($part + $part_size - $start_id) . 
						" left ($print_file)\n";
			} else {
				$error = 1;
				last;
			}
		}
		
		# Inform the parent process of the error
		if ($error) {
			$pm->finish(1);
			last;
		} else {
			$pm->finish;
		}
	}
	
	$pm->wait_all_children;

	# Succesful finish, move script
	unless ($error) {
		my $base = basename $file;
		my $finish_name = "$finished_dir/$base";
		 
		rename $file, $finish_name 
				or warn "*** Could not rename $file to $finish_name\n$!\n";
	}
	
	# Drop wrapper function
	if ($drop_func_sql) {
		unless ( run_sql( $db_params, $drop_func_sql, $file, $desc ) ) {
			warn "*** Could not drop wrapper function\n";
		}
	}
	
	# Enable all triggers for this table
	print "Enabling triggers...\n";
	able_all_triggers( 'ENABLE', $able_trigger, $file, $db_params );
	
	last if $error && $exit_on_error;

} # foreach file

# Drop any temporary functions used above
foreach my $drop (@drop_func) {
	run_sql($db_params, $drop, 'No file', 'Drop function' );
}
	
print 'Finished' . ($error ? ' with error' : '') . "\n";		

# Do this when the program ends, no matter what.
# A side effect of this is that time will print when each child process ends.
END {
	print_time( $time );
}

=head1 Subroutines

=head2 get_db_handle

Get a database handle

=over 4

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

=over 4

=item Parameters

B<$db_params> - the DB parameters (ref to hash)

B<$sql> - the SQL statement

B<$file> - the file name

B<$desc> - a description of the task (first comment)

B<$start_d> - the starting ID when the error occurred or zero

=item Returns

1 = success, 0 = failure

=item Side Effects

Creates a file with the extension .err if there is an error executing the SQL

=back

=cut

sub run_sql {
	my $db_params = shift;
	my $sql       = shift;
	my $file      = shift || 'no_file';
	my $desc      = shift || 'SQL Script';
	my $start_id  = shift || '0';
	
	# Sanity check
	unless ( $db_params and ref $db_params eq 'HASH' and $sql ) {
		return 0;
	}
	
	my $dbh = get_db_handle($db_params);
	
	# Catch any errors
	eval { $dbh->do($sql) };
	
	# If there were errors...
	if ($@) {
		warn "$@\n";	
		
		# Log SQL error
		my $err = $dbh->errstr;
		$dbh->rollback;
		my $rollback_err = $dbh->errstr;
		warn "*** $file rolled back\n" unless $rollback_err;
		$dbh->disconnect;
		my $disconnect_err = $dbh->errstr;
		my ( $fail_fh, $error_file ) = get_error_file( $file, $start_id );
				
		print $fail_fh "Can't execute SQL statement!\n";
		print $fail_fh "$file: $desc\n";
		print $fail_fh "$err\n";
		print $fail_fh "Rollback error: $rollback_err\n" if $rollback_err;
		print $fail_fh "Disconnect error: $disconnect_err\n" if $disconnect_err;
		close $fail_fh or warn "Could not close $error_file\n$!\n";
		warn "*** Can't execute SQL statement! $file: $desc\n";
		
		return 0;
	}
	
	$dbh->commit;
	$dbh->disconnect;
		
	return 1;
}

=head2 run_select_sql

Execute a SELECT SQL statement and fetch one column

=over 4

=item Parameters

B<$db_params> - the DB parameters (ref to hash)

B<$sql> - the SQL statement

B<$file> - the data input file name

B<$desc> - a description of the task (first comment)

B<$start_id> - the starting ID when the error occurred or zero

=item Returns

An array of column values in list context, or a reference to the array in
scalar context

=item Side Effects

Creates a file with the extension .err if there is an error executing the SQL

=back

=cut

sub run_select_sql {
	my $db_params = shift;
	my $sql       = shift;
	my $file      = shift || 'no_file';
	my $desc      = shift || 'SQL Script';
	my $start_id  = shift || '0';
	
	# Sanity check
	unless ( $db_params and ref $db_params eq 'HASH' and $sql ) {
		return 0;
	}
	
	my $dbh = get_db_handle($db_params);
	my @row;
	my $sth;
	
	eval {
		$sth = $dbh->prepare( $sql );
		$sth->execute();
		@row = $sth->fetchrow_array();
	};
	
	if ($@) {
		warn "$@\n";
		
		# Log SQL error
		my $err = $dbh->errstr;
		$dbh->disconnect;
		my $disconnect_err = $dbh->errstr;
		my ( $fail_fh, $error_file ) = get_error_file( $file, $start_id );
				
		print $fail_fh "Can't execute SQL statement!\n";
		print $fail_fh "$file: $desc\n";
		print $fail_fh "$sql\n";
		print $fail_fh "$err\n";
		print $fail_fh "Disconnect error: $disconnect_err\n" if $disconnect_err;
		close $fail_fh or warn "Could not close $error_file\n$!\n";
		warn "*** Can't execute SQL statement! $file: $desc\n";
		
		return undef;
	}
	
	$sth->finish;
	$dbh->disconnect;
	return wantarray ? @row : \@row;
}

=head2 get_error_file

Create and open an error file.  Put in a timestamp.  The error file name is
the file name with the extention of .err.

=over 4

=item Parameters

B<$file>  - the file name to create the error file for

B<$start_id> - the starting ID when the error occurred or zero 

=item Returns

An array in list context; a reference to an array in scalar context

[0] B<$fail_fh> - the file handle of the openned error file

[1] B<$error_file> - the error file name

=back

=cut

sub get_error_file {
	my $file     = shift || 'unknown';
	my $start_id = shift || '0';
	
	my ($sec, $min, $hour, $mday, $mon, $year) = (localtime(time))[0..5];
	my $timestamp = "$hour:$min:$sec " . ($mon + 1) . "-$mday-" . ($year + 1900);
	my ( $basename, $dir ) = fileparse( $file, '.sql' );
	my $error_file = "$dir$basename-$start_id.err";
	my $fail_fh;
	
	open ($fail_fh, '>>', $error_file)
			or die "Could not open $error_file for appending\n";
	print $fail_fh "$timestamp\n";
	my @return_data = ( $fail_fh, $error_file );
	
	return wantarray ? @return_data : \@return_data;
}

=head2 print_time

Print time elapsed in hours, minutes, and seconds

=over 4

=item Parameters

B<$start> - the start time, taken from the I<time()> function

=item Side Effects

Prints elasped time to the standand out

=back

=cut

sub print_time {
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

=head2 create_helper_func

Create any helper functions needed by the update.  The input data file should 
contain a commented DROP statement what will drop the function when it's not 
needed.  For example:

	-- DROP FUNCTION IF EXISTS schema.some_function(BIGINT, TEXT)
	
	CREATE OR REPLACE FUNCTION schema.some_function(id BIGINT, marc TEXT)
	...

=over 4

=item Parameters

B<$dir> - the source directory for the input data files

B<$db_params> - a hash reference to the DB parameters

=item Returns

In list context, an array of SQL DROP statements that will remove the helper 
functions at the end of the update.  In scalar context, a reference to that array.

=item Side Effects

An error file is created if an error in encountered.

=back

=cut

sub create_helper_func {
	my $dir       = shift;
	my $db_params = shift;
	my @drop_func = ();
	
	foreach my $file ( glob "$dir/*_create.sql" ) {
		
		# Open file and get SQL statement
		unless ( open (FH, '<', $file) ) {
			
			# Log error on failure
			my $system_error = $!;
			my ( $fail_fh, $error_file ) = get_error_file( $file );
			print $fail_fh "Unable to open $file for reading\n";
			print $fail_fh "$system_error\n";
			close $fail_fh or warn "Could not close $error_file\n$!\n";
			warn "*** Unable to open $file for reading\n";
			
			next;
		}
		
		my $sql = '';
		
		# Loop thru create file
		while (<FH>) {
			
			# Collect DROP FUNCs in array
			if ( /^\s*--\s*DROP\s+FUNCTION/ ) {
				s/^\s*--\s*//;
				push @drop_func, $_;
				next;
			}
			
			next if /^\s*--/; 
			next if /^\s*$/; #* this comment helps syntax highlighting
			
			$sql .= $_;
		}
		
		close FH or warn "*** Could not close $file\n$!\n";
		run_sql( $db_params, $sql, $file, 'Create function' )
				or die "*** Could not create helper file\n";
		
	} # end foreach $file
	
	return wantarray ? @drop_func : \@drop_func;
}

=head2 able_all_triggers

Enable/Disable triggers on a table.  The SQL is pulled from the input data
file line that begins "ALTER TABLE".

=over 4

=item Paramters

B<$able> - The word ENABLE or DISABLE, depending on what you want to do to
the triggers.  Defaults to DISABLE.

B<$range_sql> - The SQL statement that gets the ID ranges, previously
extracted from the input data file.

B<$file> - The name of the input data file.

B<$db_params> - The DB parameters (ref to hash)

=item Side Effects

Enables or disables triggers for a table.

=back

=cut

sub able_all_triggers {
	my $able         = shift || 'DISABLE';
	my $able_trigger = shift;
	my $file         = shift;
	my $db_params    = shift;
	
	unless ( $able =~ /ENABLE|DISABLE/i ) {
		warn "*** Bad first param in able_all_triggers()\n";
	}
	
	# Change the SQL statement to reflect enabling or disabling
	(my $sql = $able_trigger) =~ s{\b(?:ENABLE|DISABLE)\b}{\U$able\E}i;
	
	unless ( run_sql( $db_params, $sql, $file, "\L$able\E triggers" ) ) {
		warn "*** Cannot \L$able\E triggers\n";
	}
}

=head2 parse_input_file

Parse the input data file for different SQL statements and return each
statement.

=over 4

=item Parameters

B<$input_fh> - a file handle opened to the input file

B<$file> - the input file name

=item Returns

In array context, an array of all the different SQL statements parsed.  In
scalar context, a reference to that array.

[0] B<$sql> - the main updating SQL statement(s)

[1] B<$desc> - the description of this task

[2] B<$range_sql> - the SQL statement that gets the ID ranges

[3] B<$create_func_sql> - the SQL to create a wrapper function, if any   

[4] B<$drop_func_sql> - the SQL statement that drops the wrapper function, if any

[5] B<$able_trigger> - the SQL to enable/disable all triggers on the update table

=back

=cut

sub parse_input_file {
	my $input_fh = shift || return undef;
	my $file     = shift;
	
	my $sql = '';
	my $desc = '';
	my $range_sql = '';
	my $create_func_sql = '';
	my $drop_func_sql = '';
	my $able_trigger = '';
	my $truncate_sql = '';
	
	# String SQL statement together
	while (<$input_fh>) {
		
		# Kludge: remove anything that isn't ASCII 20-127 or whitespace
		# (why are we getting weird characters in front of the first line?)
		s/[^\x{21}-\x{7E}\s]//g; 
		
		# First comment is the description
		if ( $desc eq '' && /^\s*--\s*/ ) {
			chomp;
			s/^\s*--\s*//; # strip off dashes and leading whitespace
			$desc = $_;
			next;
		} 
		
		# Ignore comments and blank lines
		next if /^\s*--/; 
		next if /^\s*$/; #* this comment helps syntax highlighting
				
		# Find the min and max ids select statement
		if ( $range_sql eq '' && /^\s*SELECT\s+MAX/i ) {
			chomp;
			$range_sql = $_;
			next;
		}
		
		# Find drop function SQL
		if ( $drop_func_sql eq '' && /^\s*DROP\s+FUNCTION\s+/i ) {
			chomp;
			$drop_func_sql = $_;
			next;
		}
		
		# Find truncate SQL
		if ( $truncate_sql eq '' && /^\s*TRUNCATE\s+TABLE\s+/i ) {
			chomp;
			$truncate_sql = $_;
			next;
		}
		
		# Find enable/disable trigger statement
		if ( $able_trigger eq '' && /^\s*ALTER\s+TABLE\s+/i ) {
			chomp;
			$able_trigger = $_;
			next;
		}
		
		# Get create function SQL
		# Starts with "CREATE [OR REPLACE] FUNCTION..."
		# Ends with "$$ LANGUAGE..."
		if ( $create_func_sql eq '' && 
				/^\s*CREATE\s+(OR\s+REPLACE\s+)?FUNCTION\s+/i ) 
		{
			while (1) {
				$create_func_sql .= $_;
				defined( $_ = <$input_fh> ) 
						or die "*** Readline failed: $!\nBad input script? $file\n";
						
				if ( /^\s*\$\$\s+LANGUAGE\s+/i ) {
					$create_func_sql .= $_;
					last;
				}						
			}
			
			next;
		}
		
		# Add to execute SQL
		$sql .= $_;
		
	} # end while readline SQL file
	
	close $input_fh or warn "*** Could not close $file\n$!\n";
	
	my @return_data = ($sql, $desc, $range_sql, $create_func_sql, $drop_func_sql, $able_trigger, $truncate_sql);
	
	return wantarray ? @return_data : \@return_data;
}

__END__