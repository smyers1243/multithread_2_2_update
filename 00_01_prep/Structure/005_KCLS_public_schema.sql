-- Init Public Schema

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;

DROP FUNCTION IF EXISTS public.remove_insignificants(text);
CREATE OR REPLACE FUNCTION public.remove_insignificants(text) RETURNS text AS $func$
	my $str = shift;
	my @char_array = split ('', $str);
	
		if($char_array[2] eq ' ' && $char_array[1] eq 'n' && $char_array[0] eq 'a'){
			$str =~ s/^an //;
		}elsif($char_array[1] eq ' ' && $char_array[0] eq 'a'){
			$str =~ s/^a //;
		}elsif($char_array[3] eq ' ' && $char_array[2] eq 'e' && $char_array[1] eq 'h' && $char_array[0] eq 't'){
			$str =~ s/^the //;
		}
		
	return $str;
		
$func$ LANGUAGE 'plperlu' IMMUTABLE STRICT;