-- Permission Schema Inits

-- TODO: make sure that the ids are valid.  Might be best to change to auto-increment

INSERT INTO permission.perm_list VALUES
 (507, 'ABORT_TRANSIT_ON_LOST', oils_i18n_gettext(507, 'Allows a user to abort a transit on a copy with status of LOST', 'ppl', 'description')),
 (508, 'ABORT_TRANSIT_ON_MISSING', oils_i18n_gettext(508, 'Allows a user to abort a transit on a copy with status of MISSING', 'ppl', 'description'));

--- stock Circulation Administrator group

INSERT INTO permission.grp_perm_map ( grp, perm, depth, grantable )
    SELECT
        4,
        id,
        0,
        't'
    FROM permission.perm_list
    WHERE code in ('ABORT_TRANSIT_ON_LOST', 'ABORT_TRANSIT_ON_MISSING');

DELETE FROM permission.grp_perm_map WHERE grp = 4 AND perm IN (
	SELECT id FROM permission.perm_list
	WHERE code in ('ABORT_TRANSIT_ON_LOST', 'ABORT_TRANSIT_ON_MISSING')
);

INSERT INTO permission.grp_perm_map (grp, perm, depth, grantable)
	SELECT
		pgt.id, perm.id, aout.depth, TRUE
	FROM
		permission.grp_tree pgt,
		permission.perm_list perm,
		actor.org_unit_type aout
	WHERE
		pgt.name = 'Circulation Administrator' AND
		aout.name = 'Consortium' AND
		perm.code IN (
			'ABORT_TRANSIT_ON_LOST',
			'ABORT_TRANSIT_ON_MISSING'
		) AND NOT EXISTS (
			SELECT 1
			FROM permission.grp_perm_map AS map
			WHERE
				map.grp = pgt.id
				AND map.perm = perm.id
		);

INSERT INTO permission.perm_list ( id, code, description ) VALUES (  
    509, 
    'TRANSIT_CHECKIN_INTERVAL_BLOCK.override', 
    oils_i18n_gettext(
        509,
        'Allows a user to override the TRANSIT_CHECKIN_INTERVAL_BLOCK event', 
        'ppl', 
        'description'
    )
);

--INSERT INTO permission.perm_list (id, code, description) VALUES (
--    511,
--    'PERSISTENT_LOGIN',
--    oils_i18n_gettext(
--        511,
--        'Allows a user to authenticate and get a long-lived session (length configured in opensrf.xml)',
--        'ppl',
--        'description'
--    )
--);
--CHANGED to update, id already exists
UPDATE permission.perm_list SET description = oils_i18n_gettext(
	(select id from permission.perm_list where code = 'PERSISTENT_LOGIN')
	,
        'Allows a user to authenticate and get a long-lived session (length configured in opensrf.xml)',
        'ppl',
        'description'
    )
	where code = 'PERSISTENT_LOGIN';
	
-- add the perm to the default circ admin group
INSERT INTO permission.grp_perm_map (grp, perm, depth, grantable)
	SELECT
		pgt.id, perm.id, aout.depth, TRUE
	FROM
		permission.grp_tree pgt,
		permission.perm_list perm,
		actor.org_unit_type aout
	WHERE
		pgt.name = 'Circulation Administrator' AND
		aout.name = 'System' AND
		perm.code IN ( 'TRANSIT_CHECKIN_INTERVAL_BLOCK.override' );

UPDATE permission.perm_list SET  
    code = 'PERSISTENT_LOGIN',
    description = oils_i18n_gettext( 
    	(SELECT id FROM permission.perm_list WHERE code = 'PERSISTENT_LOGIN'),
        'Allows a user to authenticate and get a long-lived session (length configured in opensrf.xml)',
        'ppl',
        'description'
    )
WHERE code = 'PERSISTENT_LOGIN';


INSERT INTO permission.grp_perm_map (grp, perm, depth, grantable)
    SELECT
        pgt.id, perm.id, aout.depth, FALSE
    FROM
        permission.grp_tree pgt,
        permission.perm_list perm,
        actor.org_unit_type aout
    WHERE
        pgt.name = 'Users' AND
        aout.name = 'Consortium' AND
        perm.code = 'PERSISTENT_LOGIN';

INSERT INTO permission.perm_list ( id, code, description ) VALUES
 ( 514, 'UPDATE_PATRON_ACTIVE_CARD', oils_i18n_gettext( 514,
    'Allows a user to manually adjust a patron''s active cards', 'ppl', 'description')),
 ( 515, 'UPDATE_PATRON_PRIMARY_CARD', oils_i18n_gettext( 515,
    'Allows a user to manually adjust a patron''s primary card', 'ppl', 'description'));

INSERT INTO permission.perm_list ( id, code, description ) VALUES
 ( 516, 'CREATE_REPORT_TEMPLATE', oils_i18n_gettext( 516,
    'Allows a user to create report templates', 'ppl', 'description' ));

INSERT INTO permission.grp_perm_map (grp, perm, depth, grantable)
    SELECT grp, 516, depth, grantable
        FROM permission.grp_perm_map
        WHERE perm = (
            SELECT id
                FROM permission.perm_list
                WHERE code = 'RUN_REPORTS'
        );

INSERT INTO permission.perm_list ( id, code, description ) VALUES
    (
        519,
        'ADMIN_SMS_CARRIER',
        oils_i18n_gettext(
            519,
            'Allows a user to add/create/delete SMS Carrier entries.',
            'ppl',
            'description'
        )
    )
;

