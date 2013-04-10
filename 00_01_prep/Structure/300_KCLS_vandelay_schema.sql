-- Vandelay Schema, Inserts into import_error

-----------------------------------------------
-- Seed data for import errors
-----------------------------------------------

INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'general.unknown', oils_i18n_gettext('general.unknown', 'Import or Overlay failed', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.item.duplicate.barcode', oils_i18n_gettext('import.item.duplicate.barcode', 'Import failed due to barcode collision', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.item.invalid.circ_modifier', oils_i18n_gettext('import.item.invalid.circ_modifier', 'Import failed due to invalid circulation modifier', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.item.invalid.location', oils_i18n_gettext('import.item.invalid.location', 'Import failed due to invalid copy location', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.duplicate.sysid', oils_i18n_gettext('import.duplicate.sysid', 'Import failed due to system id collision', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.duplicate.tcn', oils_i18n_gettext('import.duplicate.sysid', 'Import failed due to system id collision', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'overlay.missing.sysid', oils_i18n_gettext('overlay.missing.sysid', 'Overlay failed due to missing system id', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.auth.duplicate.acn', oils_i18n_gettext('import.auth.duplicate.acn', 'Import failed due to Accession Number collision', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.xml.malformed', oils_i18n_gettext('import.xml.malformed', 'Malformed record cause Import failure', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'overlay.xml.malformed', oils_i18n_gettext('overlay.xml.malformed', 'Malformed record cause Overlay failure', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'overlay.record.quality', oils_i18n_gettext('overlay.record.quality', 'New record had insufficient quality', 'vie', 'description') );

INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.item.invalid.status', oils_i18n_gettext('import.item.invalid.status', 'Invalid value for "status"', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.item.invalid.price', oils_i18n_gettext('import.item.invalid.price', 'Invalid value for "price"', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.item.invalid.deposit_amount', oils_i18n_gettext('import.item.invalid.deposit_amount', 'Invalid value for "deposit_amount"', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.item.invalid.owning_lib', oils_i18n_gettext('import.item.invalid.owning_lib', 'Invalid value for "owning_lib"', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.item.invalid.circ_lib', oils_i18n_gettext('import.item.invalid.circ_lib', 'Invalid value for "circ_lib"', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.item.invalid.copy_number', oils_i18n_gettext('import.item.invalid.copy_number', 'Invalid value for "copy_number"', 'vie', 'description') );
INSERT INTO vandelay.import_error ( code, description ) VALUES ( 'import.item.invalid.circ_as_type', oils_i18n_gettext('import.item.invalid.circ_as_type', 'Invalid value for "circ_as_type"', 'vie', 'description') );

INSERT INTO vandelay.import_error ( code, description )  VALUES ( 'import.record.perm_failure', oils_i18n_gettext('import.record.perm_failure', 'Perm failure creating a record', 'vie', 'description') );
