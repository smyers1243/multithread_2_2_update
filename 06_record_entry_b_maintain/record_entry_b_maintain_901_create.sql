-- Function: record_entry_b_maintain_901()
-- Original function: evergreen.maintain_901()

-- DROP FUNCTION IF EXISTS biblio.record_entry_b_maintain_901(BIGINT, TEXT, TEXT, TEXT, INTEGER, INTEGER)

CREATE OR REPLACE FUNCTION biblio.record_entry_b_maintain_901(
	id 			BIGINT, 
	marc 		TEXT, 
	tcn_value 	TEXT, 
	tcn_source 	TEXT, 
	owner 		INTEGER, 
	share_depth	INTEGER
)
RETURNS void AS $BODY$
--BEGIN

use strict;
use warnings;

use MARC::Record;
use MARC::File::XML (BinaryEncoding => 'UTF-8');
use MARC::Charset;
use Encode;
use Unicode::Normalize;

MARC::Charset->assume_unicode(1);

my $schema      = 'biblio';
my $id          = shift;
my $p_marc      = shift;
my $tcn_value   = shift;
my $tcn_source  = shift;
my $owner       = shift;
my $share_depth = shift;

my $marc = MARC::Record->new_from_xml($p_marc);
my @old901s = $marc->field('901');
$marc->delete_fields(@old901s);

# Set TCN value to record ID?
my $id_as_tcn = spi_exec_query("
	SELECT enabled
	FROM config.global_flag
	WHERE name = 'cat.bib.use_id_for_tcn'
");

if (($id_as_tcn->{processed}) && $id_as_tcn->{rows}[0]->{enabled} eq 't') {
	$tcn_value = $id; 
}

my $new_901 = MARC::Field->new("901", " ", " ",
	"a" => $tcn_value,
	"b" => $tcn_source,
	"c" => $id,
	"t" => $schema
);

if ($owner) {
	$new_901->add_subfields("o" => $owner);
}

if ($share_depth) {
	$new_901->add_subfields("d" => $share_depth);
}

$marc->append_fields($new_901);
my $xml = $marc->as_xml_record();
$xml =~ s/\n//sgo;
$xml =~ s/^<\?xml.+\?\s*>//go;
$xml =~ s/>\s+</></go;
$xml =~ s/\p{Cc}//go;

# Embed a version of OpenILS::Application::AppUtils->entityize()
# to avoid having to set PERL5LIB for PostgreSQL as well

# If we are going to convert non-ASCII characters to XML entities,
# we had better be dealing with a UTF8 string to begin with
$xml = decode_utf8($xml);

# Normalize text
$xml = NFC($xml);

# Convert raw ampersands to entities
$xml =~ s/&(?!\S+;)/&amp;/gso;

# Convert Unicode characters to entities
$xml =~ s/([\x{0080}-\x{fffd}])/sprintf('&#x%X;',ord($1))/sgoe;

# Remove control characters
$xml =~ s/[\x00-\x1f]//go;

# Update record_entry
my $query = spi_exec_query("
	UPDATE biblio.record_entry 
	   SET marc = '$xml' 
	 WHERE id = $id;"
);
unless ($query->{processed}) { warn "*** UPDATE in biblio.record_entry_b_maintain_901() did not complete\n"; }

$BODY$ LANGUAGE PLPERLU;