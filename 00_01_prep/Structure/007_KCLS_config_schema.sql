-- Config schema, pre inits

CREATE TRIGGER no_overlapping_sups
    BEFORE INSERT OR UPDATE ON config.db_patch_dependencies
    FOR EACH ROW EXECUTE PROCEDURE evergreen.array_overlap_check ('supersedes');

CREATE TRIGGER no_overlapping_deps
    BEFORE INSERT OR UPDATE ON config.db_patch_dependencies
    FOR EACH ROW EXECUTE PROCEDURE evergreen.array_overlap_check ('deprecates');
	
INSERT into config.org_unit_setting_type
( name, label, description, datatype ) VALUES
( 'circ.checkout_fills_related_hold_exact_match_only',
    'Checkout Fills Related Hold On Valid Copy Only',
    'When filling related holds on checkout only match on items that are valid for opportunistic capture for the hold. Without this set a Title or Volume hold could match when the item is not holdable. With this set only holdable items will match.',
    'bool');

	INSERT INTO config.org_unit_setting_type ( name, label, description, datatype ) VALUES (
    'org.patron_opt_boundary',
    oils_i18n_gettext( 
        'org.patron_opt_boundary',
        'Circ: Patron Opt-In Boundary',
        'coust',
        'label'
    ),
    oils_i18n_gettext( 
        'org.patron_opt_boundary',
        'This determines at which depth above which patrons must be opted in, and below which patrons will be assumed to be opted in.',
        'coust',
        'label'
    ),
    'integer'
);

INSERT INTO config.org_unit_setting_type ( name, label, description, datatype ) VALUES (
    'org.patron_opt_default',
    oils_i18n_gettext( 
        'org.patron_opt_default',
        'Circ: Patron Opt-In Default',
        'coust',
        'label'
    ),
    oils_i18n_gettext( 
        'org.patron_opt_default',
        'This is the default depth at which a patron is opted in; it is calculated as an org unit relative to the current workstation.',
        'coust',
        'label'
    ),
    'integer'
);

--INSERT INTO config.index_normalizer (name, description, func, param_count) VALUES (
--    'Generic Mapping Normalizer', 
--    'Map values or sets of values to new values',
--    'generic_map_normalizer', 
--    1
--);
--Record already existed without description.  Changed to update
UPDATE config.index_normalizer SET description = 'Map values or sets of values to new values'
WHERE name = 'Generic Mapping Normalizer';

INSERT INTO config.org_unit_setting_type ( name, label, description, datatype ) 
    VALUES ( 
        'cat.volume.delete_on_empty',
        oils_i18n_gettext('cat.volume.delete_on_empty', 'Cat: Delete volume with last copy', 'coust', 'label'),
        oils_i18n_gettext('cat.volume.delete_on_empty', 'Automatically delete a volume when the last linked copy is deleted', 'coust', 'description'),
        'bool'
    );
	
INSERT INTO config.org_unit_setting_type ( name, label, description, datatype ) VALUES (
    'circ.transit.min_checkin_interval',
    oils_i18n_gettext( 
        'circ.transit.min_checkin_interval', 
        'Circ:  Minimum Transit Checkin Interval',
        'coust',
        'label'
    ),
    oils_i18n_gettext( 
        'circ.transit.min_checkin_interval', 
        'In-Transit items checked in this close to the transit start time will be prevented from checking in',
        'coust',
        'label'
    ),
    'interval'
);
	
INSERT INTO config.org_unit_setting_type ( name, label, description, datatype ) VALUES (
    'circ.lost.generate_overdue_on_checkin',
    oils_i18n_gettext( 
        'circ.lost.generate_overdue_on_checkin',
        'Circ:  Lost Checkin Generates New Overdues',
        'coust',
        'label'
    ),
    oils_i18n_gettext( 
        'circ.lost.generate_overdue_on_checkin',
        'Enabling this setting causes retroactive creation of not-yet-existing overdue fines on lost item checkin, up to the point of checkin time (or max fines is reached).  This is different than "restore overdue on lost", because it only creates new overdue fines.  Use both settings together to get the full complement of overdue fines for a lost item',
        'coust',
        'label'
    ),
    'bool'
);

INSERT INTO config.org_unit_setting_type ( name, label, description, datatype ) 
    VALUES ( 
        'ui.circ.billing.uncheck_bills_and_unfocus_payment_box',
        oils_i18n_gettext(
            'ui.circ.billing.uncheck_bills_and_unfocus_payment_box',
            'GUI: Uncheck bills by default in the patron billing interface',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'ui.circ.billing.uncheck_bills_and_unfocus_payment_box',
            'Uncheck bills by default in the patron billing interface,'
            || ' and focus on the Uncheck All button instead of the'
            || ' Payment Received field.',
            'coust',
            'description'
        ),
        'bool'
    );
--records below already existed.  updating description for safety.
UPDATE config.org_unit_setting_type SET description = oils_i18n_gettext(
            'circ.offline.skip_checkout_if_newer_status_changed_time',
            'Skip offline checkout transaction (raise exception when'
            || ' processing) if item Status Changed Time is newer than the'
            || ' recorded transaction time.  WARNING: The Reshelving to'
            || ' Available status rollover will trigger this.',
            'coust',
            'description'
        )
WHERE label = 'Offline: Skip offline renewal if newer item Status Changed Time.';
UPDATE config.org_unit_setting_type set description = oils_i18n_gettext(
            'circ.offline.skip_renew_if_newer_status_changed_time',
            'Skip offline renewal transaction (raise exception when'
            || ' processing) if item Status Changed Time is newer than the'
            || ' recorded transaction time.  WARNING: The Reshelving to'
            || ' Available status rollover will trigger this.',
            'coust',
            'description'
        )
WHERE label = 'Offline: Skip offline renewal if newer item Status Changed Time.';

UPDATE config.org_unit_setting_type set description = oils_i18n_gettext(
            'circ.offline.skip_checkin_if_newer_status_changed_time',
            'Skip offline checkin transaction (raise exception when'
            || ' processing) if item Status Changed Time is newer than the'
            || ' recorded transaction time.  WARNING: The Reshelving to'
            || ' Available status rollover will trigger this.',
            'coust',
            'description'
        )
WHERE label = 'Offline: Skip offline checkin if newer item Status Changed Time.';
--INSERT INTO config.org_unit_setting_type ( name, label, description, datatype ) 
--    VALUES --( 
--       'circ.offline.skip_checkout_if_newer_status_changed_time',
--       oils_i18n_gettext(
--            'circ.offline.skip_checkout_if_newer_status_changed_time',
--            'Offline: Skip offline checkout if newer item Status Changed Time.',
--            'coust',
--            'label'
--        ),
--        oils_i18n_gettext(
--            'circ.offline.skip_checkout_if_newer_status_changed_time',
--            'Skip offline checkout transaction (raise exception when'
--            || ' processing) if item Status Changed Time is newer than the'
--            || ' recorded transaction time.  WARNING: The Reshelving to'
--            || ' Available status rollover will trigger this.',
--            'coust',
--            'description'
--        ),
--        'bool'
--    ),
--	( 
--        'circ.offline.skip_renew_if_newer_status_changed_time',
--        oils_i18n_gettext(
--            'circ.offline.skip_renew_if_newer_status_changed_time',
--            'Offline: Skip offline renewal if newer item Status Changed Time.',
--            'coust',
--            'label'
--        ),
--        oils_i18n_gettext(
--            'circ.offline.skip_renew_if_newer_status_changed_time',
--            'Skip offline renewal transaction (raise exception when'
--            || ' processing) if item Status Changed Time is newer than the'
--            || ' recorded transaction time.  WARNING: The Reshelving to'
--            || ' Available status rollover will trigger this.',
--            'coust',
--            'description'
--        ),
--        'bool'
--    ),
--	( 
--        'circ.offline.skip_checkin_if_newer_status_changed_time',
--        oils_i18n_gettext(
--            'circ.offline.skip_checkin_if_newer_status_changed_time',
--            'Offline: Skip offline checkin if newer item Status Changed Time.',
--            'coust',
--            'label'
--        ),
--        oils_i18n_gettext(
--            'circ.offline.skip_checkin_if_newer_status_changed_time',
--            'Skip offline checkin transaction (raise exception when'
--            || ' processing) if item Status Changed Time is newer than the'
--            || ' recorded transaction time.  WARNING: The Reshelving to'
--            || ' Available status rollover will trigger this.',
--            'coust',
--            'description'
--        ),
--        'bool'
--    );
	
INSERT INTO config.org_unit_setting_type ( name, label, description, datatype )
    VALUES (
        'ui.patron_search.result_cap',
        oils_i18n_gettext(
            'ui.patron_search.result_cap',
            'GUI: Cap results in Patron Search at this number.',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'ui.patron_search.result_cap',
            'So for example, if you search for John Doe, normally you would get'
            || ' at most 50 results.  This setting allows you to raise or lower'
            || ' that limit.',
            'coust',
            'description'
        ),
        'integer'
    );

INSERT INTO config.org_unit_setting_type ( name, label, description, datatype ) VALUES (
    'acq.copy_creator_uses_receiver',
    oils_i18n_gettext( 
        'acq.copy_creator_uses_receiver',
        'Acq: Set copy creator as receiver',
        'coust',
        'label'
    ),
    oils_i18n_gettext( 
        'acq.copy_creator_uses_receiver',
        'When receiving a copy in acquisitions, set the copy "creator" to be the staff that received the copy',
        'coust',
        'label'
    ),
    'bool'
);

INSERT into config.org_unit_setting_type
( name, label, description, datatype ) VALUES
(
        'circ.staff_client.receipt.header_text',
        oils_i18n_gettext(
            'circ.staff_client.receipt.header_text',
            'Receipt Template: Content of header_text include',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'circ.staff_client.receipt.header_text',
            'Text/HTML/Macros to be inserted into receipt templates in place of %INCLUDE(header_text)%',
            'coust',
            'description'
        ),
        'string'
    )
,(
        'circ.staff_client.receipt.footer_text',
        oils_i18n_gettext(
            'circ.staff_client.receipt.footer_text',
            'Receipt Template: Content of footer_text include',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'circ.staff_client.receipt.footer_text',
            'Text/HTML/Macros to be inserted into receipt templates in place of %INCLUDE(footer_text)%',
            'coust',
            'description'
        ),
        'string'
    )
,(
        'circ.staff_client.receipt.notice_text',
        oils_i18n_gettext(
            'circ.staff_client.receipt.notice_text',
            'Receipt Template: Content of notice_text include',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'circ.staff_client.receipt.notice_text',
            'Text/HTML/Macros to be inserted into receipt templates in place of %INCLUDE(notice_text)%',
            'coust',
            'description'
        ),
        'string'
    )
,(
        'circ.staff_client.receipt.alert_text',
        oils_i18n_gettext(
            'circ.staff_client.receipt.alert_text',
            'Receipt Template: Content of alert_text include',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'circ.staff_client.receipt.alert_text',
            'Text/HTML/Macros to be inserted into receipt templates in place of %INCLUDE(alert_text)%',
            'coust',
            'description'
        ),
        'string'
    )
,(
        'circ.staff_client.receipt.event_text',
        oils_i18n_gettext(
            'circ.staff_client.receipt.event_text',
            'Receipt Template: Content of event_text include',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'circ.staff_client.receipt.event_text',
            'Text/HTML/Macros to be inserted into receipt templates in place of %INCLUDE(event_text)%',
            'coust',
            'description'
        ),
        'string'
    );

UPDATE config.org_unit_setting_type SET description = E'The Regular Expression for validation on the day_phone field in patron registration. Note: The first capture group will be used for the "last 4 digits of phone number" feature, if enabled. Ex: "[2-9]\\d{2}-\\d{3}-(\\d{4})( x\\d+)?" will ignore the extension on a NANP number.' WHERE name = 'ui.patron.edit.au.day_phone.regex';

UPDATE config.org_unit_setting_type SET description = 'The Regular Expression for validation on phone fields in patron registration. Applies to all phone fields without their own setting. NOTE: See description of the day_phone regex for important information about capture groups with it.' WHERE name = 'ui.patron.edit.phone.regex';

UPDATE config.org_unit_setting_type SET description = oils_i18n_gettext('patron.password.use_phone', 'By default, use the last 4 alphanumeric characters of the patrons phone number as the default password when creating new users.  The exact characters used may be configured via the "GUI: Regex for day_phone field on patron registration" setting.', 'coust', 'description') WHERE name = 'patron.password.use_phone';

	
	INSERT INTO config.org_unit_setting_type (name, label, description, datatype)
  VALUES ('booking.allow_email_notify', 'booking.allow_email_notify', 'Permit email notification when a reservation is ready for pickup.', 'bool');

INSERT INTO config.metabib_field ( id, field_class, name, label, format, xpath, search_field, facet_field) VALUES
    (28, 'identifier', 'authority_id', oils_i18n_gettext(28, 'Authority Record ID', 'cmf', 'label'), 'marcxml', '//marc:datafield/marc:subfield[@code="0"]', FALSE, TRUE);

	INSERT INTO config.marc21_rec_type_map (code, type_val, blvl_val) VALUES ('AUT','z',' ');
INSERT INTO config.marc21_rec_type_map (code, type_val, blvl_val) VALUES ('MFHD','uvxy',' ');
 
INSERT INTO config.marc21_ff_pos_map (fixed_field, tag, rec_type,start_pos, length, default_val) VALUES ('ELvl', 'ldr', 'AUT', 17, 1, ' ');
INSERT INTO config.marc21_ff_pos_map (fixed_field, tag, rec_type,start_pos, length, default_val) VALUES ('Subj', '008', 'AUT', 11, 1, '|');
INSERT INTO config.marc21_ff_pos_map (fixed_field, tag, rec_type,start_pos, length, default_val) VALUES ('RecStat', 'ldr', 'AUT', 5, 1, 'n');
 
INSERT INTO config.metabib_field_index_norm_map (field,norm,pos)
    SELECT  m.id,
            i.id,
            -1
      FROM  config.metabib_field m,
            config.index_normalizer i
      WHERE i.func = 'remove_paren_substring'
            AND m.id IN (28);
			
INSERT into config.org_unit_setting_type (name, label, description, datatype)
VALUES (
    'opac.payment_history_age_limit',
    oils_i18n_gettext('opac.payment_history_age_limit',
        'OPAC: Payment History Age Limit', 'coust', 'label'),
    oils_i18n_gettext('opac.payment_history_age_limit',
        'The OPAC should not display payments by patrons that are older than any interval defined here.', 'coust', 'label'),
    'interval'
);

INSERT INTO config.settings_group (name, label) VALUES
('sys', oils_i18n_gettext('config.settings_group.system', 'System', 'coust', 'label')),
('gui', oils_i18n_gettext('config.settings_group.gui', 'GUI', 'coust', 'label')),
('lib', oils_i18n_gettext('config.settings_group.lib', 'Library', 'coust', 'label')),
('sec', oils_i18n_gettext('config.settings_group.sec', 'Security', 'coust', 'label')),
('cat', oils_i18n_gettext('config.settings_group.cat', 'Cataloging', 'coust', 'label')),
('holds', oils_i18n_gettext('config.settings_group.holds', 'Holds', 'coust', 'label')),
('circ', oils_i18n_gettext('config.settings_group.circulation', 'Circulation', 'coust', 'label')),
('self', oils_i18n_gettext('config.settings_group.self', 'Self Check', 'coust', 'label')),
('opac', oils_i18n_gettext('config.settings_group.opac', 'OPAC', 'coust', 'label')),
('prog', oils_i18n_gettext('config.settings_group.program', 'Program', 'coust', 'label')),
('glob', oils_i18n_gettext('config.settings_group.global', 'Global', 'coust', 'label')),
('finance', oils_i18n_gettext('config.settings_group.finances', 'Finances', 'coust', 'label')),
('credit', oils_i18n_gettext('config.settings_group.ccp', 'Credit Card Processing', 'coust', 'label')),
('serial', oils_i18n_gettext('config.settings_group.serial', 'Serials', 'coust', 'label')),
('recall', oils_i18n_gettext('config.settings_group.recall', 'Recalls', 'coust', 'label')),
('booking', oils_i18n_gettext('config.settings_group.booking', 'Booking', 'coust', 'label')),
('offline', oils_i18n_gettext('config.settings_group.offline', 'Offline', 'coust', 'label')),
('receipt_template', oils_i18n_gettext('config.settings_group.receipt_template', 'Receipt Template', 'coust', 'label'));