INSERT INTO permission.grp_perm_map (grp, perm, depth, grantable)
    SELECT
        pgt.id, perm.id, aout.depth, TRUE
    FROM
        permission.grp_tree pgt,
        permission.perm_list perm,
        actor.org_unit_type aout
    WHERE
        pgt.name = 'Global Administrator' AND
        aout.name = 'Consortium' AND
        perm.code = 'ADMIN_SMS_CARRIER';

INSERT INTO action_trigger.reactor (
    module,
    description
) VALUES (
    'SendSMS',
    'Send an SMS text message based on a user-defined template'
);

INSERT INTO permission.perm_list ( id, code, description ) VALUES
 ( 517, 'COPY_HOLDS_FORCE', oils_i18n_gettext( 517, 
    'Allow a user to place a force hold on a specific copy', 'ppl', 'description' )),
 ( 518, 'COPY_HOLDS_RECALL', oils_i18n_gettext( 518, 
    'Allow a user to place a cataloging recall on a specific copy', 'ppl', 'description' ));

INSERT INTO permission.perm_list (id, code, description) VALUES (
    520,
    'COPY_DELETE_WARNING.override',
    'Allow a user to override warnings about deleting copies in problematic situations.'
);

INSERT INTO permission.perm_list ( id, code, description ) 
    VALUES ( 
        521, 
        'IMPORT_ACQ_LINEITEM_BIB_RECORD_UPLOAD', 
        oils_i18n_gettext( 
            521,
            'Allows a user to create new bibs directly from an ACQ MARC file upload', 
            'ppl', 
            'description' 
        )
    );

INSERT INTO permission.perm_list ( id, code, description ) VALUES (
    523,
    'ADMIN_TOOLBAR',
    oils_i18n_gettext(
        523,
        'Allows a user to create, edit, and delete custom toolbars',
        'ppl',
        'description'
    )
);

INSERT INTO permission.perm_list ( id, code, description ) VALUES
 ( 524, 'PLACE_UNFILLABLE_HOLD', oils_i18n_gettext( 524,
    'Allows a user to place a hold that cannot currently be filled.', 'ppl', 'description' ));

-- Add permissions
INSERT INTO permission.perm_list ( id, code, description ) VALUES
    ( 525, 'CREATE_PATRON_STAT_CAT_ENTRY_DEFAULT', oils_i18n_gettext( 525, 
        'User may set a default entry in a patron statistical category', 'ppl', 'description' )),
    ( 526, 'UPDATE_PATRON_STAT_CAT_ENTRY_DEFAULT', oils_i18n_gettext( 526, 
        'User may reset a default entry in a patron statistical category', 'ppl', 'description' )),
    ( 527, 'DELETE_PATRON_STAT_CAT_ENTRY_DEFAULT', oils_i18n_gettext( 527, 
        'User may unset a default entry in a patron statistical category', 'ppl', 'description' ));

INSERT INTO permission.grp_perm_map (grp, perm, depth, grantable)
    SELECT
        pgt.id, perm.id, aout.depth, TRUE
    FROM
        permission.grp_tree pgt,
        permission.perm_list perm,
        actor.org_unit_type aout
    WHERE
        pgt.name = 'Circulation Administrator' AND
        aout.name = 'System' AND
        perm.code IN ('CREATE_PATRON_STAT_CAT_ENTRY_DEFAULT', 'DELETE_PATRON_STAT_CAT_ENTRY_DEFAULT');

INSERT INTO permission.perm_list (id, code, description)
    VALUES (
        528,
        'ADMIN_ORG_UNIT_CUSTOM_TREE',
        oils_i18n_gettext(
            528,
            'User may update custom org unit trees',
            'ppl',
            'description'
        )
    );

INSERT INTO permission.perm_list ( id, code, description )
    VALUES (
        529,
        'ADMIN_IMPORT_MATCH_SET',
        oils_i18n_gettext(
            529,
            'Allows a user to create/retrieve/update/delete vandelay match sets',
            'ppl',
            'description'
        )
    ), (
        530,
        'VIEW_IMPORT_MATCH_SET',
        oils_i18n_gettext(
            530,
            'Allows a user to view vandelay match sets',
            'ppl',
            'description'
        )
    );

INSERT INTO permission.perm_list ( id, code, description ) 
    VALUES ( 
        531, 
        'ADMIN_ADDRESS_ALERT',
        oils_i18n_gettext( 
            531,
            'Allows a user to create/retrieve/update/delete address alerts',
            'ppl', 
            'description' 
        )
    ), ( 
        532, 
        'VIEW_ADDRESS_ALERT',
        oils_i18n_gettext( 
            532,
            'Allows a user to view address alerts',
            'ppl', 
            'description' 
        )
    ), ( 
        533, 
        'ADMIN_COPY_LOCATION_GROUP',
        oils_i18n_gettext( 
            533,
            'Allows a user to create/retrieve/update/delete copy location groups',
            'ppl', 
            'description' 
        )
    ), ( 
        534, 
        'ADMIN_USER_ACTIVITY_TYPE',
        oils_i18n_gettext( 
            534,
            'Allows a user to create/retrieve/update/delete user activity types',
            'ppl', 
            'description' 
        )
    );

-- this one unrelated to toolbars but is a gap in the upgrade scripts
INSERT INTO permission.perm_list ( id, code, description )
    SELECT
        522,
        'IMPORT_AUTHORITY_MARC',
        oils_i18n_gettext(
            522,
            'Allows a user to create new authority records',
            'ppl',
            'description'
        )
    WHERE NOT EXISTS (
        SELECT 1
        FROM permission.perm_list
        WHERE
            id = 522
    );