UPDATE config.org_unit_setting_type SET grp = 'lib', label='Set copy creator as receiver' WHERE name = 'acq.copy_creator_uses_receiver';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'acq.default_circ_modifier';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'acq.default_copy_location';
UPDATE config.org_unit_setting_type SET grp = 'finance' WHERE name = 'acq.fund.balance_limit.block';
UPDATE config.org_unit_setting_type SET grp = 'finance' WHERE name = 'acq.fund.balance_limit.warn';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'acq.holds.allow_holds_from_purchase_request';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'acq.tmp_barcode_prefix';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'acq.tmp_callnumber_prefix';
UPDATE config.org_unit_setting_type SET grp = 'sec' WHERE name = 'auth.opac_timeout';
UPDATE config.org_unit_setting_type SET grp = 'sec' WHERE name = 'auth.persistent_login_interval';
UPDATE config.org_unit_setting_type SET grp = 'sec' WHERE name = 'auth.staff_timeout';
UPDATE config.org_unit_setting_type SET grp = 'booking' WHERE name = 'booking.allow_email_notify';
UPDATE config.org_unit_setting_type SET grp = 'gui' WHERE name = 'cat.bib.alert_on_empty';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Delete bib if all copies are deleted via Acquisitions lineitem cancellation.' WHERE name = 'cat.bib.delete_on_no_copy_via_acq_lineitem_cancel';
UPDATE config.org_unit_setting_type SET grp = 'prog' WHERE name = 'cat.bib.keep_on_empty';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Default Classification Scheme' WHERE name = 'cat.default_classification_scheme';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Default copy status (fast add)' WHERE name = 'cat.default_copy_status_fast';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Default copy status (normal)' WHERE name = 'cat.default_copy_status_normal';
UPDATE config.org_unit_setting_type SET grp = 'finance' WHERE name = 'cat.default_item_price';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Spine and pocket label font family' WHERE name = 'cat.label.font.family';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Spine and pocket label font size' WHERE name = 'cat.label.font.size';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Spine and pocket label font weight' WHERE name = 'cat.label.font.weight';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Defines the control number identifier used in 003 and 035 fields.' WHERE name = 'cat.marc_control_number_identifier';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Spine label maximum lines' WHERE name = 'cat.spine.line.height';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Spine label left margin' WHERE name = 'cat.spine.line.margin';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Spine label line width' WHERE name = 'cat.spine.line.width';
UPDATE config.org_unit_setting_type SET grp = 'cat', label='Delete volume with last copy' WHERE name = 'cat.volume.delete_on_empty';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Toggle off the patron summary sidebar after first view.' WHERE name = 'circ.auto_hide_patron_summary';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Block Renewal of Items Needed for Holds' WHERE name = 'circ.block_renews_for_holds';
UPDATE config.org_unit_setting_type SET grp = 'booking', label='Elbow room' WHERE name = 'circ.booking_reservation.default_elbow_room';
UPDATE config.org_unit_setting_type SET grp = 'finance' WHERE name = 'circ.charge_lost_on_zero';
UPDATE config.org_unit_setting_type SET grp = 'finance' WHERE name = 'circ.charge_on_damaged';
UPDATE config.org_unit_setting_type SET grp = 'circ' WHERE name = 'circ.checkout_auto_renew_age';
UPDATE config.org_unit_setting_type SET grp = 'circ' WHERE name = 'circ.checkout_fills_related_hold';
UPDATE config.org_unit_setting_type SET grp = 'circ' WHERE name = 'circ.checkout_fills_related_hold_exact_match_only';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'circ.claim_never_checked_out.mark_missing';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'circ.claim_return.copy_status';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'circ.damaged.void_ovedue';
UPDATE config.org_unit_setting_type SET grp = 'finance' WHERE name = 'circ.damaged_item_processing_fee';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Do not include outstanding Claims Returned circulations in lump sum tallies in Patron Display.' WHERE name = 'circ.do_not_tally_claims_returned';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Hard boundary' WHERE name = 'circ.hold_boundary.hard';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Soft boundary' WHERE name = 'circ.hold_boundary.soft';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Expire Alert Interval' WHERE name = 'circ.hold_expire_alert_interval';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Expire Interval' WHERE name = 'circ.hold_expire_interval';
UPDATE config.org_unit_setting_type SET grp = 'circ' WHERE name = 'circ.hold_shelf_status_delay';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Soft stalling interval' WHERE name = 'circ.hold_stalling.soft';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Hard stalling interval' WHERE name = 'circ.hold_stalling_hard';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Use Active Date for Age Protection' WHERE name = 'circ.holds.age_protect.active_date';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Behind Desk Pickup Supported' WHERE name = 'circ.holds.behind_desk_pickup_supported';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Canceled holds display age' WHERE name = 'circ.holds.canceled.display_age';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Canceled holds display count' WHERE name = 'circ.holds.canceled.display_count';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Clear shelf copy status' WHERE name = 'circ.holds.clear_shelf.copy_status';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Bypass hold capture during clear shelf process' WHERE name = 'circ.holds.clear_shelf.no_capture_holds';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Default Estimated Wait' WHERE name = 'circ.holds.default_estimated_wait_interval';
UPDATE config.org_unit_setting_type SET grp = 'holds' WHERE name = 'circ.holds.default_shelf_expire_interval';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Block hold request if hold recipient privileges have expired' WHERE name = 'circ.holds.expired_patron_block';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Has Local Copy Alert' WHERE name = 'circ.holds.hold_has_copy_at.alert';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Has Local Copy Block' WHERE name = 'circ.holds.hold_has_copy_at.block';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Maximum library target attempts' WHERE name = 'circ.holds.max_org_unit_target_loops';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Minimum Estimated Wait' WHERE name = 'circ.holds.min_estimated_wait_interval';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Org Unit Target Weight' WHERE name = 'circ.holds.org_unit_target_weight';
UPDATE config.org_unit_setting_type SET grp = 'recall', label='An array of fine amount, fine interval, and maximum fine.' WHERE name = 'circ.holds.recall_fine_rules';
UPDATE config.org_unit_setting_type SET grp = 'recall', label='Truncated loan period.' WHERE name = 'circ.holds.recall_return_interval';
UPDATE config.org_unit_setting_type SET grp = 'recall', label='Circulation duration that triggers a recall.' WHERE name = 'circ.holds.recall_threshold';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Use weight-based hold targeting' WHERE name = 'circ.holds.target_holds_by_org_unit_weight';
UPDATE config.org_unit_setting_type SET grp = 'holds' WHERE name = 'circ.holds.target_skip_me';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='Reset request time on un-cancel' WHERE name = 'circ.holds.uncancel.reset_request_time';
UPDATE config.org_unit_setting_type SET grp = 'holds', label='FIFO' WHERE name = 'circ.holds_fifo';
UPDATE config.org_unit_setting_type SET grp = 'gui' WHERE name = 'circ.item_checkout_history.max';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Lost Checkin Generates New Overdues' WHERE name = 'circ.lost.generate_overdue_on_checkin';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Lost items usable on checkin' WHERE name = 'circ.lost_immediately_available';
UPDATE config.org_unit_setting_type SET grp = 'finance' WHERE name = 'circ.lost_materials_processing_fee';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Void lost max interval' WHERE name = 'circ.max_accept_return_of_lost';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Cap Max Fine at Item Price' WHERE name = 'circ.max_fine.cap_at_price';
UPDATE config.org_unit_setting_type SET grp = 'circ' WHERE name = 'circ.max_patron_claim_return_count';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Item Status for Missing Pieces' WHERE name = 'circ.missing_pieces.copy_status';
UPDATE config.org_unit_setting_type SET grp = 'sec' WHERE name = 'circ.obscure_dob';
UPDATE config.org_unit_setting_type SET grp = 'offline', label='Skip offline checkin if newer item Status Changed Time.' WHERE name = 'circ.offline.skip_checkin_if_newer_status_changed_time';
UPDATE config.org_unit_setting_type SET grp = 'offline', label='Skip offline checkout if newer item Status Changed Time.' WHERE name = 'circ.offline.skip_checkout_if_newer_status_changed_time';
UPDATE config.org_unit_setting_type SET grp = 'offline', label='Skip offline renewal if newer item Status Changed Time.' WHERE name = 'circ.offline.skip_renew_if_newer_status_changed_time';
UPDATE config.org_unit_setting_type SET grp = 'sec', label='Offline: Patron Usernames Allowed' WHERE name = 'circ.offline.username_allowed';
UPDATE config.org_unit_setting_type SET grp = 'sec', label='Maximum concurrently active self-serve password reset requests per user' WHERE name = 'circ.password_reset_request_per_user_limit';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Require matching email address for password reset requests' WHERE name = 'circ.password_reset_request_requires_matching_email';
UPDATE config.org_unit_setting_type SET grp = 'sec', label='Maximum concurrently active self-serve password reset requests' WHERE name = 'circ.password_reset_request_throttle';
UPDATE config.org_unit_setting_type SET grp = 'sec', label='Self-serve password reset request time-to-live' WHERE name = 'circ.password_reset_request_time_to_live';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Patron Registration: Cloned patrons get address copy' WHERE name = 'circ.patron_edit.clone.copy_address';
UPDATE config.org_unit_setting_type SET grp = 'circ' WHERE name = 'circ.patron_invalid_address_apply_penalty';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'circ.pre_cat_copy_circ_lib';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'circ.reshelving_complete.interval';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Restore overdues on lost item return' WHERE name = 'circ.restore_overdue_on_lost_return';
UPDATE config.org_unit_setting_type SET grp = 'self', label='Pop-up alert for errors' WHERE name = 'circ.selfcheck.alert.popup';
UPDATE config.org_unit_setting_type SET grp = 'self', label='Audio Alerts' WHERE name = 'circ.selfcheck.alert.sound';
UPDATE config.org_unit_setting_type SET grp = 'self' WHERE name = 'circ.selfcheck.auto_override_checkout_events';
UPDATE config.org_unit_setting_type SET grp = 'self', label='Block copy checkout status' WHERE name = 'circ.selfcheck.block_checkout_on_copy_status';
UPDATE config.org_unit_setting_type SET grp = 'self', label='Patron Login Timeout (in seconds)' WHERE name = 'circ.selfcheck.patron_login_timeout';
UPDATE config.org_unit_setting_type SET grp = 'self', label='Require Patron Password' WHERE name = 'circ.selfcheck.patron_password_required';
UPDATE config.org_unit_setting_type SET grp = 'self', label='Require patron password' WHERE name = 'circ.selfcheck.require_patron_password';
UPDATE config.org_unit_setting_type SET grp = 'self', label='Workstation Required' WHERE name = 'circ.selfcheck.workstation_required';
UPDATE config.org_unit_setting_type SET grp = 'circ' WHERE name = 'circ.staff_client.actor_on_checkout';
UPDATE config.org_unit_setting_type SET grp = 'prog' WHERE name = 'circ.staff_client.do_not_auto_attempt_print';
UPDATE config.org_unit_setting_type SET grp = 'receipt_template', label='Content of alert_text include' WHERE name = 'circ.staff_client.receipt.alert_text';
UPDATE config.org_unit_setting_type SET grp = 'receipt_template', label='Content of event_text include' WHERE name = 'circ.staff_client.receipt.event_text';
UPDATE config.org_unit_setting_type SET grp = 'receipt_template', label='Content of footer_text include' WHERE name = 'circ.staff_client.receipt.footer_text';
UPDATE config.org_unit_setting_type SET grp = 'receipt_template', label='Content of header_text include' WHERE name = 'circ.staff_client.receipt.header_text';
UPDATE config.org_unit_setting_type SET grp = 'receipt_template', label='Content of notice_text include' WHERE name = 'circ.staff_client.receipt.notice_text';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Minimum Transit Checkin Interval' WHERE name = 'circ.transit.min_checkin_interval';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Patron Merge Deactivate Card' WHERE name = 'circ.user_merge.deactivate_cards';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Patron Merge Address Delete' WHERE name = 'circ.user_merge.delete_addresses';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Patron Merge Barcode Delete' WHERE name = 'circ.user_merge.delete_cards';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Void lost item billing when returned' WHERE name = 'circ.void_lost_on_checkin';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Void processing fee on lost item return' WHERE name = 'circ.void_lost_proc_fee_on_checkin';
UPDATE config.org_unit_setting_type SET grp = 'finance', label='Void overdue fines when items are marked lost' WHERE name = 'circ.void_overdue_on_lost';
UPDATE config.org_unit_setting_type SET grp = 'finance' WHERE name = 'credit.payments.allow';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='Enable AuthorizeNet payments' WHERE name = 'credit.processor.authorizenet.enabled';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='AuthorizeNet login' WHERE name = 'credit.processor.authorizenet.login';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='AuthorizeNet password' WHERE name = 'credit.processor.authorizenet.password';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='AuthorizeNet server' WHERE name = 'credit.processor.authorizenet.server';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='AuthorizeNet test mode' WHERE name = 'credit.processor.authorizenet.testmode';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='Name default credit processor' WHERE name = 'credit.processor.default';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='Enable PayflowPro payments' WHERE name = 'credit.processor.payflowpro.enabled';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='PayflowPro login/merchant ID' WHERE name = 'credit.processor.payflowpro.login';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='PayflowPro partner' WHERE name = 'credit.processor.payflowpro.partner';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='PayflowPro password' WHERE name = 'credit.processor.payflowpro.password';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='PayflowPro test mode' WHERE name = 'credit.processor.payflowpro.testmode';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='PayflowPro vendor' WHERE name = 'credit.processor.payflowpro.vendor';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='Enable PayPal payments' WHERE name = 'credit.processor.paypal.enabled';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='PayPal login' WHERE name = 'credit.processor.paypal.login';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='PayPal password' WHERE name = 'credit.processor.paypal.password';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='PayPal signature' WHERE name = 'credit.processor.paypal.signature';
UPDATE config.org_unit_setting_type SET grp = 'credit', label='PayPal test mode' WHERE name = 'credit.processor.paypal.testmode';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Format Dates with this pattern.' WHERE name = 'format.date';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Format Times with this pattern.' WHERE name = 'format.time';
UPDATE config.org_unit_setting_type SET grp = 'glob' WHERE name = 'global.default_locale';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'global.juvenile_age_threshold';
UPDATE config.org_unit_setting_type SET grp = 'glob' WHERE name = 'global.password_regex';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Disable the ability to save list column configurations locally.' WHERE name = 'gui.disable_local_save_columns';
UPDATE config.org_unit_setting_type SET grp = 'lib', label='Courier Code' WHERE name = 'lib.courier_code';
UPDATE config.org_unit_setting_type SET grp = 'lib' WHERE name = 'notice.telephony.callfile_lines';
UPDATE config.org_unit_setting_type SET grp = 'opac', label='Allow pending addresses' WHERE name = 'opac.allow_pending_address';
UPDATE config.org_unit_setting_type SET grp = 'glob' WHERE name = 'opac.barcode_regex';
UPDATE config.org_unit_setting_type SET grp = 'opac', label='Use fully compressed serial holdings' WHERE name = 'opac.fully_compressed_serial_holdings';
UPDATE config.org_unit_setting_type SET grp = 'opac', label='Org Unit Hiding Depth' WHERE name = 'opac.org_unit_hiding.depth';
UPDATE config.org_unit_setting_type SET grp = 'opac', label='Payment History Age Limit' WHERE name = 'opac.payment_history_age_limit';
UPDATE config.org_unit_setting_type SET grp = 'prog' WHERE name = 'org.bounced_emails';
UPDATE config.org_unit_setting_type SET grp = 'sec', label='Patron Opt-In Boundary' WHERE name = 'org.patron_opt_boundary';
UPDATE config.org_unit_setting_type SET grp = 'sec', label='Patron Opt-In Default' WHERE name = 'org.patron_opt_default';
UPDATE config.org_unit_setting_type SET grp = 'sec' WHERE name = 'patron.password.use_phone';
UPDATE config.org_unit_setting_type SET grp = 'serial', label='Previous Issuance Copy Location' WHERE name = 'serial.prev_issuance_copy_location';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Work Log: Maximum Patrons Logged' WHERE name = 'ui.admin.patron_log.max_entries';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Work Log: Maximum Actions Logged' WHERE name = 'ui.admin.work_log.max_entries';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Horizontal layout for Volume/Copy Creator/Editor.' WHERE name = 'ui.cat.volume_copy_editor.horizontal';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Uncheck bills by default in the patron billing interface' WHERE name = 'ui.circ.billing.uncheck_bills_and_unfocus_payment_box';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Record In-House Use: Maximum # of uses allowed per entry.' WHERE name = 'ui.circ.in_house_use.entry_cap';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Record In-House Use: # of uses threshold for Are You Sure? dialog.' WHERE name = 'ui.circ.in_house_use.entry_warn';
UPDATE config.org_unit_setting_type SET grp = 'gui' WHERE name = 'ui.circ.patron_summary.horizontal';
UPDATE config.org_unit_setting_type SET grp = 'gui' WHERE name = 'ui.circ.show_billing_tab_on_bills';
UPDATE config.org_unit_setting_type SET grp = 'circ', label='Suppress popup-dialogs during check-in.' WHERE name = 'ui.circ.suppress_checkin_popups';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Button bar' WHERE name = 'ui.general.button_bar';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Default Hotkeyset' WHERE name = 'ui.general.hotkeyset';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Idle timeout' WHERE name = 'ui.general.idle_timeout';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Default Country for New Addresses in Patron Editor' WHERE name = 'ui.patron.default_country';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Default Ident Type for Patron Registration' WHERE name = 'ui.patron.default_ident_type';
UPDATE config.org_unit_setting_type SET grp = 'sec', label='Default level of patrons'' internet access' WHERE name = 'ui.patron.default_inet_access_level';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show active field on patron registration' WHERE name = 'ui.patron.edit.au.active.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest active field on patron registration' WHERE name = 'ui.patron.edit.au.active.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show alert_message field on patron registration' WHERE name = 'ui.patron.edit.au.alert_message.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest alert_message field on patron registration' WHERE name = 'ui.patron.edit.au.alert_message.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show alias field on patron registration' WHERE name = 'ui.patron.edit.au.alias.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest alias field on patron registration' WHERE name = 'ui.patron.edit.au.alias.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show barred field on patron registration' WHERE name = 'ui.patron.edit.au.barred.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest barred field on patron registration' WHERE name = 'ui.patron.edit.au.barred.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show claims_never_checked_out_count field on patron registration' WHERE name = 'ui.patron.edit.au.claims_never_checked_out_count.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest claims_never_checked_out_count field on patron registration' WHERE name = 'ui.patron.edit.au.claims_never_checked_out_count.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show claims_returned_count field on patron registration' WHERE name = 'ui.patron.edit.au.claims_returned_count.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest claims_returned_count field on patron registration' WHERE name = 'ui.patron.edit.au.claims_returned_count.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Example for day_phone field on patron registration' WHERE name = 'ui.patron.edit.au.day_phone.example';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Regex for day_phone field on patron registration' WHERE name = 'ui.patron.edit.au.day_phone.regex';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Require day_phone field on patron registration' WHERE name = 'ui.patron.edit.au.day_phone.require';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show day_phone field on patron registration' WHERE name = 'ui.patron.edit.au.day_phone.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest day_phone field on patron registration' WHERE name = 'ui.patron.edit.au.day_phone.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show calendar widget for dob field on patron registration' WHERE name = 'ui.patron.edit.au.dob.calendar';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Require dob field on patron registration' WHERE name = 'ui.patron.edit.au.dob.require';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show dob field on patron registration' WHERE name = 'ui.patron.edit.au.dob.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest dob field on patron registration' WHERE name = 'ui.patron.edit.au.dob.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Example for email field on patron registration' WHERE name = 'ui.patron.edit.au.email.example';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Regex for email field on patron registration' WHERE name = 'ui.patron.edit.au.email.regex';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Require email field on patron registration' WHERE name = 'ui.patron.edit.au.email.require';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show email field on patron registration' WHERE name = 'ui.patron.edit.au.email.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest email field on patron registration' WHERE name = 'ui.patron.edit.au.email.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Example for evening_phone field on patron registration' WHERE name = 'ui.patron.edit.au.evening_phone.example';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Regex for evening_phone field on patron registration' WHERE name = 'ui.patron.edit.au.evening_phone.regex';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Require evening_phone field on patron registration' WHERE name = 'ui.patron.edit.au.evening_phone.require';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show evening_phone field on patron registration' WHERE name = 'ui.patron.edit.au.evening_phone.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest evening_phone field on patron registration' WHERE name = 'ui.patron.edit.au.evening_phone.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show ident_value field on patron registration' WHERE name = 'ui.patron.edit.au.ident_value.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest ident_value field on patron registration' WHERE name = 'ui.patron.edit.au.ident_value.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show ident_value2 field on patron registration' WHERE name = 'ui.patron.edit.au.ident_value2.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest ident_value2 field on patron registration' WHERE name = 'ui.patron.edit.au.ident_value2.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show juvenile field on patron registration' WHERE name = 'ui.patron.edit.au.juvenile.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest juvenile field on patron registration' WHERE name = 'ui.patron.edit.au.juvenile.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show master_account field on patron registration' WHERE name = 'ui.patron.edit.au.master_account.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest master_account field on patron registration' WHERE name = 'ui.patron.edit.au.master_account.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Example for other_phone field on patron registration' WHERE name = 'ui.patron.edit.au.other_phone.example';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Regex for other_phone field on patron registration' WHERE name = 'ui.patron.edit.au.other_phone.regex';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Require other_phone field on patron registration' WHERE name = 'ui.patron.edit.au.other_phone.require';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show other_phone field on patron registration' WHERE name = 'ui.patron.edit.au.other_phone.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest other_phone field on patron registration' WHERE name = 'ui.patron.edit.au.other_phone.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show second_given_name field on patron registration' WHERE name = 'ui.patron.edit.au.second_given_name.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest second_given_name field on patron registration' WHERE name = 'ui.patron.edit.au.second_given_name.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Show suffix field on patron registration' WHERE name = 'ui.patron.edit.au.suffix.show';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Suggest suffix field on patron registration' WHERE name = 'ui.patron.edit.au.suffix.suggest';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Require county field on patron registration' WHERE name = 'ui.patron.edit.aua.county.require';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Example for post_code field on patron registration' WHERE name = 'ui.patron.edit.aua.post_code.example';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Regex for post_code field on patron registration' WHERE name = 'ui.patron.edit.aua.post_code.regex';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Default showing suggested patron registration fields' WHERE name = 'ui.patron.edit.default_suggested';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Example for phone fields on patron registration' WHERE name = 'ui.patron.edit.phone.example';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Regex for phone fields on patron registration' WHERE name = 'ui.patron.edit.phone.regex';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Require at least one address for Patron Registration' WHERE name = 'ui.patron.registration.require_address';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Cap results in Patron Search at this number.' WHERE name = 'ui.patron_search.result_cap';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Require staff initials for entry/edit of item/patron/penalty notes/messages.' WHERE name = 'ui.staff.require_initials';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='Unified Volume/Item Creator/Editor' WHERE name = 'ui.unified_volume_copy_editor';
UPDATE config.org_unit_setting_type SET grp = 'gui', label='URL for remote directory containing list column settings.' WHERE name = 'url.remote_column_settings';

INSERT into config.org_unit_setting_type (name, grp, label, description, datatype) VALUES
( 'circ.transit.suppress_hold', 'circ',
    oils_i18n_gettext('circ.transit.suppress_hold',
        'Suppress Hold Transits Group',
        'coust', 'label'),
    oils_i18n_gettext('circ.transit.suppress_hold',
        'If set to a non-empty value, Hold Transits will be suppressed between this OU and others with the same value. If set to an empty value, transits will not be suppressed.',
        'coust', 'description'),
    'string')
,( 'circ.transit.suppress_non_hold', 'circ',
    oils_i18n_gettext('circ.transit.suppress_non_hold',
        'Suppress Non-Hold Transits Group',
        'coust', 'label'),
    oils_i18n_gettext('circ.transit.suppress_non_hold',
        'If set to a non-empty value, Non-Hold Transits will be suppressed between this OU and others with the same value. If set to an empty value, transits will not be suppressed.',
        'coust', 'description'),
    'string');

INSERT INTO config.org_unit_setting_type (name, grp, label, description, datatype) VALUES
( 'opac.username_regex', 'glob',
    oils_i18n_gettext('opac.username_regex',
        'Patron username format',
        'coust', 'label'),
    oils_i18n_gettext('opac.username_regex',
        'Regular expression defining the patron username format, used for patron registration and self-service username changing only',
        'coust', 'description'),
    'string')
,( 'opac.lock_usernames', 'glob',
    oils_i18n_gettext('opac.lock_usernames',
        'Lock Usernames',
        'coust', 'label'),
    oils_i18n_gettext('opac.lock_usernames',
        'If enabled username changing via the OPAC will be disabled',
        'coust', 'description'),
    'bool')
,( 'opac.unlimit_usernames', 'glob',
    oils_i18n_gettext('opac.unlimit_usernames',
        'Allow multiple username changes',
        'coust', 'label'),
    oils_i18n_gettext('opac.unlimit_usernames',
        'If enabled (and Lock Usernames is not set) patrons will be allowed to change their username when it does not look like a barcode. Otherwise username changing in the OPAC will only be allowed when the patron''s username looks like a barcode.',
        'coust', 'description'),
    'bool')
;

UPDATE config.org_unit_setting_type SET description = oils_i18n_gettext(
            'opac.staff.jump_to_details_on_single_hit',
            'When a search yields only 1 result, jump directly to the record details page.  This setting only affects the OPAC within the staff client',
            'coust', 
            'description'
        )
WHERE label = 'Jump to details on 1 hit (staff client)';
UPDATE config.org_unit_setting_type SET description = oils_i18n_gettext(
            'opac.patron.jump_to_details_on_single_hit',
            'When a search yields only 1 result, jump directly to the record details page.  This setting only affects the public OPAC',
            'coust', 
            'description'
        )
WHERE label = 'Jump to details on 1 hit (public)';
--INSERT INTO config.org_unit_setting_type ( name, grp, label, description, datatype )
--    VALUES (
--        'opac.staff.jump_to_details_on_single_hit', 
--        'opac',
--        oils_i18n_gettext(
--            'opac.staff.jump_to_details_on_single_hit',
--            'Jump to details on 1 hit (staff client)',
--            'coust', 
--            'label'
--        ),
--        oils_i18n_gettext(
--            'opac.staff.jump_to_details_on_single_hit',
--            'When a search yields only 1 result, jump directly to the record details page.  This setting only affects the OPAC within the staff client',
--            'coust', 
--            'description'
--        ),
--        'bool'
--    ), 
--(
--        'opac.patron.jump_to_details_on_single_hit', 
--        'opac',
--        oils_i18n_gettext(
--            'opac.patron.jump_to_details_on_single_hit',
--            'Jump to details on 1 hit (public)',
--            'coust', 
--            'label'
--        ),
--        oils_i18n_gettext(
--            'opac.patron.jump_to_details_on_single_hit',
--            'When a search yields only 1 result, jump directly to the record details page.  This setting only affects the public OPAC',
--            'coust', 
--            'description'
--        ),
--        'bool'
--    );
INSERT INTO config.org_unit_setting_type(name, grp, label, description, datatype) VALUES

( 'circ.grace.extend', 'circ',
    oils_i18n_gettext('circ.grace.extend',
        'Auto-Extend Grace Periods',
        'coust', 'label'),
    oils_i18n_gettext('circ.grace.extend',
        'When enabled grace periods will auto-extend. By default this will be only when they are a full day or more and end on a closed date, though other options can alter this.',
        'coust', 'description'),
    'bool')

,( 'circ.grace.extend.all', 'circ',
    oils_i18n_gettext('circ.grace.extend.all',
        'Auto-Extending Grace Periods extend for all closed dates',
        'coust', 'label'),
    oils_i18n_gettext('circ.grace.extend.all',
        'If enabled and Grace Periods auto-extending is turned on grace periods will extend past all closed dates they intersect, within hard-coded limits. This basically becomes "grace periods can only be consumed by closed dates".',
        'coust', 'description'),
    'bool')

,( 'circ.grace.extend.into_closed', 'circ',
    oils_i18n_gettext('circ.grace.extend.into_closed',
        'Auto-Extending Grace Periods include trailing closed dates',
        'coust', 'label'),
    oils_i18n_gettext('circ.grace.extend.into_closed',
         'If enabled and Grace Periods auto-extending is turned on grace periods will include closed dates that directly follow the last day of the grace period, to allow a backdate into the closed dates to assume "returned after hours on the last day of the grace period, and thus still within it" automatically.',
        'coust', 'description'),
    'bool');

	INSERT into config.org_unit_setting_type (name, grp, label, description, datatype) VALUES
( 'circ.holds.target_when_closed', 'circ',
    oils_i18n_gettext('circ.holds.target_when_closed',
        'Target copies for a hold even if copy''s circ lib is closed',
        'coust', 'label'),
    oils_i18n_gettext('circ.holds.target_when_closed',
        'If this setting is true at a given org unit or one of its ancestors, the hold targeter will target copies from this org unit even if the org unit is closed (according to the actor.org_unit.closed_date table).',
        'coust', 'description'),
    'bool'),
( 'circ.holds.target_when_closed_if_at_pickup_lib', 'circ',
    oils_i18n_gettext('circ.holds.target_when_closed_if_at_pickup_lib',
        'Target copies for a hold even if copy''s circ lib is closed IF the circ lib is the hold''s pickup lib',
        'coust', 'label'),
    oils_i18n_gettext('circ.holds.target_when_closed_if_at_pickup_lib',
        'If this setting is true at a given org unit or one of its ancestors, the hold targeter will target copies from this org unit even if the org unit is closed (according to the actor.org_unit.closed_date table) IF AND ONLY IF the copy''s circ lib is the same as the hold''s pickup lib.',
        'coust', 'description'),
    'bool')
;

-- register the normalizer
INSERT INTO config.index_normalizer (name, description, func, param_count) VALUES (
    'Coded Value Map Normalizer', 
    'Applies coded_value_map mapping of values',
    'coded_value_map_normalizer', 
    1
);

-- 950.data.seed-values.sql
INSERT INTO config.settings_group (name, label) VALUES
    (
        'sms',
        oils_i18n_gettext(
            'sms',
            'SMS Text Messages',
            'csg',
            'label'
        )
    )
;

INSERT INTO config.org_unit_setting_type (name, grp, label, description, datatype) VALUES
    (
        'sms.enable',
        'sms',
        oils_i18n_gettext(
            'sms.enable',
            'Enable features that send SMS text messages.',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'sms.enable',
            'Current features that use SMS include hold-ready-for-pickup notifications and a "Send Text" action for call numbers in the OPAC. If this setting is not enabled, the SMS options will not be offered to the user.  Unless you are carefully silo-ing patrons and their use of the OPAC, the context org for this setting should be the top org in the org hierarchy, otherwise patrons can trample their user settings when jumping between orgs.',
            'coust',
            'description'
        ),
        'bool'
    )
    ,(
        'sms.disable_authentication_requirement.callnumbers',
        'sms',
        oils_i18n_gettext(
            'sms.disable_authentication_requirement.callnumbers',
            'Disable auth requirement for texting call numbers.',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'sms.disable_authentication_requirement.callnumbers',
            'Disable authentication requirement for sending call number information via SMS from the OPAC.',
            'coust',
            'description'
        ),
        'bool'
    )
;

-- 090.schema.action.sql
-- 950.data.seed-values.sql
INSERT INTO config.usr_setting_type (name,grp,opac_visible,label,description,datatype,fm_class) VALUES (
    'opac.default_sms_carrier',
    'sms',
    TRUE,
    oils_i18n_gettext(
        'opac.default_sms_carrier',
        'Default SMS/Text Carrier',
        'cust',
        'label'
    ),
    oils_i18n_gettext(
        'opac.default_sms_carrier',
        'Default SMS/Text Carrier',
        'cust',
        'description'
    ),
    'link',
    'csc'
);

INSERT INTO config.usr_setting_type (name,grp,opac_visible,label,description,datatype) VALUES (
    'opac.default_sms_notify',
    'sms',
    TRUE,
    oils_i18n_gettext(
        'opac.default_sms_notify',
        'Default SMS/Text Number',
        'cust',
        'label'
    ),
    oils_i18n_gettext(
        'opac.default_sms_notify',
        'Default SMS/Text Number',
        'cust',
        'description'
    ),
    'string'
);

INSERT INTO config.usr_setting_type (name,grp,opac_visible,label,description,datatype) VALUES (
    'opac.default_phone',
    'opac',
    TRUE,
    oils_i18n_gettext(
        'opac.default_phone',
        'Default Phone Number',
        'cust',
        'label'
    ),
    oils_i18n_gettext(
        'opac.default_phone',
        'Default Phone Number',
        'cust',
        'description'
    ),
    'string'
);

SELECT setval( 'config.sms_carrier_id_seq', 1000 );
INSERT INTO config.sms_carrier VALUES

    -- Testing
    (
        1,
        oils_i18n_gettext(
            1,
            'Local',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            1,
            'Test Carrier',
            'csc',
            'name'
        ),
        'opensrf+$number@localhost',
        FALSE
    ),

    -- Canada & USA
    (
        2,
        oils_i18n_gettext(
            2,
            'Canada & USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            2,
            'Rogers Wireless',
            'csc',
            'name'
        ),
        '$number@pcs.rogers.com',
        TRUE
    ),
    (
        3,
        oils_i18n_gettext(
            3,
            'Canada & USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            3,
            'Rogers Wireless (Alternate)',
            'csc',
            'name'
        ),
        '1$number@mms.rogers.com',
        TRUE
    ),
    (
        4,
        oils_i18n_gettext(
            4,
            'Canada & USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            4,
            'Telus Mobility',
            'csc',
            'name'
        ),
        '$number@msg.telus.com',
        TRUE
    ),

    -- Canada
    (
        5,
        oils_i18n_gettext(
            5,
            'Canada',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            5,
            'Koodo Mobile',
            'csc',
            'name'
        ),
        '$number@msg.telus.com',
        TRUE
    ),
    (
        6,
        oils_i18n_gettext(
            6,
            'Canada',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            6,
            'Fido',
            'csc',
            'name'
        ),
        '$number@fido.ca',
        TRUE
    ),
    (
        7,
        oils_i18n_gettext(
            7,
            'Canada',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            7,
            'Bell Mobility & Solo Mobile',
            'csc',
            'name'
        ),
        '$number@txt.bell.ca',
        TRUE
    ),
    (
        8,
        oils_i18n_gettext(
            8,
            'Canada',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            8,
            'Bell Mobility & Solo Mobile (Alternate)',
            'csc',
            'name'
        ),
        '$number@txt.bellmobility.ca',
        TRUE
    ),
    (
        9,
        oils_i18n_gettext(
            9,
            'Canada',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            9,
            'Aliant',
            'csc',
            'name'
        ),
        '$number@sms.wirefree.informe.ca',
        TRUE
    ),
    (
        10,
        oils_i18n_gettext(
            10,
            'Canada',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            10,
            'PC Telecom',
            'csc',
            'name'
        ),
        '$number@mobiletxt.ca',
        TRUE
    ),
    (
        11,
        oils_i18n_gettext(
            11,
            'Canada',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            11,
            'SaskTel',
            'csc',
            'name'
        ),
        '$number@sms.sasktel.com',
        TRUE
    ),
    (
        12,
        oils_i18n_gettext(
            12,
            'Canada',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            12,
            'MTS Mobility',
            'csc',
            'name'
        ),
        '$number@text.mtsmobility.com',
        TRUE
    ),
    (
        13,
        oils_i18n_gettext(
            13,
            'Canada',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            13,
            'Virgin Mobile',
            'csc',
            'name'
        ),
        '$number@vmobile.ca',
        TRUE
    ),

    -- International
    (
        14,
        oils_i18n_gettext(
            14,
            'International',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            14,
            'Iridium',
            'csc',
            'name'
        ),
        '$number@msg.iridium.com',
        TRUE
    ),
    (
        15,
        oils_i18n_gettext(
            15,
            'International',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            15,
            'Globalstar',
            'csc',
            'name'
        ),
        '$number@msg.globalstarusa.com',
        TRUE
    ),
    (
        16,
        oils_i18n_gettext(
            16,
            'International',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            16,
            'Bulletin.net',
            'csc',
            'name'
        ),
        '$number@bulletinmessenger.net', -- International Formatted number
        TRUE
    ),
    (
        17,
        oils_i18n_gettext(
            17,
            'International',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            17,
            'Panacea Mobile',
            'csc',
            'name'
        ),
        '$number@api.panaceamobile.com',
        TRUE
    ),

    -- USA
    (
        18,
        oils_i18n_gettext(
            18,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            18,
            'C Beyond',
            'csc',
            'name'
        ),
        '$number@cbeyond.sprintpcs.com',
        TRUE
    ),
    (
        19,
        oils_i18n_gettext(
            19,
            'Alaska, USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            19,
            'General Communications, Inc.',
            'csc',
            'name'
        ),
        '$number@mobile.gci.net',
        TRUE
    ),
    (
        20,
        oils_i18n_gettext(
            20,
            'California, USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            20,
            'Golden State Cellular',
            'csc',
            'name'
        ),
        '$number@gscsms.com',
        TRUE
    ),
    (
        21,
        oils_i18n_gettext(
            21,
            'Cincinnati, Ohio, USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            21,
            'Cincinnati Bell',
            'csc',
            'name'
        ),
        '$number@gocbw.com',
        TRUE
    ),
    (
        22,
        oils_i18n_gettext(
            22,
            'Hawaii, USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            22,
            'Hawaiian Telcom Wireless',
            'csc',
            'name'
        ),
        '$number@hawaii.sprintpcs.com',
        TRUE
    ),
    (
        23,
        oils_i18n_gettext(
            23,
            'Midwest, USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            23,
            'i wireless (T-Mobile)',
            'csc',
            'name'
        ),
        '$number.iws@iwspcs.net',
        TRUE
    ),
    (
        24,
        oils_i18n_gettext(
            24,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            24,
            'i-wireless (Sprint PCS)',
            'csc',
            'name'
        ),
        '$number@iwirelesshometext.com',
        TRUE
    ),
    (
        25,
        oils_i18n_gettext(
            25,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            25,
            'MetroPCS',
            'csc',
            'name'
        ),
        '$number@mymetropcs.com',
        TRUE
    ),
    (
        26,
        oils_i18n_gettext(
            26,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            26,
            'Kajeet',
            'csc',
            'name'
        ),
        '$number@mobile.kajeet.net',
        TRUE
    ),
    (
        27,
        oils_i18n_gettext(
            27,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            27,
            'Element Mobile',
            'csc',
            'name'
        ),
        '$number@SMS.elementmobile.net',
        TRUE
    ),
    (
        28,
        oils_i18n_gettext(
            28,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            28,
            'Esendex',
            'csc',
            'name'
        ),
        '$number@echoemail.net',
        TRUE
    ),
    (
        29,
        oils_i18n_gettext(
            29,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            29,
            'Boost Mobile',
            'csc',
            'name'
        ),
        '$number@myboostmobile.com',
        TRUE
    ),
    (
        30,
        oils_i18n_gettext(
            30,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            30,
            'BellSouth',
            'csc',
            'name'
        ),
        '$number@bellsouth.com',
        TRUE
    ),
    (
        31,
        oils_i18n_gettext(
            31,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            31,
            'Bluegrass Cellular',
            'csc',
            'name'
        ),
        '$number@sms.bluecell.com',
        TRUE
    ),
    (
        32,
        oils_i18n_gettext(
            32,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            32,
            'AT&T Enterprise Paging',
            'csc',
            'name'
        ),
        '$number@page.att.net',
        TRUE
    ),
    (
        33,
        oils_i18n_gettext(
            33,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            33,
            'AT&T Mobility/Wireless',
            'csc',
            'name'
        ),
        '$number@txt.att.net',
        TRUE
    ),
    (
        34,
        oils_i18n_gettext(
            34,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            34,
            'AT&T Global Smart Messaging Suite',
            'csc',
            'name'
        ),
        '$number@sms.smartmessagingsuite.com',
        TRUE
    ),
    (
        35,
        oils_i18n_gettext(
            35,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            35,
            'Alltel (Allied Wireless)',
            'csc',
            'name'
        ),
        '$number@sms.alltelwireless.com',
        TRUE
    ),
    (
        36,
        oils_i18n_gettext(
            36,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            36,
            'Alaska Communications',
            'csc',
            'name'
        ),
        '$number@msg.acsalaska.com',
        TRUE
    ),
    (
        37,
        oils_i18n_gettext(
            37,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            37,
            'Ameritech',
            'csc',
            'name'
        ),
        '$number@paging.acswireless.com',
        TRUE
    ),
    (
        38,
        oils_i18n_gettext(
            38,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            38,
            'Cingular (GoPhone prepaid)',
            'csc',
            'name'
        ),
        '$number@cingulartext.com',
        TRUE
    ),
    (
        39,
        oils_i18n_gettext(
            39,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            39,
            'Cingular (Postpaid)',
            'csc',
            'name'
        ),
        '$number@cingular.com',
        TRUE
    ),
    (
        40,
        oils_i18n_gettext(
            40,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            40,
            'Cellular One (Dobson) / O2 / Orange',
            'csc',
            'name'
        ),
        '$number@mobile.celloneusa.com',
        TRUE
    ),
    (
        41,
        oils_i18n_gettext(
            41,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            41,
            'Cellular South',
            'csc',
            'name'
        ),
        '$number@csouth1.com',
        TRUE
    ),
    (
        42,
        oils_i18n_gettext(
            42,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            42,
            'Cellcom',
            'csc',
            'name'
        ),
        '$number@cellcom.quiktxt.com',
        TRUE
    ),
    (
        43,
        oils_i18n_gettext(
            43,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            43,
            'Chariton Valley Wireless',
            'csc',
            'name'
        ),
        '$number@sms.cvalley.net',
        TRUE
    ),
    (
        44,
        oils_i18n_gettext(
            44,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            44,
            'Cricket',
            'csc',
            'name'
        ),
        '$number@sms.mycricket.com',
        TRUE
    ),
    (
        45,
        oils_i18n_gettext(
            45,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            45,
            'Cleartalk Wireless',
            'csc',
            'name'
        ),
        '$number@sms.cleartalk.us',
        TRUE
    ),
    (
        46,
        oils_i18n_gettext(
            46,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            46,
            'Edge Wireless',
            'csc',
            'name'
        ),
        '$number@sms.edgewireless.com',
        TRUE
    ),
    (
        47,
        oils_i18n_gettext(
            47,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            47,
            'Syringa Wireless',
            'csc',
            'name'
        ),
        '$number@rinasms.com',
        TRUE
    ),
    (
        48,
        oils_i18n_gettext(
            48,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            48,
            'T-Mobile',
            'csc',
            'name'
        ),
        '$number@tmomail.net',
        TRUE
    ),
    (
        49,
        oils_i18n_gettext(
            49,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            49,
            'Straight Talk / PagePlus Cellular',
            'csc',
            'name'
        ),
        '$number@vtext.com',
        TRUE
    ),
    (
        50,
        oils_i18n_gettext(
            50,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            50,
            'South Central Communications',
            'csc',
            'name'
        ),
        '$number@rinasms.com',
        TRUE
    ),
    (
        51,
        oils_i18n_gettext(
            51,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            51,
            'Simple Mobile',
            'csc',
            'name'
        ),
        '$number@smtext.com',
        TRUE
    ),
    (
        52,
        oils_i18n_gettext(
            52,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            52,
            'Sprint (PCS)',
            'csc',
            'name'
        ),
        '$number@messaging.sprintpcs.com',
        TRUE
    ),
    (
        53,
        oils_i18n_gettext(
            53,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            53,
            'Nextel',
            'csc',
            'name'
        ),
        '$number@messaging.nextel.com',
        TRUE
    ),
    (
        54,
        oils_i18n_gettext(
            54,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            54,
            'Pioneer Cellular',
            'csc',
            'name'
        ),
        '$number@zsend.com', -- nine digit number
        TRUE
    ),
    (
        55,
        oils_i18n_gettext(
            55,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            55,
            'Qwest Wireless',
            'csc',
            'name'
        ),
        '$number@qwestmp.com',
        TRUE
    ),
    (
        56,
        oils_i18n_gettext(
            56,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            56,
            'US Cellular',
            'csc',
            'name'
        ),
        '$number@email.uscc.net',
        TRUE
    ),
    (
        57,
        oils_i18n_gettext(
            57,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            57,
            'Unicel',
            'csc',
            'name'
        ),
        '$number@utext.com',
        TRUE
    ),
    (
        58,
        oils_i18n_gettext(
            58,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            58,
            'Teleflip',
            'csc',
            'name'
        ),
        '$number@teleflip.com',
        TRUE
    ),
    (
        59,
        oils_i18n_gettext(
            59,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            59,
            'Virgin Mobile',
            'csc',
            'name'
        ),
        '$number@vmobl.com',
        TRUE
    ),
    (
        60,
        oils_i18n_gettext(
            60,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            60,
            'Verizon Wireless',
            'csc',
            'name'
        ),
        '$number@vtext.com',
        TRUE
    ),
    (
        61,
        oils_i18n_gettext(
            61,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            61,
            'USA Mobility',
            'csc',
            'name'
        ),
        '$number@usamobility.net',
        TRUE
    ),
    (
        62,
        oils_i18n_gettext(
            62,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            62,
            'Viaero',
            'csc',
            'name'
        ),
        '$number@viaerosms.com',
        TRUE
    ),
    (
        63,
        oils_i18n_gettext(
            63,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            63,
            'TracFone',
            'csc',
            'name'
        ),
        '$number@mmst5.tracfone.com',
        TRUE
    ),
    (
        64,
        oils_i18n_gettext(
            64,
            'USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            64,
            'Centennial Wireless',
            'csc',
            'name'
        ),
        '$number@cwemail.com',
        TRUE
    ),

    -- South Korea and USA
    (
        65,
        oils_i18n_gettext(
            65,
            'South Korea and USA',
            'csc',
            'region'
        ),
        oils_i18n_gettext(
            65,
            'Helio',
            'csc',
            'name'
        ),
        '$number@myhelio.com',
        TRUE
    )
;

INSERT INTO config.standing_penalty (id, name, label, staff_alert, org_depth) VALUES
    (
        31,
        'INVALID_PATRON_EMAIL_ADDRESS',
        oils_i18n_gettext(
            31,
            'Patron had an invalid email address',
            'csp',
            'label'
        ),
        TRUE,
        0
    ),
    (
        32,
        'INVALID_PATRON_DAY_PHONE',
        oils_i18n_gettext(
            32,
            'Patron had an invalid daytime phone number',
            'csp',
            'label'
        ),
        TRUE,
        0
    ),
    (
        33,
        'INVALID_PATRON_EVENING_PHONE',
        oils_i18n_gettext(
            33,
            'Patron had an invalid evening phone number',
            'csp',
            'label'
        ),
        TRUE,
        0
    ),
    (
        34,
        'INVALID_PATRON_OTHER_PHONE',
        oils_i18n_gettext(
            34,
            'Patron had an invalid other phone number',
            'csp',
            'label'
        ),
        TRUE,
        0
    );


UPDATE config.copy_status
SET restrict_copy_delete = TRUE
WHERE id IN (1,3,6,8);
--Update statement not included in last run.  ids might not be valid
UPDATE config.copy_status SET copy_active = true WHERE id IN (0, 1, 7, 8, 10, 12, 15);

INSERT INTO config.global_flag (name, label, enabled, value) VALUES (
    'opac.use_autosuggest',
    'OPAC: Show auto-completing suggestions dialog under basic search box (put ''opac_visible'' into the value field to limit suggestions to OPAC-visible items, or blank the field for a possible performance improvement)',
    TRUE,
    'opac_visible'
);

-- one good exception to default true:
UPDATE config.metabib_field
    SET browse_field = FALSE
    WHERE (field_class = 'keyword' AND name = 'keyword') OR
        (field_class = 'subject' AND name = 'complete');

		INSERT INTO config.usr_activity_type (id, ewho, ewhat, ehow, egroup, label) VALUES

     -- authen/authz actions
     -- note: "opensrf" is the default ingress/ehow
     (1,  NULL, 'login',  'opensrf',      'authen', oils_i18n_gettext(1 , 'Login via opensrf', 'cuat', 'label'))
    ,(2,  NULL, 'login',  'srfsh',        'authen', oils_i18n_gettext(2 , 'Login via srfsh', 'cuat', 'label'))
    ,(3,  NULL, 'login',  'gateway-v1',   'authen', oils_i18n_gettext(3 , 'Login via gateway-v1', 'cuat', 'label'))
    ,(4,  NULL, 'login',  'translator-v1','authen', oils_i18n_gettext(4 , 'Login via translator-v1', 'cuat', 'label'))
    ,(5,  NULL, 'login',  'xmlrpc',       'authen', oils_i18n_gettext(5 , 'Login via xmlrpc', 'cuat', 'label'))
    ,(6,  NULL, 'login',  'remoteauth',   'authen', oils_i18n_gettext(6 , 'Login via remoteauth', 'cuat', 'label'))
    ,(7,  NULL, 'login',  'sip2',         'authen', oils_i18n_gettext(7 , 'SIP2 Proxy Login', 'cuat', 'label'))
    ,(8,  NULL, 'login',  'apache',       'authen', oils_i18n_gettext(8 , 'Login via Apache module', 'cuat', 'label'))

    ,(9,  NULL, 'verify', 'opensrf',      'authz',  oils_i18n_gettext(9 , 'Verification via opensrf', 'cuat', 'label'))
    ,(10, NULL, 'verify', 'srfsh',        'authz',  oils_i18n_gettext(10, 'Verification via srfsh', 'cuat', 'label'))
    ,(11, NULL, 'verify', 'gateway-v1',   'authz',  oils_i18n_gettext(11, 'Verification via gateway-v1', 'cuat', 'label'))
    ,(12, NULL, 'verify', 'translator-v1','authz',  oils_i18n_gettext(12, 'Verification via translator-v1', 'cuat', 'label'))
    ,(13, NULL, 'verify', 'xmlrpc',       'authz',  oils_i18n_gettext(13, 'Verification via xmlrpc', 'cuat', 'label'))
    ,(14, NULL, 'verify', 'remoteauth',   'authz',  oils_i18n_gettext(14, 'Verification via remoteauth', 'cuat', 'label'))
    ,(15, NULL, 'verify', 'sip2',         'authz',  oils_i18n_gettext(15, 'SIP2 User Verification', 'cuat', 'label'))

     -- authen/authz actions w/ known uses of "who"
    ,(16, 'opac',        'login',  'gateway-v1',   'authen', oils_i18n_gettext(16, 'OPAC Login (jspac)', 'cuat', 'label'))
    ,(17, 'opac',        'login',  'apache',       'authen', oils_i18n_gettext(17, 'OPAC Login (tpac)', 'cuat', 'label'))
    ,(18, 'staffclient', 'login',  'gateway-v1',   'authen', oils_i18n_gettext(18, 'Staff Client Login', 'cuat', 'label'))
    ,(19, 'selfcheck',   'login',  'translator-v1','authen', oils_i18n_gettext(19, 'Self-Check Proxy Login', 'cuat', 'label'))
    ,(20, 'ums',         'login',  'xmlrpc',       'authen', oils_i18n_gettext(20, 'Unique Mgt Login', 'cuat', 'label'))
    ,(21, 'authproxy',   'login',  'apache',       'authen', oils_i18n_gettext(21, 'Apache Auth Proxy Login', 'cuat', 'label'))
    ,(22, 'libraryelf',  'login',  'xmlrpc',       'authz',  oils_i18n_gettext(22, 'LibraryElf Login', 'cuat', 'label'))

    ,(23, 'selfcheck',   'verify', 'translator-v1','authz',  oils_i18n_gettext(23, 'Self-Check User Verification', 'cuat', 'label'))
    ,(24, 'ezproxy',     'verify', 'remoteauth',   'authz',  oils_i18n_gettext(24, 'EZProxy Verification', 'cuat', 'label'))
    -- ...
    ;
-- reserve the first 1000 slots
SELECT SETVAL('config.usr_activity_type_id_seq'::TEXT, 1000);

INSERT INTO config.org_unit_setting_type 
    (name, label, description, grp, datatype) 
    VALUES (
        'circ.patron.usr_activity_retrieve.max',
         oils_i18n_gettext(
            'circ.patron.usr_activity_retrieve.max',
            'Max user activity entries to retrieve (staff client)',
            'coust', 
            'label'
        ),
        oils_i18n_gettext(
            'circ.patron.usr_activity_retrieve.max',
            'Sets the maxinum number of recent user activity entries to retrieve for display in the staff client.  0 means show none, -1 means show all.  Default is 1.',
            'coust', 
            'description'
        ),
        'gui',
        'integer'
    );

INSERT INTO config.org_unit_setting_type
    (name, label, description, grp, datatype)
    VALUES (
        'circ.fines.charge_when_closed',
         oils_i18n_gettext(
            'circ.fines.charge_when_closed',
            'Charge fines on overdue circulations when closed',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'circ.fines.charge_when_closed',
            'Normally, fines are not charged when a library is closed.  When set to True, fines will be charged during scheduled closings and normal weekly closed days.',
            'coust',
            'description'
        ),
        'circ',
        'bool'
    );

	INSERT into config.org_unit_setting_type
( name, grp, label, description, datatype, fm_class ) VALUES

( 'ui.patron.edit.au.prefix.require', 'gui',
    oils_i18n_gettext('ui.patron.edit.au.prefix.require',
        'Require prefix field on patron registration',
        'coust', 'label'),
    oils_i18n_gettext('ui.patron.edit.au.prefix.require',
        'The prefix field will be required on the patron registration screen.',
        'coust', 'description'),
    'bool', null)
	
,( 'ui.patron.edit.au.prefix.show', 'gui',
    oils_i18n_gettext('ui.patron.edit.au.prefix.show',
        'Show prefix field on patron registration',
        'coust', 'label'),
    oils_i18n_gettext('ui.patron.edit.au.prefix.show',
        'The prefix field will be shown on the patron registration screen. Showing a field makes it appear with required fields even when not required. If the field is required this setting is ignored.',
        'coust', 'description'),
    'bool', null)

,( 'ui.patron.edit.au.prefix.suggest', 'gui',
    oils_i18n_gettext('ui.patron.edit.au.prefix.suggest',
        'Suggest prefix field on patron registration',
        'coust', 'label'),
    oils_i18n_gettext('ui.patron.edit.au.prefix.suggest',
        'The prefix field will be suggested on the patron registration screen. Suggesting a field makes it appear when suggested fields are shown. If the field is shown or required this setting is ignored.',
        'coust', 'description'),
    'bool', null)
;		
INSERT INTO config.usr_setting_type (name,opac_visible,label,description,datatype)
    VALUES ('opac.default_pickup_location', TRUE, 'Default Hold Pickup Location', 'Default location for holds pickup', 'integer');

INSERT INTO config.org_unit_setting_type ( name, label, description, datatype, grp )
    VALUES (
        'ui.hide_copy_editor_fields',
        oils_i18n_gettext(
            'ui.hide_copy_editor_fields',
            'GUI: Hide these fields within the Item Attribute Editor',
            'coust',
            'label'
        ),
        oils_i18n_gettext(
            'ui.hide_copy_editor_fields',
            'This setting may be best maintained with the dedicated configuration'
            || ' interface within the Item Attribute Editor.  However, here it'
            || ' shows up as comma separated list of field identifiers to hide.',
            'coust',
            'description'
        ),
        'array',
        'gui'
    );

	INSERT INTO config.internal_flag (name, value, enabled) VALUES (
    'serial.rematerialize_on_same_holding_code', NULL, FALSE
);

INSERT INTO config.org_unit_setting_type (
    name, label, grp, description, datatype
) VALUES (
    'serial.default_display_grouping',
    'Default display grouping for serials distributions presented in the OPAC.',
    'serial',
    'Default display grouping for serials distributions presented in the OPAC. This can be "enum" or "chron".',
    'string'
);

UPDATE config.internal_flag
    SET enabled = TRUE
    WHERE name = 'serial.rematerialize_on_same_holding_code';

UPDATE config.internal_flag
    SET enabled = FALSE
    WHERE name = 'serial.rematerialize_on_same_holding_code';
	
INSERT INTO config.global_flag (name, enabled, label) 
    VALUES (
        'opac.org_unit.non_inherited_visibility',
        FALSE,
        oils_i18n_gettext(
            'opac.org_unit.non_inherited_visibility',
            'Org Units Do Not Inherit Visibility',
            'cgf',
            'label'
        )
    );

INSERT INTO config.settings_group (name, label) VALUES
('acq', oils_i18n_gettext('config.settings_group.system', 'Acquisitions', 'coust', 'label'));

UPDATE config.org_unit_setting_type
    SET grp = 'acq'
    WHERE name LIKE 'acq%';

SELECT SETVAL('config.coded_value_map_id_seq'::TEXT, (SELECT max(id) FROM config.coded_value_map));

INSERT INTO config.index_normalizer (name, description, func, param_count) VALUES (
	'Search Normalize',
	'Apply search normalization rules to the extracted text. A less extreme version of NACO normalization.',
	'search_normalize',
	0
);

UPDATE config.metabib_field_index_norm_map
    SET norm = (
        SELECT id FROM config.index_normalizer WHERE func = 'search_normalize'
    )
    WHERE norm = (
        SELECT id FROM config.index_normalizer WHERE func = 'naco_normalize'
    )
;

UPDATE config.metabib_field SET browse_field = FALSE WHERE id < 100 AND field_class = 'identifier';

-- FIXME: add/check SQL statements to perform the upgrade
-- Delete the index normalizer that was meant to remove spaces from ISSNs
-- but ended up breaking records with multiple ISSNs
-- Might be intensive, CHECK
DELETE FROM config.metabib_field_index_norm_map WHERE id IN (
    SELECT map.id FROM config.metabib_field_index_norm_map map
        INNER JOIN config.metabib_field cmf ON cmf.id = map.field
        INNER JOIN config.index_normalizer cin ON cin.id = map.norm
    WHERE cin.func = 'replace'
        AND cmf.field_class = 'identifier'
        AND cmf.name = 'issn'
        AND map.params = $$[" ",""]$$
);

UPDATE config.metabib_field
    SET xpath = $$//mods32:mods/mods32:titleNonfiling[mods32:title and not (@type)]$$,
        format = 'mods32'
    WHERE field_class = 'title' AND name = 'proper';

--Replaced xsl on 2/13 
UPDATE config.xml_transform SET xslt=$$<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.loc.gov/mods/v3" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="xlink marc" version="1.0">
	<xsl:output encoding="UTF-8" indent="yes" method="xml"/>
<!--
Revision 1.14 - Fixed template isValid and fields 010, 020, 022, 024, 028, and 037 to output additional identifier elements 
  with corresponding @type and @invalid eq 'yes' when subfields z or y (in the case of 022) exist in the MARCXML ::: 2007/01/04 17:35:20 cred

Revision 1.13 - Changed order of output under cartographics to reflect schema  2006/11/28 tmee
	
Revision 1.12 - Updated to reflect MODS 3.2 Mapping  2006/10/11 tmee
		
Revision 1.11 - The attribute objectPart moved from <languageTerm> to <language>
      2006/04/08  jrad

Revision 1.10 MODS 3.1 revisions to language and classification elements  
				(plus ability to find marc:collection embedded in wrapper elements such as SRU zs: wrappers)
				2006/02/06  ggar

Revision 1.9 subfield $y was added to field 242 2004/09/02 10:57 jrad

Revision 1.8 Subject chopPunctuation expanded and attribute fixes 2004/08/12 jrad

Revision 1.7 2004/03/25 08:29 jrad

Revision 1.6 various validation fixes 2004/02/20 ntra

Revision 1.5  2003/10/02 16:18:58  ntra
MODS2 to MODS3 updates, language unstacking and 
de-duping, chopPunctuation expanded

Revision 1.3  2003/04/03 00:07:19  ntra
Revision 1.3 Additional Changes not related to MODS Version 2.0 by ntra

Revision 1.2  2003/03/24 19:37:42  ckeith
Added Log Comment

-->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="//marc:collection">
				<modsCollection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-2.xsd">
					<xsl:for-each select="//marc:collection/marc:record">
						<mods version="3.2">
							<xsl:call-template name="marcRecord"/>
						</mods>
					</xsl:for-each>
				</modsCollection>
			</xsl:when>
			<xsl:otherwise>
				<mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.2" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-2.xsd">
					<xsl:for-each select="//marc:record">
						<xsl:call-template name="marcRecord"/>
					</xsl:for-each>
				</mods>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="marcRecord">
		<xsl:variable name="leader" select="marc:leader"/>
		<xsl:variable name="leader6" select="substring($leader,7,1)"/>
		<xsl:variable name="leader7" select="substring($leader,8,1)"/>
		<xsl:variable name="controlField008" select="marc:controlfield[@tag='008']"/>
		<xsl:variable name="typeOf008">
			<xsl:choose>
				<xsl:when test="$leader6='a'">
					<xsl:choose>
						<xsl:when test="$leader7='a' or $leader7='c' or $leader7='d' or $leader7='m'">BK</xsl:when>
						<xsl:when test="$leader7='b' or $leader7='i' or $leader7='s'">SE</xsl:when>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$leader6='t'">BK</xsl:when>
				<xsl:when test="$leader6='p'">MM</xsl:when>
				<xsl:when test="$leader6='m'">CF</xsl:when>
				<xsl:when test="$leader6='e' or $leader6='f'">MP</xsl:when>
				<xsl:when test="$leader6='g' or $leader6='k' or $leader6='o' or $leader6='r'">VM</xsl:when>
				<xsl:when test="$leader6='c' or $leader6='d' or $leader6='i' or $leader6='j'">MU</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:for-each select="marc:datafield[@tag='245']">
			<titleInfo>
				<xsl:variable name="title">
					<xsl:choose>
						<xsl:when test="marc:subfield[@code='b']">
							<xsl:call-template name="specialSubfieldSelect">
								<xsl:with-param name="axis">b</xsl:with-param>
								<xsl:with-param name="beforeCodes">afgk</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">abfgk</xsl:with-param>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="titleChop">
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="$title"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="@ind2>0">
						<nonSort>
							<xsl:value-of select="substring($titleChop,1,@ind2)"/>
						</nonSort>
						<title>
							<xsl:value-of select="substring($titleChop,@ind2+1)"/>
						</title>
					</xsl:when>
					<xsl:otherwise>
						<title>
							<xsl:value-of select="$titleChop"/>
						</title>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="marc:subfield[@code='b']">
					<subTitle>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="axis">b</xsl:with-param>
									<xsl:with-param name="anyCodes">b</xsl:with-param>
									<xsl:with-param name="afterCodes">afgk</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</subTitle>
				</xsl:if>
				<xsl:call-template name="part"></xsl:call-template>
			</titleInfo>
			<!-- A form of title that ignores non-filing characters; useful
				 for not converting "L'Oreal" into "L' Oreal" at index time -->
			<titleNonfiling>
				<xsl:variable name="title">
					<xsl:choose>
						<xsl:when test="marc:subfield[@code='b']">
							<xsl:call-template name="specialSubfieldSelect">
								<xsl:with-param name="axis">b</xsl:with-param>
								<xsl:with-param name="beforeCodes">afgk</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">abfgk</xsl:with-param>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<title>
					<xsl:value-of select="$title"/>
				</title>
				<xsl:if test="marc:subfield[@code='b']">
					<subTitle>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="axis">b</xsl:with-param>
									<xsl:with-param name="anyCodes">b</xsl:with-param>
									<xsl:with-param name="afterCodes">afgk</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</subTitle>
				</xsl:if>
				<xsl:call-template name="part"></xsl:call-template>
			</titleNonfiling>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='210']">
			<titleInfo type="abbreviated">
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">a</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:call-template name="subtitle"/>
			</titleInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='242']">
			<titleInfo type="translated">
				<!--09/01/04 Added subfield $y-->
				<xsl:for-each select="marc:subfield[@code='y']">
					<xsl:attribute name="lang">
						<xsl:value-of select="text()"/>
					</xsl:attribute>
				</xsl:for-each>
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<!-- 1/04 removed $h, b -->
								<xsl:with-param name="codes">a</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<!-- 1/04 fix -->
				<xsl:call-template name="subtitle"/>
				<xsl:call-template name="part"/>
			</titleInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='246']">
			<titleInfo type="alternative">
				<xsl:for-each select="marc:subfield[@code='i']">
					<xsl:attribute name="displayLabel">
						<xsl:value-of select="text()"/>
					</xsl:attribute>
				</xsl:for-each>
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<!-- 1/04 removed $h, $b -->
								<xsl:with-param name="codes">af</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:call-template name="subtitle"/>
				<xsl:call-template name="part"/>
			</titleInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='130']|marc:datafield[@tag='240']|marc:datafield[@tag='730'][@ind2!='2']">
			<titleInfo type="uniform">
				<title>
					<xsl:variable name="str">
						<xsl:for-each select="marc:subfield">
							<xsl:if test="(contains('adfklmor',@code) and (not(../marc:subfield[@code='n' or @code='p']) or (following-sibling::marc:subfield[@code='n' or @code='p'])))">
								<xsl:value-of select="text()"/>
								<xsl:text> </xsl:text>
							</xsl:if>
						</xsl:for-each>
					</xsl:variable>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="substring($str,1,string-length($str)-1)"/>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:call-template name="part"/>
			</titleInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='740'][@ind2!='2']">
			<titleInfo type="alternative">
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">ah</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:call-template name="part"/>
			</titleInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='100']">
			<name type="personal">
				<xsl:call-template name="nameABCDQ"/>
				<xsl:call-template name="affiliation"/>
				<role>
					<roleTerm authority="marcrelator" type="text">creator</roleTerm>
				</role>
				<xsl:call-template name="role"/>
			</name>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='110']">
			<name type="corporate">
				<xsl:call-template name="nameABCDN"/>
				<role>
					<roleTerm authority="marcrelator" type="text">creator</roleTerm>
				</role>
				<xsl:call-template name="role"/>
			</name>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='111']">
			<name type="conference">
				<xsl:call-template name="nameACDEQ"/>
				<role>
					<roleTerm authority="marcrelator" type="text">creator</roleTerm>
				</role>
				<xsl:call-template name="role"/>
			</name>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='700'][not(marc:subfield[@code='t'])]">
			<name type="personal">
				<xsl:call-template name="nameABCDQ"/>
				<xsl:call-template name="affiliation"/>
				<xsl:call-template name="role"/>
			</name>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='710'][not(marc:subfield[@code='t'])]">
			<name type="corporate">
				<xsl:call-template name="nameABCDN"/>
				<xsl:call-template name="role"/>
			</name>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='711'][not(marc:subfield[@code='t'])]">
			<name type="conference">
				<xsl:call-template name="nameACDEQ"/>
				<xsl:call-template name="role"/>
			</name>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='720'][not(marc:subfield[@code='t'])]">
			<name>
				<xsl:if test="@ind1=1">
					<xsl:attribute name="type">
						<xsl:text>personal</xsl:text>
					</xsl:attribute>
				</xsl:if>
				<namePart>
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</namePart>
				<xsl:call-template name="role"/>
			</name>
		</xsl:for-each>
		<typeOfResource>
			<xsl:if test="$leader7='c'">
				<xsl:attribute name="collection">yes</xsl:attribute>
			</xsl:if>
			<xsl:if test="$leader6='d' or $leader6='f' or $leader6='p' or $leader6='t'">
				<xsl:attribute name="manuscript">yes</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="$leader6='a' or $leader6='t'">text</xsl:when>
				<xsl:when test="$leader6='e' or $leader6='f'">cartographic</xsl:when>
				<xsl:when test="$leader6='c' or $leader6='d'">notated music</xsl:when>
				<xsl:when test="$leader6='i'">sound recording-nonmusical</xsl:when>
				<xsl:when test="$leader6='j'">sound recording-musical</xsl:when>
				<xsl:when test="$leader6='k'">still image</xsl:when>
				<xsl:when test="$leader6='g'">moving image</xsl:when>
				<xsl:when test="$leader6='r'">three dimensional object</xsl:when>
				<xsl:when test="$leader6='m'">software, multimedia</xsl:when>
				<xsl:when test="$leader6='p'">mixed material</xsl:when>
			</xsl:choose>
		</typeOfResource>
		<xsl:if test="substring($controlField008,26,1)='d'">
			<genre authority="marc">globe</genre>
		</xsl:if>
		<xsl:if test="marc:controlfield[@tag='007'][substring(text(),1,1)='a'][substring(text(),2,1)='r']">
			<genre authority="marc">remote sensing image</genre>
		</xsl:if>
		<xsl:if test="$typeOf008='MP'">
			<xsl:variable name="controlField008-25" select="substring($controlField008,26,1)"></xsl:variable>
			<xsl:choose>
				<xsl:when test="$controlField008-25='a' or $controlField008-25='b' or $controlField008-25='c' or marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='j']">
					<genre authority="marc">map</genre>
				</xsl:when>
				<xsl:when test="$controlField008-25='e' or marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='d']">
					<genre authority="marc">atlas</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='SE'">
			<xsl:variable name="controlField008-21" select="substring($controlField008,22,1)"></xsl:variable>
			<xsl:choose>
				<xsl:when test="$controlField008-21='d'">
					<genre authority="marc">database</genre>
				</xsl:when>
				<xsl:when test="$controlField008-21='l'">
					<genre authority="marc">loose-leaf</genre>
				</xsl:when>
				<xsl:when test="$controlField008-21='m'">
					<genre authority="marc">series</genre>
				</xsl:when>
				<xsl:when test="$controlField008-21='n'">
					<genre authority="marc">newspaper</genre>
				</xsl:when>
				<xsl:when test="$controlField008-21='p'">
					<genre authority="marc">periodical</genre>
				</xsl:when>
				<xsl:when test="$controlField008-21='w'">
					<genre authority="marc">web site</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='BK' or $typeOf008='SE'">
			<xsl:variable name="controlField008-24" select="substring($controlField008,25,4)"></xsl:variable>
			<xsl:choose>
				<xsl:when test="contains($controlField008-24,'a')">
					<genre authority="marc">abstract or summary</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'b')">
					<genre authority="marc">bibliography</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'c')">
					<genre authority="marc">catalog</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'d')">
					<genre authority="marc">dictionary</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'e')">
					<genre authority="marc">encyclopedia</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'f')">
					<genre authority="marc">handbook</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'g')">
					<genre authority="marc">legal article</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'i')">
					<genre authority="marc">index</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'k')">
					<genre authority="marc">discography</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'l')">
					<genre authority="marc">legislation</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'m')">
					<genre authority="marc">theses</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'n')">
					<genre authority="marc">survey of literature</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'o')">
					<genre authority="marc">review</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'p')">
					<genre authority="marc">programmed text</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'q')">
					<genre authority="marc">filmography</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'r')">
					<genre authority="marc">directory</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'s')">
					<genre authority="marc">statistics</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'t')">
					<genre authority="marc">technical report</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'v')">
					<genre authority="marc">legal case and case notes</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'w')">
					<genre authority="marc">law report or digest</genre>
				</xsl:when>
				<xsl:when test="contains($controlField008-24,'z')">
					<genre authority="marc">treaty</genre>
				</xsl:when>
			</xsl:choose>
			<xsl:variable name="controlField008-29" select="substring($controlField008,30,1)"></xsl:variable>
			<xsl:choose>
				<xsl:when test="$controlField008-29='1'">
					<genre authority="marc">conference publication</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='CF'">
			<xsl:variable name="controlField008-26" select="substring($controlField008,27,1)"></xsl:variable>
			<xsl:choose>
				<xsl:when test="$controlField008-26='a'">
					<genre authority="marc">numeric data</genre>
				</xsl:when>
				<xsl:when test="$controlField008-26='e'">
					<genre authority="marc">database</genre>
				</xsl:when>
				<xsl:when test="$controlField008-26='f'">
					<genre authority="marc">font</genre>
				</xsl:when>
				<xsl:when test="$controlField008-26='g'">
					<genre authority="marc">game</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='BK'">
			<xsl:if test="substring($controlField008,25,1)='j'">
				<genre authority="marc">patent</genre>
			</xsl:if>
			<xsl:if test="substring($controlField008,31,1)='1'">
				<genre authority="marc">festschrift</genre>
			</xsl:if>
			<xsl:variable name="controlField008-34" select="substring($controlField008,35,1)"></xsl:variable>
			<xsl:if test="$controlField008-34='a' or $controlField008-34='b' or $controlField008-34='c' or $controlField008-34='d'">
				<genre authority="marc">biography</genre>
			</xsl:if>
			<xsl:variable name="controlField008-33" select="substring($controlField008,34,1)"></xsl:variable>
			<xsl:choose>
				<xsl:when test="$controlField008-33='e'">
					<genre authority="marc">essay</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='d'">
					<genre authority="marc">drama</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='c'">
					<genre authority="marc">comic strip</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='l'">
					<genre authority="marc">fiction</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='h'">
					<genre authority="marc">humor, satire</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='i'">
					<genre authority="marc">letter</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='f'">
					<genre authority="marc">novel</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='j'">
					<genre authority="marc">short story</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='s'">
					<genre authority="marc">speech</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="$typeOf008='MU'">
			<xsl:variable name="controlField008-30-31" select="substring($controlField008,31,2)"></xsl:variable>
			<xsl:if test="contains($controlField008-30-31,'b')">
				<genre authority="marc">biography</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'c')">
				<genre authority="marc">conference publication</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'d')">
				<genre authority="marc">drama</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'e')">
				<genre authority="marc">essay</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'f')">
				<genre authority="marc">fiction</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'o')">
				<genre authority="marc">folktale</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'h')">
				<genre authority="marc">history</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'k')">
				<genre authority="marc">humor, satire</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'m')">
				<genre authority="marc">memoir</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'p')">
				<genre authority="marc">poetry</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'r')">
				<genre authority="marc">rehearsal</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'g')">
				<genre authority="marc">reporting</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'s')">
				<genre authority="marc">sound</genre>
			</xsl:if>
			<xsl:if test="contains($controlField008-30-31,'l')">
				<genre authority="marc">speech</genre>
			</xsl:if>
		</xsl:if>
		<xsl:if test="$typeOf008='VM'">
			<xsl:variable name="controlField008-33" select="substring($controlField008,34,1)"></xsl:variable>
			<xsl:choose>
				<xsl:when test="$controlField008-33='a'">
					<genre authority="marc">art original</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='b'">
					<genre authority="marc">kit</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='c'">
					<genre authority="marc">art reproduction</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='d'">
					<genre authority="marc">diorama</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='f'">
					<genre authority="marc">filmstrip</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='g'">
					<genre authority="marc">legal article</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='i'">
					<genre authority="marc">picture</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='k'">
					<genre authority="marc">graphic</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='l'">
					<genre authority="marc">technical drawing</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='m'">
					<genre authority="marc">motion picture</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='n'">
					<genre authority="marc">chart</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='o'">
					<genre authority="marc">flash card</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='p'">
					<genre authority="marc">microscope slide</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='q' or marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='q']">
					<genre authority="marc">model</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='r'">
					<genre authority="marc">realia</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='s'">
					<genre authority="marc">slide</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='t'">
					<genre authority="marc">transparency</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='v'">
					<genre authority="marc">videorecording</genre>
				</xsl:when>
				<xsl:when test="$controlField008-33='w'">
					<genre authority="marc">toy</genre>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:for-each select="marc:datafield[@tag=655]">
			<genre authority="marc">
				<xsl:attribute name="authority">
					<xsl:value-of select="marc:subfield[@code='2']"/>
				</xsl:attribute>
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">abvxyz</xsl:with-param>
					<xsl:with-param name="delimeter">-</xsl:with-param>
				</xsl:call-template>
			</genre>
		</xsl:for-each>
		<originInfo>
			<xsl:variable name="MARCpublicationCode" select="normalize-space(substring($controlField008,16,3))"></xsl:variable>
			<xsl:if test="translate($MARCpublicationCode,'|','')">
				<place>
					<placeTerm>
						<xsl:attribute name="type">code</xsl:attribute>
						<xsl:attribute name="authority">marccountry</xsl:attribute>
						<xsl:value-of select="$MARCpublicationCode"/>
					</placeTerm>
				</place>
			</xsl:if>
			<xsl:for-each select="marc:datafield[@tag=044]/marc:subfield[@code='c']">
				<place>
					<placeTerm>
						<xsl:attribute name="type">code</xsl:attribute>
						<xsl:attribute name="authority">iso3166</xsl:attribute>
						<xsl:value-of select="."/>
					</placeTerm>
				</place>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=260]/marc:subfield[@code='a']">
				<place>
					<placeTerm>
						<xsl:attribute name="type">text</xsl:attribute>
						<xsl:call-template name="chopPunctuationFront">
							<xsl:with-param name="chopString">
								<xsl:call-template name="chopPunctuation">
									<xsl:with-param name="chopString" select="."/>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</placeTerm>
				</place>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=046]/marc:subfield[@code='m']">
				<dateValid point="start">
					<xsl:value-of select="."/>
				</dateValid>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=046]/marc:subfield[@code='n']">
				<dateValid point="end">
					<xsl:value-of select="."/>
				</dateValid>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=046]/marc:subfield[@code='j']">
				<dateModified>
					<xsl:value-of select="."/>
				</dateModified>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=260]/marc:subfield[@code='b' or @code='c' or @code='g']">
				<xsl:choose>
					<xsl:when test="@code='b'">
						<publisher>
							<xsl:call-template name="chopPunctuation">
								<xsl:with-param name="chopString" select="."/>
								<xsl:with-param name="punctuation">
									<xsl:text>:,;/ </xsl:text>
								</xsl:with-param>
							</xsl:call-template>
						</publisher>
					</xsl:when>
					<xsl:when test="@code='c'">
						<dateIssued>
							<xsl:call-template name="chopPunctuation">
								<xsl:with-param name="chopString" select="."/>
							</xsl:call-template>
						</dateIssued>
					</xsl:when>
					<xsl:when test="@code='g'">
						<dateCreated>
							<xsl:value-of select="."/>
						</dateCreated>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
			<xsl:variable name="dataField260c">
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="marc:datafield[@tag=260]/marc:subfield[@code='c']"></xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="controlField008-7-10" select="normalize-space(substring($controlField008, 8, 4))"></xsl:variable>
			<xsl:variable name="controlField008-11-14" select="normalize-space(substring($controlField008, 12, 4))"></xsl:variable>
			<xsl:variable name="controlField008-6" select="normalize-space(substring($controlField008, 7, 1))"></xsl:variable>
			<xsl:if test="$controlField008-6='e' or $controlField008-6='p' or $controlField008-6='r' or $controlField008-6='t' or $controlField008-6='s'">
				<xsl:if test="$controlField008-7-10 and ($controlField008-7-10 != $dataField260c)">
					<dateIssued encoding="marc">
						<xsl:value-of select="$controlField008-7-10"/>
					</dateIssued>
				</xsl:if>
			</xsl:if>
			<xsl:if test="$controlField008-6='c' or $controlField008-6='d' or $controlField008-6='i' or $controlField008-6='k' or $controlField008-6='m' or $controlField008-6='q' or $controlField008-6='u'">
				<xsl:if test="$controlField008-7-10">
					<dateIssued encoding="marc" point="start">
						<xsl:value-of select="$controlField008-7-10"/>
					</dateIssued>
				</xsl:if>
			</xsl:if>
			<xsl:if test="$controlField008-6='c' or $controlField008-6='d' or $controlField008-6='i' or $controlField008-6='k' or $controlField008-6='m' or $controlField008-6='q' or $controlField008-6='u'">
				<xsl:if test="$controlField008-11-14">
					<dateIssued encoding="marc" point="end">
						<xsl:value-of select="$controlField008-11-14"/>
					</dateIssued>
				</xsl:if>
			</xsl:if>
			<xsl:if test="$controlField008-6='q'">
				<xsl:if test="$controlField008-7-10">
					<dateIssued encoding="marc" point="start" qualifier="questionable">
						<xsl:value-of select="$controlField008-7-10"/>
					</dateIssued>
				</xsl:if>
			</xsl:if>
			<xsl:if test="$controlField008-6='q'">
				<xsl:if test="$controlField008-11-14">
					<dateIssued encoding="marc" point="end" qualifier="questionable">
						<xsl:value-of select="$controlField008-11-14"/>
					</dateIssued>
				</xsl:if>
			</xsl:if>
			<xsl:if test="$controlField008-6='t'">
				<xsl:if test="$controlField008-11-14">
					<copyrightDate encoding="marc">
						<xsl:value-of select="$controlField008-11-14"/>
					</copyrightDate>
				</xsl:if>
			</xsl:if>
			<xsl:for-each select="marc:datafield[@tag=033][@ind1=0 or @ind1=1]/marc:subfield[@code='a']">
				<dateCaptured encoding="iso8601">
					<xsl:value-of select="."/>
				</dateCaptured>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=033][@ind1=2]/marc:subfield[@code='a'][1]">
				<dateCaptured encoding="iso8601" point="start">
					<xsl:value-of select="."/>
				</dateCaptured>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=033][@ind1=2]/marc:subfield[@code='a'][2]">
				<dateCaptured encoding="iso8601" point="end">
					<xsl:value-of select="."/>
				</dateCaptured>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=250]/marc:subfield[@code='a']">
				<edition>
					<xsl:value-of select="."/>
				</edition>
			</xsl:for-each>
			<xsl:for-each select="marc:leader">
				<issuance>
					<xsl:choose>
						<xsl:when test="$leader7='a' or $leader7='c' or $leader7='d' or $leader7='m'">monographic</xsl:when>
						<xsl:when test="$leader7='b' or $leader7='i' or $leader7='s'">continuing</xsl:when>
					</xsl:choose>
				</issuance>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=310]|marc:datafield[@tag=321]">
				<frequency>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">ab</xsl:with-param>
					</xsl:call-template>
				</frequency>
			</xsl:for-each>
		</originInfo>
		<xsl:variable name="controlField008-35-37" select="normalize-space(translate(substring($controlField008,36,3),'|#',''))"></xsl:variable>
		<xsl:if test="$controlField008-35-37">
			<language>
				<languageTerm authority="iso639-2b" type="code">
					<xsl:value-of select="substring($controlField008,36,3)"/>
				</languageTerm>
			</language>
		</xsl:if>
		<xsl:for-each select="marc:datafield[@tag=041]">
			<xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='d' or @code='e' or @code='f' or @code='g' or @code='h']">
				<xsl:variable name="langCodes" select="."/>
				<xsl:choose>
					<xsl:when test="../marc:subfield[@code='2']='rfc3066'">
						<!-- not stacked but could be repeated -->
						<xsl:call-template name="rfcLanguages">
							<xsl:with-param name="nodeNum">
								<xsl:value-of select="1"/>
							</xsl:with-param>
							<xsl:with-param name="usedLanguages">
								<xsl:text></xsl:text>
							</xsl:with-param>
							<xsl:with-param name="controlField008-35-37">
								<xsl:value-of select="$controlField008-35-37"></xsl:value-of>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<!-- iso -->
						<xsl:variable name="allLanguages">
							<xsl:copy-of select="$langCodes"></xsl:copy-of>
						</xsl:variable>
						<xsl:variable name="currentLanguage">
							<xsl:value-of select="substring($allLanguages,1,3)"></xsl:value-of>
						</xsl:variable>
						<xsl:call-template name="isoLanguage">
							<xsl:with-param name="currentLanguage">
								<xsl:value-of select="substring($allLanguages,1,3)"></xsl:value-of>
							</xsl:with-param>
							<xsl:with-param name="remainingLanguages">
								<xsl:value-of select="substring($allLanguages,4,string-length($allLanguages)-3)"></xsl:value-of>
							</xsl:with-param>
							<xsl:with-param name="usedLanguages">
								<xsl:if test="$controlField008-35-37">
									<xsl:value-of select="$controlField008-35-37"></xsl:value-of>
								</xsl:if>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:for-each>
		<xsl:variable name="physicalDescription">
			<!--3.2 change tmee 007/11 -->
			<xsl:if test="$typeOf008='CF' and marc:controlfield[@tag=007][substring(.,12,1)='a']">
				<digitalOrigin>reformatted digital</digitalOrigin>
			</xsl:if>
			<xsl:if test="$typeOf008='CF' and marc:controlfield[@tag=007][substring(.,12,1)='b']">
				<digitalOrigin>digitized microfilm</digitalOrigin>
			</xsl:if>
			<xsl:if test="$typeOf008='CF' and marc:controlfield[@tag=007][substring(.,12,1)='d']">
				<digitalOrigin>digitized other analog</digitalOrigin>
			</xsl:if>
			<xsl:variable name="controlField008-23" select="substring($controlField008,24,1)"></xsl:variable>
			<xsl:variable name="controlField008-29" select="substring($controlField008,30,1)"></xsl:variable>
			<xsl:variable name="check008-23">
				<xsl:if test="$typeOf008='BK' or $typeOf008='MU' or $typeOf008='SE' or $typeOf008='MM'">
					<xsl:value-of select="true()"></xsl:value-of>
				</xsl:if>
			</xsl:variable>
			<xsl:variable name="check008-29">
				<xsl:if test="$typeOf008='MP' or $typeOf008='VM'">
					<xsl:value-of select="true()"></xsl:value-of>
				</xsl:if>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="($check008-23 and $controlField008-23='f') or ($check008-29 and $controlField008-29='f')">
					<form authority="marcform">braille</form>
				</xsl:when>
				<xsl:when test="($controlField008-23=' ' and ($leader6='c' or $leader6='d')) or (($typeOf008='BK' or $typeOf008='SE') and ($controlField008-23=' ' or $controlField008='r'))">
					<form authority="marcform">print</form>
				</xsl:when>
				<xsl:when test="$leader6 = 'm' or ($check008-23 and $controlField008-23='s') or ($check008-29 and $controlField008-29='s')">
					<form authority="marcform">electronic</form>
				</xsl:when>
				<xsl:when test="($check008-23 and $controlField008-23='b') or ($check008-29 and $controlField008-29='b')">
					<form authority="marcform">microfiche</form>
				</xsl:when>
				<xsl:when test="($check008-23 and $controlField008-23='a') or ($check008-29 and $controlField008-29='a')">
					<form authority="marcform">microfilm</form>
				</xsl:when>
			</xsl:choose>
			<!-- 1/04 fix -->
			<xsl:if test="marc:datafield[@tag=130]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=130]/marc:subfield[@code='h']"></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:if test="marc:datafield[@tag=240]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=240]/marc:subfield[@code='h']"></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:if test="marc:datafield[@tag=242]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=242]/marc:subfield[@code='h']"></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:if test="marc:datafield[@tag=245]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=245]/marc:subfield[@code='h']"></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:if test="marc:datafield[@tag=246]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=246]/marc:subfield[@code='h']"></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:if test="marc:datafield[@tag=730]/marc:subfield[@code='h']">
				<form authority="gmd">
					<xsl:call-template name="chopBrackets">
						<xsl:with-param name="chopString">
							<xsl:value-of select="marc:datafield[@tag=730]/marc:subfield[@code='h']"></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</form>
			</xsl:if>
			<xsl:for-each select="marc:datafield[@tag=256]/marc:subfield[@code='a']">
				<form>
					<xsl:value-of select="."></xsl:value-of>
				</form>
			</xsl:for-each>
			<xsl:for-each select="marc:controlfield[@tag=007][substring(text(),1,1)='c']">
				<xsl:choose>
					<xsl:when test="substring(text(),14,1)='a'">
						<reformattingQuality>access</reformattingQuality>
					</xsl:when>
					<xsl:when test="substring(text(),14,1)='p'">
						<reformattingQuality>preservation</reformattingQuality>
					</xsl:when>
					<xsl:when test="substring(text(),14,1)='r'">
						<reformattingQuality>replacement</reformattingQuality>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
			<!--3.2 change tmee 007/01 -->
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='b']">
				<form authority="smd">chip cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='c']">
				<form authority="smd">computer optical disc cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='j']">
				<form authority="smd">magnetic disc</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='m']">
				<form authority="smd">magneto-optical disc</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='o']">
				<form authority="smd">optical disc</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='r']">
				<form authority="smd">remote</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='a']">
				<form authority="smd">tape cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='f']">
				<form authority="smd">tape cassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='c'][substring(text(),2,1)='h']">
				<form authority="smd">tape reel</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='d'][substring(text(),2,1)='a']">
				<form authority="smd">celestial globe</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='d'][substring(text(),2,1)='e']">
				<form authority="smd">earth moon globe</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='d'][substring(text(),2,1)='b']">
				<form authority="smd">planetary or lunar globe</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='d'][substring(text(),2,1)='c']">
				<form authority="smd">terrestrial globe</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='o'][substring(text(),2,1)='o']">
				<form authority="smd">kit</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='d']">
				<form authority="smd">atlas</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='g']">
				<form authority="smd">diagram</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='j']">
				<form authority="smd">map</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='q']">
				<form authority="smd">model</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='k']">
				<form authority="smd">profile</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='r']">
				<form authority="smd">remote-sensing image</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='s']">
				<form authority="smd">section</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='a'][substring(text(),2,1)='y']">
				<form authority="smd">view</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='a']">
				<form authority="smd">aperture card</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='e']">
				<form authority="smd">microfiche</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='f']">
				<form authority="smd">microfiche cassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='b']">
				<form authority="smd">microfilm cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='c']">
				<form authority="smd">microfilm cassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='d']">
				<form authority="smd">microfilm reel</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='h'][substring(text(),2,1)='g']">
				<form authority="smd">microopaque</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='m'][substring(text(),2,1)='c']">
				<form authority="smd">film cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='m'][substring(text(),2,1)='f']">
				<form authority="smd">film cassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='m'][substring(text(),2,1)='r']">
				<form authority="smd">film reel</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='n']">
				<form authority="smd">chart</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='c']">
				<form authority="smd">collage</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='d']">
				<form authority="smd">drawing</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='o']">
				<form authority="smd">flash card</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='e']">
				<form authority="smd">painting</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='f']">
				<form authority="smd">photomechanical print</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='g']">
				<form authority="smd">photonegative</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='h']">
				<form authority="smd">photoprint</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='i']">
				<form authority="smd">picture</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='j']">
				<form authority="smd">print</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='k'][substring(text(),2,1)='l']">
				<form authority="smd">technical drawing</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='q'][substring(text(),2,1)='q']">
				<form authority="smd">notated music</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='d']">
				<form authority="smd">filmslip</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='c']">
				<form authority="smd">filmstrip cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='o']">
				<form authority="smd">filmstrip roll</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='f']">
				<form authority="smd">other filmstrip type</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='s']">
				<form authority="smd">slide</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='g'][substring(text(),2,1)='t']">
				<form authority="smd">transparency</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='r'][substring(text(),2,1)='r']">
				<form authority="smd">remote-sensing image</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='e']">
				<form authority="smd">cylinder</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='q']">
				<form authority="smd">roll</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='g']">
				<form authority="smd">sound cartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='s']">
				<form authority="smd">sound cassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='d']">
				<form authority="smd">sound disc</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='t']">
				<form authority="smd">sound-tape reel</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='i']">
				<form authority="smd">sound-track film</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='s'][substring(text(),2,1)='w']">
				<form authority="smd">wire recording</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='f'][substring(text(),2,1)='c']">
				<form authority="smd">braille</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='f'][substring(text(),2,1)='b']">
				<form authority="smd">combination</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='f'][substring(text(),2,1)='a']">
				<form authority="smd">moon</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='f'][substring(text(),2,1)='d']">
				<form authority="smd">tactile, with no writing system</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='t'][substring(text(),2,1)='c']">
				<form authority="smd">braille</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='t'][substring(text(),2,1)='b']">
				<form authority="smd">large print</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='t'][substring(text(),2,1)='a']">
				<form authority="smd">regular print</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='t'][substring(text(),2,1)='d']">
				<form authority="smd">text in looseleaf binder</form>
			</xsl:if>
			
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='v'][substring(text(),2,1)='c']">
				<form authority="smd">videocartridge</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='v'][substring(text(),2,1)='f']">
				<form authority="smd">videocassette</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='v'][substring(text(),2,1)='d']">
				<form authority="smd">videodisc</form>
			</xsl:if>
			<xsl:if test="marc:controlfield[@tag=007][substring(text(),1,1)='v'][substring(text(),2,1)='r']">
				<form authority="smd">videoreel</form>
			</xsl:if>
			
			<xsl:for-each select="marc:datafield[@tag=856]/marc:subfield[@code='q'][string-length(.)>1]">
				<internetMediaType>
					<xsl:value-of select="."></xsl:value-of>
				</internetMediaType>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=300]">
				<extent>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">abce</xsl:with-param>
					</xsl:call-template>
				</extent>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="string-length(normalize-space($physicalDescription))">
			<physicalDescription>
				<xsl:copy-of select="$physicalDescription"></xsl:copy-of>
			</physicalDescription>
		</xsl:if>
		<xsl:for-each select="marc:datafield[@tag=520]">
			<abstract>
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">ab</xsl:with-param>
				</xsl:call-template>
			</abstract>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=505]">
			<tableOfContents>
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">agrt</xsl:with-param>
				</xsl:call-template>
			</tableOfContents>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=521]">
			<targetAudience>
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">ab</xsl:with-param>
				</xsl:call-template>
			</targetAudience>
		</xsl:for-each>
		<xsl:if test="$typeOf008='BK' or $typeOf008='CF' or $typeOf008='MU' or $typeOf008='VM'">
			<xsl:variable name="controlField008-22" select="substring($controlField008,23,1)"></xsl:variable>
			<xsl:choose>
				<!-- 01/04 fix -->
				<xsl:when test="$controlField008-22='d'">
					<targetAudience authority="marctarget">adolescent</targetAudience>
				</xsl:when>
				<xsl:when test="$controlField008-22='e'">
					<targetAudience authority="marctarget">adult</targetAudience>
				</xsl:when>
				<xsl:when test="$controlField008-22='g'">
					<targetAudience authority="marctarget">general</targetAudience>
				</xsl:when>
				<xsl:when test="$controlField008-22='b' or $controlField008-22='c' or $controlField008-22='j'">
					<targetAudience authority="marctarget">juvenile</targetAudience>
				</xsl:when>
				<xsl:when test="$controlField008-22='a'">
					<targetAudience authority="marctarget">preschool</targetAudience>
				</xsl:when>
				<xsl:when test="$controlField008-22='f'">
					<targetAudience authority="marctarget">specialized</targetAudience>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:for-each select="marc:datafield[@tag=245]/marc:subfield[@code='c']">
			<note type="statement of responsibility">
				<xsl:value-of select="."></xsl:value-of>
			</note>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=500]">
			<note>
				<xsl:value-of select="marc:subfield[@code='a']"></xsl:value-of>
				<xsl:call-template name="uri"></xsl:call-template>
			</note>
		</xsl:for-each>
		
		<!--3.2 change tmee additional note fields-->
		
		<xsl:for-each select="marc:datafield[@tag=506]">
			<note type="restrictions">
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield[@code!='6' or @code!='8']">
						<xsl:value-of select="."></xsl:value-of>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="substring($str,1,string-length($str)-1)"></xsl:value-of>
			</note>
		</xsl:for-each>
		
		<xsl:for-each select="marc:datafield[@tag=510]">
			<note  type="citation/reference">
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield[@code!='6' or @code!='8']">
						<xsl:value-of select="."></xsl:value-of>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="substring($str,1,string-length($str)-1)"></xsl:value-of>
			</note>
		</xsl:for-each>
		
			
		<xsl:for-each select="marc:datafield[@tag=511]">
			<note type="performers">
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:value-of select="marc:subfield[@code='a']"></xsl:value-of>
			</note>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=518]">
			<note type="venue">
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:value-of select="marc:subfield[@code='a']"></xsl:value-of>
			</note>
		</xsl:for-each>
		
		<xsl:for-each select="marc:datafield[@tag=530]">
			<note  type="additional physical form">
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield[@code!='6' or @code!='8']">
						<xsl:value-of select="."></xsl:value-of>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="substring($str,1,string-length($str)-1)"></xsl:value-of>
			</note>
		</xsl:for-each>
		
		<xsl:for-each select="marc:datafield[@tag=533]">
			<note  type="reproduction">
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield[@code!='6' or @code!='8']">
						<xsl:value-of select="."></xsl:value-of>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="substring($str,1,string-length($str)-1)"></xsl:value-of>
			</note>
		</xsl:for-each>
		
		<xsl:for-each select="marc:datafield[@tag=534]">
			<note  type="original version">
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield[@code!='6' or @code!='8']">
						<xsl:value-of select="."></xsl:value-of>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="substring($str,1,string-length($str)-1)"></xsl:value-of>
			</note>
		</xsl:for-each>
		
		<xsl:for-each select="marc:datafield[@tag=538]">
			<note  type="system details">
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield[@code!='6' or @code!='8']">
						<xsl:value-of select="."></xsl:value-of>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="substring($str,1,string-length($str)-1)"></xsl:value-of>
			</note>
		</xsl:for-each>
		
		<xsl:for-each select="marc:datafield[@tag=583]">
			<note type="action">
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield[@code!='6' or @code!='8']">
						<xsl:value-of select="."></xsl:value-of>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="substring($str,1,string-length($str)-1)"></xsl:value-of>
			</note>
		</xsl:for-each>
		

		
		
		
		<xsl:for-each select="marc:datafield[@tag=501 or @tag=502 or @tag=504 or @tag=507 or @tag=508 or  @tag=513 or @tag=514 or @tag=515 or @tag=516 or @tag=522 or @tag=524 or @tag=525 or @tag=526 or @tag=535 or @tag=536 or @tag=540 or @tag=541 or @tag=544 or @tag=545 or @tag=546 or @tag=547 or @tag=550 or @tag=552 or @tag=555 or @tag=556 or @tag=561 or @tag=562 or @tag=565 or @tag=567 or @tag=580 or @tag=581 or @tag=584 or @tag=585 or @tag=586]">
			<note>
				<xsl:call-template name="uri"></xsl:call-template>
				<xsl:variable name="str">
					<xsl:for-each select="marc:subfield[@code!='6' or @code!='8']">
						<xsl:value-of select="."></xsl:value-of>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="substring($str,1,string-length($str)-1)"></xsl:value-of>
			</note>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=034][marc:subfield[@code='d' or @code='e' or @code='f' or @code='g']]">
			<subject>
				<cartographics>
					<coordinates>
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">defg</xsl:with-param>
						</xsl:call-template>
					</coordinates>
				</cartographics>
			</subject>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=043]">
			<subject>
				<xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c']">
					<geographicCode>
						<xsl:attribute name="authority">
							<xsl:if test="@code='a'">
								<xsl:text>marcgac</xsl:text>
							</xsl:if>
							<xsl:if test="@code='b'">
								<xsl:value-of select="following-sibling::marc:subfield[@code=2]"></xsl:value-of>
							</xsl:if>
							<xsl:if test="@code='c'">
								<xsl:text>iso3166</xsl:text>
							</xsl:if>
						</xsl:attribute>
						<xsl:value-of select="self::marc:subfield"></xsl:value-of>
					</geographicCode>
				</xsl:for-each>
			</subject>
		</xsl:for-each>
		<!-- tmee 2006/11/27 -->
		<xsl:for-each select="marc:datafield[@tag=255]">
			<subject>
				<xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c']">
				<cartographics>
					<xsl:if test="@code='a'">
						<scale>
							<xsl:value-of select="."></xsl:value-of>
						</scale>
					</xsl:if>
					<xsl:if test="@code='b'">
						<projection>
							<xsl:value-of select="."></xsl:value-of>
						</projection>
					</xsl:if>
					<xsl:if test="@code='c'">
						<coordinates>
							<xsl:value-of select="."></xsl:value-of>
						</coordinates>
					</xsl:if>
				</cartographics>
				</xsl:for-each>
			</subject>
		</xsl:for-each>
				
		<xsl:apply-templates select="marc:datafield[653 >= @tag and @tag >= 600]"></xsl:apply-templates>
		<xsl:apply-templates select="marc:datafield[@tag=656]"></xsl:apply-templates>
		<xsl:for-each select="marc:datafield[@tag=752]">
			<subject>
				<hierarchicalGeographic>
					<xsl:for-each select="marc:subfield[@code='a']">
						<country>
							<xsl:call-template name="chopPunctuation">
								<xsl:with-param name="chopString" select="."></xsl:with-param>
							</xsl:call-template>
						</country>
					</xsl:for-each>
					<xsl:for-each select="marc:subfield[@code='b']">
						<state>
							<xsl:call-template name="chopPunctuation">
								<xsl:with-param name="chopString" select="."></xsl:with-param>
							</xsl:call-template>
						</state>
					</xsl:for-each>
					<xsl:for-each select="marc:subfield[@code='c']">
						<county>
							<xsl:call-template name="chopPunctuation">
								<xsl:with-param name="chopString" select="."></xsl:with-param>
							</xsl:call-template>
						</county>
					</xsl:for-each>
					<xsl:for-each select="marc:subfield[@code='d']">
						<city>
							<xsl:call-template name="chopPunctuation">
								<xsl:with-param name="chopString" select="."></xsl:with-param>
							</xsl:call-template>
						</city>
					</xsl:for-each>
				</hierarchicalGeographic>
			</subject>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=045][marc:subfield[@code='b']]">
			<subject>
				<xsl:choose>
					<xsl:when test="@ind1=2">
						<temporal encoding="iso8601" point="start">
							<xsl:call-template name="chopPunctuation">
								<xsl:with-param name="chopString">
									<xsl:value-of select="marc:subfield[@code='b'][1]"></xsl:value-of>
								</xsl:with-param>
							</xsl:call-template>
						</temporal>
						<temporal encoding="iso8601" point="end">
							<xsl:call-template name="chopPunctuation">
								<xsl:with-param name="chopString">
									<xsl:value-of select="marc:subfield[@code='b'][2]"></xsl:value-of>
								</xsl:with-param>
							</xsl:call-template>
						</temporal>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="marc:subfield[@code='b']">
							<temporal encoding="iso8601">
								<xsl:call-template name="chopPunctuation">
									<xsl:with-param name="chopString" select="."></xsl:with-param>
								</xsl:call-template>
							</temporal>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
			</subject>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=050]">
			<xsl:for-each select="marc:subfield[@code='b']">
				<classification authority="lcc">
					<xsl:if test="../marc:subfield[@code='3']">
						<xsl:attribute name="displayLabel">
							<xsl:value-of select="../marc:subfield[@code='3']"></xsl:value-of>
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="preceding-sibling::marc:subfield[@code='a'][1]"></xsl:value-of>
					<xsl:text> </xsl:text>
					<xsl:value-of select="text()"></xsl:value-of>
				</classification>
			</xsl:for-each>
			<xsl:for-each select="marc:subfield[@code='a'][not(following-sibling::marc:subfield[@code='b'])]">
				<classification authority="lcc">
					<xsl:if test="../marc:subfield[@code='3']">
						<xsl:attribute name="displayLabel">
							<xsl:value-of select="../marc:subfield[@code='3']"></xsl:value-of>
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="text()"></xsl:value-of>
				</classification>
			</xsl:for-each>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=082]">
			<classification authority="ddc">
				<xsl:if test="marc:subfield[@code='2']">
					<xsl:attribute name="edition">
						<xsl:value-of select="marc:subfield[@code='2']"></xsl:value-of>
					</xsl:attribute>
				</xsl:if>
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">ab</xsl:with-param>
				</xsl:call-template>
			</classification>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=080]">
			<classification authority="udc">
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">abx</xsl:with-param>
				</xsl:call-template>
			</classification>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=060]">
			<classification authority="nlm">
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">ab</xsl:with-param>
				</xsl:call-template>
			</classification>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=086][@ind1=0]">
			<classification authority="sudocs">
				<xsl:value-of select="marc:subfield[@code='a']"></xsl:value-of>
			</classification>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=086][@ind1=1]">
			<classification authority="candoc">
				<xsl:value-of select="marc:subfield[@code='a']"></xsl:value-of>
			</classification>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=086]">
			<classification>
				<xsl:attribute name="authority">
					<xsl:value-of select="marc:subfield[@code='2']"></xsl:value-of>
				</xsl:attribute>
				<xsl:value-of select="marc:subfield[@code='a']"></xsl:value-of>
			</classification>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=084]">
			<classification>
				<xsl:attribute name="authority">
					<xsl:value-of select="marc:subfield[@code='2']"></xsl:value-of>
				</xsl:attribute>
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">ab</xsl:with-param>
				</xsl:call-template>
			</classification>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=440]">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">av</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"></xsl:call-template>
				</titleInfo>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=490][@ind1=0]">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">av</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"></xsl:call-template>
				</titleInfo>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=510]">
			<relatedItem type="isReferencedBy">
				<note>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">abcx3</xsl:with-param>
					</xsl:call-template>
				</note>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=534]">
			<relatedItem type="original">
				<xsl:call-template name="relatedTitle"></xsl:call-template>
				<xsl:call-template name="relatedName"></xsl:call-template>
				<xsl:if test="marc:subfield[@code='b' or @code='c']">
					<originInfo>
						<xsl:for-each select="marc:subfield[@code='c']">
							<publisher>
								<xsl:value-of select="."></xsl:value-of>
							</publisher>
						</xsl:for-each>
						<xsl:for-each select="marc:subfield[@code='b']">
							<edition>
								<xsl:value-of select="."></xsl:value-of>
							</edition>
						</xsl:for-each>
					</originInfo>
				</xsl:if>
				<xsl:call-template name="relatedIdentifierISSN"></xsl:call-template>
				<xsl:for-each select="marc:subfield[@code='z']">
					<identifier type="isbn">
						<xsl:value-of select="."></xsl:value-of>
					</identifier>
				</xsl:for-each>
				<xsl:call-template name="relatedNote"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=700][marc:subfield[@code='t']]">
			<relatedItem>
				<xsl:call-template name="constituentOrRelatedType"></xsl:call-template>
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklmorsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">g</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"></xsl:call-template>
				</titleInfo>
				<name type="personal">
					<namePart>
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="anyCodes">aq</xsl:with-param>
							<xsl:with-param name="axis">t</xsl:with-param>
							<xsl:with-param name="beforeCodes">g</xsl:with-param>
						</xsl:call-template>
					</namePart>
					<xsl:call-template name="termsOfAddress"></xsl:call-template>
					<xsl:call-template name="nameDate"></xsl:call-template>
					<xsl:call-template name="role"></xsl:call-template>
				</name>
				<xsl:call-template name="relatedForm"></xsl:call-template>
				<xsl:call-template name="relatedIdentifierISSN"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=710][marc:subfield[@code='t']]">
			<relatedItem>
				<xsl:call-template name="constituentOrRelatedType"></xsl:call-template>
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklmorsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">dg</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="relatedPartNumName"></xsl:call-template>
				</titleInfo>
				<name type="corporate">
					<xsl:for-each select="marc:subfield[@code='a']">
						<namePart>
							<xsl:value-of select="."></xsl:value-of>
						</namePart>
					</xsl:for-each>
					<xsl:for-each select="marc:subfield[@code='b']">
						<namePart>
							<xsl:value-of select="."></xsl:value-of>
						</namePart>
					</xsl:for-each>
					<xsl:variable name="tempNamePart">
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="anyCodes">c</xsl:with-param>
							<xsl:with-param name="axis">t</xsl:with-param>
							<xsl:with-param name="beforeCodes">dgn</xsl:with-param>
						</xsl:call-template>
					</xsl:variable>
					<xsl:if test="normalize-space($tempNamePart)">
						<namePart>
							<xsl:value-of select="$tempNamePart"></xsl:value-of>
						</namePart>
					</xsl:if>
					<xsl:call-template name="role"></xsl:call-template>
				</name>
				<xsl:call-template name="relatedForm"></xsl:call-template>
				<xsl:call-template name="relatedIdentifierISSN"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=711][marc:subfield[@code='t']]">
			<relatedItem>
				<xsl:call-template name="constituentOrRelatedType"></xsl:call-template>
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">g</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="relatedPartNumName"></xsl:call-template>
				</titleInfo>
				<name type="conference">
					<namePart>
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="anyCodes">aqdc</xsl:with-param>
							<xsl:with-param name="axis">t</xsl:with-param>
							<xsl:with-param name="beforeCodes">gn</xsl:with-param>
						</xsl:call-template>
					</namePart>
				</name>
				<xsl:call-template name="relatedForm"></xsl:call-template>
				<xsl:call-template name="relatedIdentifierISSN"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=730][@ind2=2]">
			<relatedItem>
				<xsl:call-template name="constituentOrRelatedType"></xsl:call-template>
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">adfgklmorsv</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"></xsl:call-template>
				</titleInfo>
				<xsl:call-template name="relatedForm"></xsl:call-template>
				<xsl:call-template name="relatedIdentifierISSN"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=740][@ind2=2]">
			<relatedItem>
				<xsl:call-template name="constituentOrRelatedType"></xsl:call-template>
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:value-of select="marc:subfield[@code='a']"></xsl:value-of>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"></xsl:call-template>
				</titleInfo>
				<xsl:call-template name="relatedForm"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=760]|marc:datafield[@tag=762]">
			<relatedItem type="series">
				<xsl:call-template name="relatedItem76X-78X"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=765]|marc:datafield[@tag=767]|marc:datafield[@tag=777]|marc:datafield[@tag=787]">
			<relatedItem>
				<xsl:call-template name="relatedItem76X-78X"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=775]">
			<relatedItem type="otherVersion">
				<xsl:call-template name="relatedItem76X-78X"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=770]|marc:datafield[@tag=774]">
			<relatedItem type="constituent">
				<xsl:call-template name="relatedItem76X-78X"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=772]|marc:datafield[@tag=773]">
			<relatedItem type="host">
				<xsl:call-template name="relatedItem76X-78X"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=776]">
			<relatedItem type="otherFormat">
				<xsl:call-template name="relatedItem76X-78X"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=780]">
			<relatedItem type="preceding">
				<xsl:call-template name="relatedItem76X-78X"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=785]">
			<relatedItem type="succeeding">
				<xsl:call-template name="relatedItem76X-78X"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=786]">
			<relatedItem type="original">
				<xsl:call-template name="relatedItem76X-78X"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=800]">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklmorsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">g</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"></xsl:call-template>
				</titleInfo>
				<name type="personal">
					<namePart>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">aq</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="beforeCodes">g</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</namePart>
					<xsl:call-template name="termsOfAddress"></xsl:call-template>
					<xsl:call-template name="nameDate"></xsl:call-template>
					<xsl:call-template name="role"></xsl:call-template>
				</name>
				<xsl:call-template name="relatedForm"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=810]">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklmorsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">dg</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="relatedPartNumName"></xsl:call-template>
				</titleInfo>
				<name type="corporate">
					<xsl:for-each select="marc:subfield[@code='a']">
						<namePart>
							<xsl:value-of select="."></xsl:value-of>
						</namePart>
					</xsl:for-each>
					<xsl:for-each select="marc:subfield[@code='b']">
						<namePart>
							<xsl:value-of select="."></xsl:value-of>
						</namePart>
					</xsl:for-each>
					<namePart>
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="anyCodes">c</xsl:with-param>
							<xsl:with-param name="axis">t</xsl:with-param>
							<xsl:with-param name="beforeCodes">dgn</xsl:with-param>
						</xsl:call-template>
					</namePart>
					<xsl:call-template name="role"></xsl:call-template>
				</name>
				<xsl:call-template name="relatedForm"></xsl:call-template>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=811]">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="specialSubfieldSelect">
									<xsl:with-param name="anyCodes">tfklsv</xsl:with-param>
									<xsl:with-param name="axis">t</xsl:with-param>
									<xsl:with-param name="afterCodes">g</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="relatedPartNumName"/>
				</titleInfo>
				<name type="conference">
					<namePart>
						<xsl:call-template name="specialSubfieldSelect">
							<xsl:with-param name="anyCodes">aqdc</xsl:with-param>
							<xsl:with-param name="axis">t</xsl:with-param>
							<xsl:with-param name="beforeCodes">gn</xsl:with-param>
						</xsl:call-template>
					</namePart>
					<xsl:call-template name="role"/>
				</name>
				<xsl:call-template name="relatedForm"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='830']">
			<relatedItem type="series">
				<titleInfo>
					<title>
						<xsl:call-template name="chopPunctuation">
							<xsl:with-param name="chopString">
								<xsl:call-template name="subfieldSelect">
									<xsl:with-param name="codes">adfgklmorsv</xsl:with-param>
								</xsl:call-template>
							</xsl:with-param>
						</xsl:call-template>
					</title>
					<xsl:call-template name="part"/>
				</titleInfo>
				<xsl:call-template name="relatedForm"/>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='856'][@ind2='2']/marc:subfield[@code='q']">
			<relatedItem>
				<internetMediaType>
					<xsl:value-of select="."/>
				</internetMediaType>
			</relatedItem>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='020']">
			<xsl:call-template name="isInvalid">
				<xsl:with-param name="type">isbn</xsl:with-param>
			</xsl:call-template>
			<xsl:if test="marc:subfield[@code='a']">
				<identifier type="isbn">
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='024'][@ind1='0']">
			<xsl:call-template name="isInvalid">
				<xsl:with-param name="type">isrc</xsl:with-param>
			</xsl:call-template>
			<xsl:if test="marc:subfield[@code='a']">
				<identifier type="isrc">
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='024'][@ind1='2']">
			<xsl:call-template name="isInvalid">
				<xsl:with-param name="type">ismn</xsl:with-param>
			</xsl:call-template>
			<xsl:if test="marc:subfield[@code='a']">
				<identifier type="ismn">
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='024'][@ind1='4']">
			<xsl:call-template name="isInvalid">
				<xsl:with-param name="type">sici</xsl:with-param>
			</xsl:call-template>
			<identifier type="sici">
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">ab</xsl:with-param>
				</xsl:call-template>
			</identifier>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='022']">
			<xsl:call-template name="isInvalid">
				<xsl:with-param name="type">issn</xsl:with-param>
			</xsl:call-template>
			<identifier type="issn">
				<xsl:value-of select="marc:subfield[@code='a']"/>
			</identifier>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='010']">
			<xsl:call-template name="isInvalid">
				<xsl:with-param name="type">lccn</xsl:with-param>
			</xsl:call-template>
			<identifier type="lccn">
				<xsl:value-of select="normalize-space(marc:subfield[@code='a'])"/>
			</identifier>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='028']">
			<identifier>
				<xsl:attribute name="type">
					<xsl:choose>
						<xsl:when test="@ind1='0'">issue number</xsl:when>
						<xsl:when test="@ind1='1'">matrix number</xsl:when>
						<xsl:when test="@ind1='2'">music plate</xsl:when>
						<xsl:when test="@ind1='3'">music publisher</xsl:when>
						<xsl:when test="@ind1='4'">videorecording identifier</xsl:when>
					</xsl:choose>
				</xsl:attribute>
				<!--<xsl:call-template name="isInvalid"/>--> <!-- no $z in 028 -->
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">
						<xsl:choose>
							<xsl:when test="@ind1='0'">ba</xsl:when>
							<xsl:otherwise>ab</xsl:otherwise>
						</xsl:choose>
					</xsl:with-param>
				</xsl:call-template>
			</identifier>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='037']">
			<identifier type="stock number">
				<!--<xsl:call-template name="isInvalid"/>--> <!-- no $z in 037 -->
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">ab</xsl:with-param>
				</xsl:call-template>
			</identifier>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag='856'][marc:subfield[@code='u']]">
			<identifier>
				<xsl:attribute name="type">
					<xsl:choose>
						<xsl:when test="starts-with(marc:subfield[@code='u'],'urn:doi') or starts-with(marc:subfield[@code='u'],'doi')">doi</xsl:when>
						<xsl:when test="starts-with(marc:subfield[@code='u'],'urn:hdl') or starts-with(marc:subfield[@code='u'],'hdl') or starts-with(marc:subfield[@code='u'],'http://hdl.loc.gov')">hdl</xsl:when>
						<xsl:otherwise>uri</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:choose>
					<xsl:when test="starts-with(marc:subfield[@code='u'],'urn:hdl') or starts-with(marc:subfield[@code='u'],'hdl') or starts-with(marc:subfield[@code='u'],'http://hdl.loc.gov') ">
						<xsl:value-of select="concat('hdl:',substring-after(marc:subfield[@code='u'],'http://hdl.loc.gov/'))"></xsl:value-of>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="marc:subfield[@code='u']"></xsl:value-of>
					</xsl:otherwise>
				</xsl:choose>
			</identifier>
			<xsl:if test="starts-with(marc:subfield[@code='u'],'urn:hdl') or starts-with(marc:subfield[@code='u'],'hdl')">
				<identifier type="hdl">
					<xsl:if test="marc:subfield[@code='y' or @code='3' or @code='z']">
						<xsl:attribute name="displayLabel">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">y3z</xsl:with-param>
							</xsl:call-template>
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="concat('hdl:',substring-after(marc:subfield[@code='u'],'http://hdl.loc.gov/'))"></xsl:value-of>
				</identifier>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=024][@ind1=1]">
			<identifier type="upc">
				<xsl:call-template name="isInvalid"/>
				<xsl:value-of select="marc:subfield[@code='a']"/>
			</identifier>
		</xsl:for-each>
		<!-- 1/04 fix added $y -->
		<xsl:for-each select="marc:datafield[@tag=856][marc:subfield[@code='u']]">
			<location>
				<url>
					<xsl:if test="marc:subfield[@code='y' or @code='3']">
						<xsl:attribute name="displayLabel">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">y3</xsl:with-param>
							</xsl:call-template>
						</xsl:attribute>
					</xsl:if>
					<xsl:if test="marc:subfield[@code='z' ]">
						<xsl:attribute name="note">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">z</xsl:with-param>
							</xsl:call-template>
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="marc:subfield[@code='u']"></xsl:value-of>

				</url>
			</location>
		</xsl:for-each>
			
			<!-- 3.2 change tmee 856z  -->

		
		<xsl:for-each select="marc:datafield[@tag=852]">
			<location>
				<physicalLocation>
					<xsl:call-template name="displayLabel"></xsl:call-template>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">abje</xsl:with-param>
					</xsl:call-template>
				</physicalLocation>
			</location>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=506]">
			<accessCondition type="restrictionOnAccess">
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">abcd35</xsl:with-param>
				</xsl:call-template>
			</accessCondition>
		</xsl:for-each>
		<xsl:for-each select="marc:datafield[@tag=540]">
			<accessCondition type="useAndReproduction">
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">abcde35</xsl:with-param>
				</xsl:call-template>
			</accessCondition>
		</xsl:for-each>
		<recordInfo>
			<xsl:for-each select="marc:datafield[@tag=040]">
				<recordContentSource authority="marcorg">
					<xsl:value-of select="marc:subfield[@code='a']"></xsl:value-of>
				</recordContentSource>
			</xsl:for-each>
			<xsl:for-each select="marc:controlfield[@tag=008]">
				<recordCreationDate encoding="marc">
					<xsl:value-of select="substring(.,1,6)"></xsl:value-of>
				</recordCreationDate>
			</xsl:for-each>
			<xsl:for-each select="marc:controlfield[@tag=005]">
				<recordChangeDate encoding="iso8601">
					<xsl:value-of select="."></xsl:value-of>
				</recordChangeDate>
			</xsl:for-each>
			<xsl:for-each select="marc:controlfield[@tag=001]">
				<recordIdentifier>
					<xsl:if test="../marc:controlfield[@tag=003]">
						<xsl:attribute name="source">
							<xsl:value-of select="../marc:controlfield[@tag=003]"></xsl:value-of>
						</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="."></xsl:value-of>
				</recordIdentifier>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag=040]/marc:subfield[@code='b']">
				<languageOfCataloging>
					<languageTerm authority="iso639-2b" type="code">
						<xsl:value-of select="."></xsl:value-of>
					</languageTerm>
				</languageOfCataloging>
			</xsl:for-each>
		</recordInfo>
	</xsl:template>
	<xsl:template name="displayForm">
		<xsl:for-each select="marc:subfield[@code='c']">
			<displayForm>
				<xsl:value-of select="."></xsl:value-of>
			</displayForm>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="affiliation">
		<xsl:for-each select="marc:subfield[@code='u']">
			<affiliation>
				<xsl:value-of select="."></xsl:value-of>
			</affiliation>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="uri">
		<xsl:for-each select="marc:subfield[@code='u']">
			<xsl:attribute name="xlink:href">
				<xsl:value-of select="."></xsl:value-of>
			</xsl:attribute>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="role">
		<xsl:for-each select="marc:subfield[@code='e']">
			<role>
				<roleTerm type="text">
					<xsl:value-of select="."></xsl:value-of>
				</roleTerm>
			</role>
		</xsl:for-each>
		<xsl:for-each select="marc:subfield[@code='4']">
			<role>
				<roleTerm authority="marcrelator" type="code">
					<xsl:value-of select="."></xsl:value-of>
				</roleTerm>
			</role>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="part">
		<xsl:variable name="partNumber">
			<xsl:call-template name="specialSubfieldSelect">
				<xsl:with-param name="axis">n</xsl:with-param>
				<xsl:with-param name="anyCodes">n</xsl:with-param>
				<xsl:with-param name="afterCodes">fgkdlmor</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="partName">
			<xsl:call-template name="specialSubfieldSelect">
				<xsl:with-param name="axis">p</xsl:with-param>
				<xsl:with-param name="anyCodes">p</xsl:with-param>
				<xsl:with-param name="afterCodes">fgkdlmor</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="string-length(normalize-space($partNumber))">
			<partNumber>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="$partNumber"></xsl:with-param>
				</xsl:call-template>
			</partNumber>
		</xsl:if>
		<xsl:if test="string-length(normalize-space($partName))">
			<partName>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="$partName"></xsl:with-param>
				</xsl:call-template>
			</partName>
		</xsl:if>
	</xsl:template>
	<xsl:template name="relatedPart">
		<xsl:if test="@tag=773">
			<xsl:for-each select="marc:subfield[@code='g']">
				<part>
					<text>
						<xsl:value-of select="."></xsl:value-of>
					</text>
				</part>
			</xsl:for-each>
			<xsl:for-each select="marc:subfield[@code='q']">
				<part>
					<xsl:call-template name="parsePart"></xsl:call-template>
				</part>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	<xsl:template name="relatedPartNumName">
		<xsl:variable name="partNumber">
			<xsl:call-template name="specialSubfieldSelect">
				<xsl:with-param name="axis">g</xsl:with-param>
				<xsl:with-param name="anyCodes">g</xsl:with-param>
				<xsl:with-param name="afterCodes">pst</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="partName">
			<xsl:call-template name="specialSubfieldSelect">
				<xsl:with-param name="axis">p</xsl:with-param>
				<xsl:with-param name="anyCodes">p</xsl:with-param>
				<xsl:with-param name="afterCodes">fgkdlmor</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="string-length(normalize-space($partNumber))">
			<partNumber>
				<xsl:value-of select="$partNumber"></xsl:value-of>
			</partNumber>
		</xsl:if>
		<xsl:if test="string-length(normalize-space($partName))">
			<partName>
				<xsl:value-of select="$partName"></xsl:value-of>
			</partName>
		</xsl:if>
	</xsl:template>
	<xsl:template name="relatedName">
		<xsl:for-each select="marc:subfield[@code='a']">
			<name>
				<namePart>
					<xsl:value-of select="."></xsl:value-of>
				</namePart>
			</name>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedForm">
		<xsl:for-each select="marc:subfield[@code='h']">
			<physicalDescription>
				<form>
					<xsl:value-of select="."></xsl:value-of>
				</form>
			</physicalDescription>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedExtent">
		<xsl:for-each select="marc:subfield[@code='h']">
			<physicalDescription>
				<extent>
					<xsl:value-of select="."></xsl:value-of>
				</extent>
			</physicalDescription>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedNote">
		<xsl:for-each select="marc:subfield[@code='n']">
			<note>
				<xsl:value-of select="."></xsl:value-of>
			</note>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedSubject">
		<xsl:for-each select="marc:subfield[@code='j']">
			<subject>
				<temporal encoding="iso8601">
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString" select="."></xsl:with-param>
					</xsl:call-template>
				</temporal>
			</subject>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedIdentifierISSN">
		<xsl:for-each select="marc:subfield[@code='x']">
			<identifier type="issn">
				<xsl:value-of select="."></xsl:value-of>
			</identifier>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedIdentifierLocal">
		<xsl:for-each select="marc:subfield[@code='w']">
			<identifier type="local">
				<xsl:value-of select="."></xsl:value-of>
			</identifier>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedIdentifier">
		<xsl:for-each select="marc:subfield[@code='o']">
			<identifier>
				<xsl:value-of select="."></xsl:value-of>
			</identifier>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedItem76X-78X">
		<xsl:call-template name="displayLabel"></xsl:call-template>
		<xsl:call-template name="relatedTitle76X-78X"></xsl:call-template>
		<xsl:call-template name="relatedName"></xsl:call-template>
		<xsl:call-template name="relatedOriginInfo"></xsl:call-template>
		<xsl:call-template name="relatedLanguage"></xsl:call-template>
		<xsl:call-template name="relatedExtent"></xsl:call-template>
		<xsl:call-template name="relatedNote"></xsl:call-template>
		<xsl:call-template name="relatedSubject"></xsl:call-template>
		<xsl:call-template name="relatedIdentifier"></xsl:call-template>
		<xsl:call-template name="relatedIdentifierISSN"></xsl:call-template>
		<xsl:call-template name="relatedIdentifierLocal"></xsl:call-template>
		<xsl:call-template name="relatedPart"></xsl:call-template>
	</xsl:template>
	<xsl:template name="subjectGeographicZ">
		<geographic>
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString" select="."></xsl:with-param>
			</xsl:call-template>
		</geographic>
	</xsl:template>
	<xsl:template name="subjectTemporalY">
		<temporal>
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString" select="."></xsl:with-param>
			</xsl:call-template>
		</temporal>
	</xsl:template>
	<xsl:template name="subjectTopic">
		<topic>
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString" select="."></xsl:with-param>
			</xsl:call-template>
		</topic>
	</xsl:template>	
	<!-- 3.2 change tmee 6xx $v genre -->
	<xsl:template name="subjectGenre">
		<genre>
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString" select="."></xsl:with-param>
			</xsl:call-template>
		</genre>
	</xsl:template>
	
	<xsl:template name="nameABCDN">
		<xsl:for-each select="marc:subfield[@code='a']">
			<namePart>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="."></xsl:with-param>
				</xsl:call-template>
			</namePart>
		</xsl:for-each>
		<xsl:for-each select="marc:subfield[@code='b']">
			<namePart>
				<xsl:value-of select="."></xsl:value-of>
			</namePart>
		</xsl:for-each>
		<xsl:if test="marc:subfield[@code='c'] or marc:subfield[@code='d'] or marc:subfield[@code='n']">
			<namePart>
				<xsl:call-template name="subfieldSelect">
					<xsl:with-param name="codes">cdn</xsl:with-param>
				</xsl:call-template>
			</namePart>
		</xsl:if>
	</xsl:template>
	<xsl:template name="nameABCDQ">
		<namePart>
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString">
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">aq</xsl:with-param>
					</xsl:call-template>
				</xsl:with-param>
				<xsl:with-param name="punctuation">
					<xsl:text>:,;/ </xsl:text>
				</xsl:with-param>
			</xsl:call-template>
		</namePart>
		<xsl:call-template name="termsOfAddress"></xsl:call-template>
		<xsl:call-template name="nameDate"></xsl:call-template>
	</xsl:template>
	<xsl:template name="nameACDEQ">
		<namePart>
			<xsl:call-template name="subfieldSelect">
				<xsl:with-param name="codes">acdeq</xsl:with-param>
			</xsl:call-template>
		</namePart>
	</xsl:template>
	<xsl:template name="constituentOrRelatedType">
		<xsl:if test="@ind2=2">
			<xsl:attribute name="type">constituent</xsl:attribute>
		</xsl:if>
	</xsl:template>
	<xsl:template name="relatedTitle">
		<xsl:for-each select="marc:subfield[@code='t']">
			<titleInfo>
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="."></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</title>
			</titleInfo>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedTitle76X-78X">
		<xsl:for-each select="marc:subfield[@code='t']">
			<titleInfo>
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="."></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:if test="marc:datafield[@tag!=773]and marc:subfield[@code='g']">
					<xsl:call-template name="relatedPartNumName"></xsl:call-template>
				</xsl:if>
			</titleInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:subfield[@code='p']">
			<titleInfo type="abbreviated">
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="."></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:if test="marc:datafield[@tag!=773]and marc:subfield[@code='g']">
					<xsl:call-template name="relatedPartNumName"></xsl:call-template>
				</xsl:if>
			</titleInfo>
		</xsl:for-each>
		<xsl:for-each select="marc:subfield[@code='s']">
			<titleInfo type="uniform">
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:value-of select="."></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</title>
				<xsl:if test="marc:datafield[@tag!=773]and marc:subfield[@code='g']">
					<xsl:call-template name="relatedPartNumName"></xsl:call-template>
				</xsl:if>
			</titleInfo>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="relatedOriginInfo">
		<xsl:if test="marc:subfield[@code='b' or @code='d'] or marc:subfield[@code='f']">
			<originInfo>
				<xsl:if test="@tag=775">
					<xsl:for-each select="marc:subfield[@code='f']">
						<place>
							<placeTerm>
								<xsl:attribute name="type">code</xsl:attribute>
								<xsl:attribute name="authority">marcgac</xsl:attribute>
								<xsl:value-of select="."></xsl:value-of>
							</placeTerm>
						</place>
					</xsl:for-each>
				</xsl:if>
				<xsl:for-each select="marc:subfield[@code='d']">
					<publisher>
						<xsl:value-of select="."></xsl:value-of>
					</publisher>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='b']">
					<edition>
						<xsl:value-of select="."></xsl:value-of>
					</edition>
				</xsl:for-each>
			</originInfo>
		</xsl:if>
	</xsl:template>
	<xsl:template name="relatedLanguage">
		<xsl:for-each select="marc:subfield[@code='e']">
			<xsl:call-template name="getLanguage">
				<xsl:with-param name="langString">
					<xsl:value-of select="."></xsl:value-of>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="nameDate">
		<xsl:for-each select="marc:subfield[@code='d']">
			<namePart type="date">
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="."></xsl:with-param>
				</xsl:call-template>
			</namePart>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="subjectAuthority">
		<xsl:if test="@ind2!=4">
			<xsl:if test="@ind2!=' '">
				<xsl:if test="@ind2!=8">
					<xsl:if test="@ind2!=9">
						<xsl:attribute name="authority">
							<xsl:choose>
								<xsl:when test="@ind2=0">lcsh</xsl:when>
								<xsl:when test="@ind2=1">lcshac</xsl:when>
								<xsl:when test="@ind2=2">mesh</xsl:when>
								<!-- 1/04 fix -->
								<xsl:when test="@ind2=3">nal</xsl:when>
								<xsl:when test="@ind2=5">csh</xsl:when>
								<xsl:when test="@ind2=6">rvm</xsl:when>
								<xsl:when test="@ind2=7">
									<xsl:value-of select="marc:subfield[@code='2']"></xsl:value-of>
								</xsl:when>
							</xsl:choose>
						</xsl:attribute>
					</xsl:if>
				</xsl:if>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template name="subjectAnyOrder">
		<xsl:for-each select="marc:subfield[@code='v' or @code='x' or @code='y' or @code='z']">
			<xsl:choose>
				<xsl:when test="@code='v'">
					<xsl:call-template name="subjectGenre"></xsl:call-template>
				</xsl:when>
				<xsl:when test="@code='x'">
					<xsl:call-template name="subjectTopic"></xsl:call-template>
				</xsl:when>
				<xsl:when test="@code='y'">
					<xsl:call-template name="subjectTemporalY"></xsl:call-template>
				</xsl:when>
				<xsl:when test="@code='z'">
					<xsl:call-template name="subjectGeographicZ"></xsl:call-template>
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="specialSubfieldSelect">
		<xsl:param name="anyCodes"></xsl:param>
		<xsl:param name="axis"></xsl:param>
		<xsl:param name="beforeCodes"></xsl:param>
		<xsl:param name="afterCodes"></xsl:param>
		<xsl:variable name="str">
			<xsl:for-each select="marc:subfield">
				<xsl:if test="contains($anyCodes, @code)      or (contains($beforeCodes,@code) and following-sibling::marc:subfield[@code=$axis])      or (contains($afterCodes,@code) and preceding-sibling::marc:subfield[@code=$axis])">
					<xsl:value-of select="text()"></xsl:value-of>
					<xsl:text> </xsl:text>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring($str,1,string-length($str)-1)"></xsl:value-of>
	</xsl:template>
	
	<!-- 3.2 change tmee 6xx $v genre -->
	<xsl:template match="marc:datafield[@tag=600]">
		<subject>
			<xsl:call-template name="subjectAuthority"></xsl:call-template>
			<name type="personal">
				<xsl:call-template name="termsOfAddress"></xsl:call-template>
				<namePart>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">aq</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
				</namePart>
				<xsl:call-template name="nameDate"></xsl:call-template>
				<xsl:call-template name="affiliation"></xsl:call-template>
				<xsl:call-template name="role"></xsl:call-template>
			</name>
			<xsl:call-template name="subjectAnyOrder"></xsl:call-template>
		</subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag=610]">
		<subject>
			<xsl:call-template name="subjectAuthority"></xsl:call-template>
			<name type="corporate">
				<xsl:for-each select="marc:subfield[@code='a']">
					<namePart>
						<xsl:value-of select="."></xsl:value-of>
					</namePart>
				</xsl:for-each>
				<xsl:for-each select="marc:subfield[@code='b']">
					<namePart>
						<xsl:value-of select="."></xsl:value-of>
					</namePart>
				</xsl:for-each>
				<xsl:if test="marc:subfield[@code='c' or @code='d' or @code='n' or @code='p']">
					<namePart>
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">cdnp</xsl:with-param>
						</xsl:call-template>
					</namePart>
				</xsl:if>
				<xsl:call-template name="role"></xsl:call-template>
			</name>
			<xsl:call-template name="subjectAnyOrder"></xsl:call-template>
		</subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag=611]">
		<subject>
			<xsl:call-template name="subjectAuthority"></xsl:call-template>
			<name type="conference">
				<namePart>
					<xsl:call-template name="subfieldSelect">
						<xsl:with-param name="codes">abcdeqnp</xsl:with-param>
					</xsl:call-template>
				</namePart>
				<xsl:for-each select="marc:subfield[@code='4']">
					<role>
						<roleTerm authority="marcrelator" type="code">
							<xsl:value-of select="."></xsl:value-of>
						</roleTerm>
					</role>
				</xsl:for-each>
			</name>
			<xsl:call-template name="subjectAnyOrder"></xsl:call-template>
		</subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag=630]">
		<subject>
			<xsl:call-template name="subjectAuthority"></xsl:call-template>
			<titleInfo>
				<title>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString">
							<xsl:call-template name="subfieldSelect">
								<xsl:with-param name="codes">adfhklor</xsl:with-param>
							</xsl:call-template>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="part"></xsl:call-template>
				</title>
			</titleInfo>
			<xsl:call-template name="subjectAnyOrder"></xsl:call-template>
		</subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag=650]">
		<subject>
			<xsl:call-template name="subjectAuthority"></xsl:call-template>
			<topic>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">abcd</xsl:with-param>
						</xsl:call-template>
					</xsl:with-param>
				</xsl:call-template>
			</topic>
			<xsl:call-template name="subjectAnyOrder"></xsl:call-template>
		</subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag=651]">
		<subject>
			<xsl:call-template name="subjectAuthority"></xsl:call-template>
			<xsl:for-each select="marc:subfield[@code='a']">
				<geographic>
					<xsl:call-template name="chopPunctuation">
						<xsl:with-param name="chopString" select="."></xsl:with-param>
					</xsl:call-template>
				</geographic>
			</xsl:for-each>
			<xsl:call-template name="subjectAnyOrder"></xsl:call-template>
		</subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag=653]">
		<subject>
			<xsl:for-each select="marc:subfield[@code='a']">
				<topic>
					<xsl:value-of select="."></xsl:value-of>
				</topic>
			</xsl:for-each>
		</subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag=656]">
		<subject>
			<xsl:if test="marc:subfield[@code=2]">
				<xsl:attribute name="authority">
					<xsl:value-of select="marc:subfield[@code=2]"></xsl:value-of>
				</xsl:attribute>
			</xsl:if>
			<occupation>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:value-of select="marc:subfield[@code='a']"></xsl:value-of>
					</xsl:with-param>
				</xsl:call-template>
			</occupation>
		</subject>
	</xsl:template>
	<xsl:template name="termsOfAddress">
		<xsl:if test="marc:subfield[@code='b' or @code='c']">
			<namePart type="termsOfAddress">
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">bc</xsl:with-param>
						</xsl:call-template>
					</xsl:with-param>
				</xsl:call-template>
			</namePart>
		</xsl:if>
	</xsl:template>
	<xsl:template name="displayLabel">
		<xsl:if test="marc:subfield[@code='i']">
			<xsl:attribute name="displayLabel">
				<xsl:value-of select="marc:subfield[@code='i']"></xsl:value-of>
			</xsl:attribute>
		</xsl:if>
		<xsl:if test="marc:subfield[@code='3']">
			<xsl:attribute name="displayLabel">
				<xsl:value-of select="marc:subfield[@code='3']"></xsl:value-of>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>
	<xsl:template name="isInvalid">
		<xsl:param name="type"/>
		<xsl:if test="marc:subfield[@code='z'] or marc:subfield[@code='y']">
			<identifier>
				<xsl:attribute name="type">
					<xsl:value-of select="$type"/>
				</xsl:attribute>
				<xsl:attribute name="invalid">
					<xsl:text>yes</xsl:text>
				</xsl:attribute>
				<xsl:if test="marc:subfield[@code='z']">
					<xsl:value-of select="marc:subfield[@code='z']"/>
				</xsl:if>
				<xsl:if test="marc:subfield[@code='y']">
					<xsl:value-of select="marc:subfield[@code='y']"/>
				</xsl:if>
			</identifier>
		</xsl:if>
	</xsl:template>
	<xsl:template name="subtitle">
		<xsl:if test="marc:subfield[@code='b']">
			<subTitle>
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString">
						<xsl:value-of select="marc:subfield[@code='b']"/>
						<!--<xsl:call-template name="subfieldSelect">
							<xsl:with-param name="codes">b</xsl:with-param>									
						</xsl:call-template>-->
					</xsl:with-param>
				</xsl:call-template>
			</subTitle>
		</xsl:if>
	</xsl:template>
	<xsl:template name="script">
		<xsl:param name="scriptCode"></xsl:param>
		<xsl:attribute name="script">
			<xsl:choose>
				<xsl:when test="$scriptCode='(3'">Arabic</xsl:when>
				<xsl:when test="$scriptCode='(B'">Latin</xsl:when>
				<xsl:when test="$scriptCode='$1'">Chinese, Japanese, Korean</xsl:when>
				<xsl:when test="$scriptCode='(N'">Cyrillic</xsl:when>
				<xsl:when test="$scriptCode='(2'">Hebrew</xsl:when>
				<xsl:when test="$scriptCode='(S'">Greek</xsl:when>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>
	<xsl:template name="parsePart">
		<!-- assumes 773$q= 1:2:3<4
		     with up to 3 levels and one optional start page
		-->
		<xsl:variable name="level1">
			<xsl:choose>
				<xsl:when test="contains(text(),':')">
					<!-- 1:2 -->
					<xsl:value-of select="substring-before(text(),':')"></xsl:value-of>
				</xsl:when>
				<xsl:when test="not(contains(text(),':'))">
					<!-- 1 or 1<3 -->
					<xsl:if test="contains(text(),'&lt;')">
						<!-- 1<3 -->
						<xsl:value-of select="substring-before(text(),'&lt;')"></xsl:value-of>
					</xsl:if>
					<xsl:if test="not(contains(text(),'&lt;'))">
						<!-- 1 -->
						<xsl:value-of select="text()"></xsl:value-of>
					</xsl:if>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="sici2">
			<xsl:choose>
				<xsl:when test="starts-with(substring-after(text(),$level1),':')">
					<xsl:value-of select="substring(substring-after(text(),$level1),2)"></xsl:value-of>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-after(text(),$level1)"></xsl:value-of>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="level2">
			<xsl:choose>
				<xsl:when test="contains($sici2,':')">
					<!--  2:3<4  -->
					<xsl:value-of select="substring-before($sici2,':')"></xsl:value-of>
				</xsl:when>
				<xsl:when test="contains($sici2,'&lt;')">
					<!-- 1: 2<4 -->
					<xsl:value-of select="substring-before($sici2,'&lt;')"></xsl:value-of>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$sici2"></xsl:value-of>
					<!-- 1:2 -->
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="sici3">
			<xsl:choose>
				<xsl:when test="starts-with(substring-after($sici2,$level2),':')">
					<xsl:value-of select="substring(substring-after($sici2,$level2),2)"></xsl:value-of>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-after($sici2,$level2)"></xsl:value-of>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="level3">
			<xsl:choose>
				<xsl:when test="contains($sici3,'&lt;')">
					<!-- 2<4 -->
					<xsl:value-of select="substring-before($sici3,'&lt;')"></xsl:value-of>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$sici3"></xsl:value-of>
					<!-- 3 -->
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="page">
			<xsl:if test="contains(text(),'&lt;')">
				<xsl:value-of select="substring-after(text(),'&lt;')"></xsl:value-of>
			</xsl:if>
		</xsl:variable>
		<xsl:if test="$level1">
			<detail level="1">
				<number>
					<xsl:value-of select="$level1"></xsl:value-of>
				</number>
			</detail>
		</xsl:if>
		<xsl:if test="$level2">
			<detail level="2">
				<number>
					<xsl:value-of select="$level2"></xsl:value-of>
				</number>
			</detail>
		</xsl:if>
		<xsl:if test="$level3">
			<detail level="3">
				<number>
					<xsl:value-of select="$level3"></xsl:value-of>
				</number>
			</detail>
		</xsl:if>
		<xsl:if test="$page">
			<extent unit="page">
				<start>
					<xsl:value-of select="$page"></xsl:value-of>
				</start>
			</extent>
		</xsl:if>
	</xsl:template>
	<xsl:template name="getLanguage">
		<xsl:param name="langString"></xsl:param>
		<xsl:param name="controlField008-35-37"></xsl:param>
		<xsl:variable name="length" select="string-length($langString)"></xsl:variable>
		<xsl:choose>
			<xsl:when test="$length=0"></xsl:when>
			<xsl:when test="$controlField008-35-37=substring($langString,1,3)">
				<xsl:call-template name="getLanguage">
					<xsl:with-param name="langString" select="substring($langString,4,$length)"></xsl:with-param>
					<xsl:with-param name="controlField008-35-37" select="$controlField008-35-37"></xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<language>
					<languageTerm authority="iso639-2b" type="code">
						<xsl:value-of select="substring($langString,1,3)"></xsl:value-of>
					</languageTerm>
				</language>
				<xsl:call-template name="getLanguage">
					<xsl:with-param name="langString" select="substring($langString,4,$length)"></xsl:with-param>
					<xsl:with-param name="controlField008-35-37" select="$controlField008-35-37"></xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="isoLanguage">
		<xsl:param name="currentLanguage"></xsl:param>
		<xsl:param name="usedLanguages"></xsl:param>
		<xsl:param name="remainingLanguages"></xsl:param>
		<xsl:choose>
			<xsl:when test="string-length($currentLanguage)=0"></xsl:when>
			<xsl:when test="not(contains($usedLanguages, $currentLanguage))">
				<language>
					<xsl:if test="@code!='a'">
						<xsl:attribute name="objectPart">
							<xsl:choose>
								<xsl:when test="@code='b'">summary or subtitle</xsl:when>
								<xsl:when test="@code='d'">sung or spoken text</xsl:when>
								<xsl:when test="@code='e'">libretto</xsl:when>
								<xsl:when test="@code='f'">table of contents</xsl:when>
								<xsl:when test="@code='g'">accompanying material</xsl:when>
								<xsl:when test="@code='h'">translation</xsl:when>
							</xsl:choose>
						</xsl:attribute>
					</xsl:if>
					<languageTerm authority="iso639-2b" type="code">
						<xsl:value-of select="$currentLanguage"></xsl:value-of>
					</languageTerm>
				</language>
				<xsl:call-template name="isoLanguage">
					<xsl:with-param name="currentLanguage">
						<xsl:value-of select="substring($remainingLanguages,1,3)"></xsl:value-of>
					</xsl:with-param>
					<xsl:with-param name="usedLanguages">
						<xsl:value-of select="concat($usedLanguages,$currentLanguage)"></xsl:value-of>
					</xsl:with-param>
					<xsl:with-param name="remainingLanguages">
						<xsl:value-of select="substring($remainingLanguages,4,string-length($remainingLanguages))"></xsl:value-of>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="isoLanguage">
					<xsl:with-param name="currentLanguage">
						<xsl:value-of select="substring($remainingLanguages,1,3)"></xsl:value-of>
					</xsl:with-param>
					<xsl:with-param name="usedLanguages">
						<xsl:value-of select="concat($usedLanguages,$currentLanguage)"></xsl:value-of>
					</xsl:with-param>
					<xsl:with-param name="remainingLanguages">
						<xsl:value-of select="substring($remainingLanguages,4,string-length($remainingLanguages))"></xsl:value-of>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="chopBrackets">
		<xsl:param name="chopString"></xsl:param>
		<xsl:variable name="string">
			<xsl:call-template name="chopPunctuation">
				<xsl:with-param name="chopString" select="$chopString"></xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="substring($string, 1,1)='['">
			<xsl:value-of select="substring($string,2, string-length($string)-2)"></xsl:value-of>
		</xsl:if>
		<xsl:if test="substring($string, 1,1)!='['">
			<xsl:value-of select="$string"></xsl:value-of>
		</xsl:if>
	</xsl:template>
	<xsl:template name="rfcLanguages">
		<xsl:param name="nodeNum"></xsl:param>
		<xsl:param name="usedLanguages"></xsl:param>
		<xsl:param name="controlField008-35-37"></xsl:param>
		<xsl:variable name="currentLanguage" select="."></xsl:variable>
		<xsl:choose>
			<xsl:when test="not($currentLanguage)"></xsl:when>
			<xsl:when test="$currentLanguage!=$controlField008-35-37 and $currentLanguage!='rfc3066'">
				<xsl:if test="not(contains($usedLanguages,$currentLanguage))">
					<language>
						<xsl:if test="@code!='a'">
							<xsl:attribute name="objectPart">
								<xsl:choose>
									<xsl:when test="@code='b'">summary or subtitle</xsl:when>
									<xsl:when test="@code='d'">sung or spoken text</xsl:when>
									<xsl:when test="@code='e'">libretto</xsl:when>
									<xsl:when test="@code='f'">table of contents</xsl:when>
									<xsl:when test="@code='g'">accompanying material</xsl:when>
									<xsl:when test="@code='h'">translation</xsl:when>
								</xsl:choose>
							</xsl:attribute>
						</xsl:if>
						<languageTerm authority="rfc3066" type="code">
							<xsl:value-of select="$currentLanguage"/>
						</languageTerm>
					</language>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="datafield">
		<xsl:param name="tag"/>
		<xsl:param name="ind1"><xsl:text> </xsl:text></xsl:param>
		<xsl:param name="ind2"><xsl:text> </xsl:text></xsl:param>
		<xsl:param name="subfields"/>
		<xsl:element name="marc:datafield">
			<xsl:attribute name="tag">
				<xsl:value-of select="$tag"/>
			</xsl:attribute>
			<xsl:attribute name="ind1">
				<xsl:value-of select="$ind1"/>
			</xsl:attribute>
			<xsl:attribute name="ind2">
				<xsl:value-of select="$ind2"/>
			</xsl:attribute>
			<xsl:copy-of select="$subfields"/>
		</xsl:element>
	</xsl:template>

	<xsl:template name="subfieldSelect">
		<xsl:param name="codes"/>
		<xsl:param name="delimeter"><xsl:text> </xsl:text></xsl:param>
		<xsl:variable name="str">
			<xsl:for-each select="marc:subfield">
				<xsl:if test="contains($codes, @code)">
					<xsl:value-of select="text()"/><xsl:value-of select="$delimeter"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring($str,1,string-length($str)-string-length($delimeter))"/>
	</xsl:template>

	<xsl:template name="buildSpaces">
		<xsl:param name="spaces"/>
		<xsl:param name="char"><xsl:text> </xsl:text></xsl:param>
		<xsl:if test="$spaces>0">
			<xsl:value-of select="$char"/>
			<xsl:call-template name="buildSpaces">
				<xsl:with-param name="spaces" select="$spaces - 1"/>
				<xsl:with-param name="char" select="$char"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="chopPunctuation">
		<xsl:param name="chopString"/>
		<xsl:param name="punctuation"><xsl:text>.:,;/ </xsl:text></xsl:param>
		<xsl:variable name="length" select="string-length($chopString)"/>
		<xsl:choose>
			<xsl:when test="$length=0"/>
			<xsl:when test="contains($punctuation, substring($chopString,$length,1))">
				<xsl:call-template name="chopPunctuation">
					<xsl:with-param name="chopString" select="substring($chopString,1,$length - 1)"/>
					<xsl:with-param name="punctuation" select="$punctuation"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="not($chopString)"/>
			<xsl:otherwise><xsl:value-of select="$chopString"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="chopPunctuationFront">
		<xsl:param name="chopString"/>
		<xsl:variable name="length" select="string-length($chopString)"/>
		<xsl:choose>
			<xsl:when test="$length=0"/>
			<xsl:when test="contains('.:,;/[ ', substring($chopString,1,1))">
				<xsl:call-template name="chopPunctuationFront">
					<xsl:with-param name="chopString" select="substring($chopString,2,$length - 1)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="not($chopString)"/>
			<xsl:otherwise><xsl:value-of select="$chopString"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>$$ WHERE name = 'mods32';

--INSERT into config.org_unit_setting_type 
--    (name, grp, label, description, datatype) 
--    VALUES ( 
--        'opac.search.tag_circulated_items', 
--        'opac',
--        oils_i18n_gettext(
--            'opac.search.tag_circulated_items',
--            'Tag Circulated Items in Results',
--            'coust', 
--            'label'
--        ),
--        oils_i18n_gettext(
--            'opac.search.tag_circulated_items',
--            'When a user is both logged in and has opted in to circulation history tracking, turning on this setting will cause previous (or currently) circulated items to be highlighted in search results',
--            'coust', 
--            'description'
--        ),
--        'bool'
--    );

--Converted to update, record already existed
UPDATE config.org_unit_setting_type SET grp =  'opac',
description = oils_i18n_gettext(
            'opac.search.tag_circulated_items',
            'When a user is both logged in and has opted in to circulation history tracking, turning on this setting will cause previous (or currently) circulated items to be highlighted in search results',
            'coust', 
            'description'
        )
WHERE name = 'opac.search.tag_circulated_items';