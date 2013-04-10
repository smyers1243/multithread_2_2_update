INSERT INTO action_trigger.hook (key,core_type,description,passive) VALUES (
        'vandelay.import_items.csv',
        'vii', 
        oils_i18n_gettext(
            'vandelay.import_items.csv',
            'CSV output has been requested for Import Items from records in an Importer Bib Queue.',
            'ath',
            'description'
        ), 
        FALSE
    );
	
INSERT INTO action_trigger.event_definition (
        active,
        owner,
        name,
        hook,
        validator,
        reactor,
        group_field,
        granularity,
        template
    ) VALUES (
        TRUE,
        1,
        'CSV Output for Import Items from Queued Bib Records',
        'vandelay.import_items.csv',
        'NOOP_True',
        'ProcessTemplate',
        'record.queue.owner',
        'print-on-demand',
$$
[%- USE date -%]
"Import Item ID","Title of work","ISBN","Attribute Definition","Import Error","Import Error Detail","Owning Library","Circulating Library","Call Number","Copy Number","Status","Shelving Location","Circulate","Deposit","Deposit Amount","Reference","Holdable","Price","Barcode","Circulation Modifier","Circulate As MARC Type","Alert Message","Public Note","Private Note","OPAC Visible"
[% FOR vii IN target %]"[% vii.id | replace('"', '""') %]","[% helpers.get_queued_bib_attr('title',vii.record.attributes) | replace('"', '""') %]","[% helpers.get_queued_bib_attr('isbn',vii.record.attributes) | replace('"', '""') %]","[% vii.definition | replace('"', '""') %]","[% vii.import_error | replace('"', '""') %]","[% vii.error_detail | replace('"', '""') %]","[% vii.owning_lib | replace('"', '""') %]","[% vii.circ_lib | replace('"', '""') %]","[% vii.call_number | replace('"', '""') %]","[% vii.copy_number | replace('"', '""') %]","[% vii.status.name | replace('"', '""') %]","[% vii.location.name | replace('"', '""') %]","[% vii.circulate | replace('"', '""') %]","[% vii.deposit | replace('"', '""') %]","[% vii.deposit_amount | replace('"', '""') %]","[% vii.ref | replace('"', '""') %]","[% vii.holdable | replace('"', '""') %]","[% vii.price | replace('"', '""') %]","[% vii.barcode | replace('"', '""') %]","[% vii.circ_modifier | replace('"', '""') %]","[% vii.circ_as_type | replace('"', '""') %]","[% vii.alert_message | replace('"', '""') %]","[% vii.pub_note | replace('"', '""') %]","[% vii.priv_note | replace('"', '""') %]","[% vii.opac_visible | replace('"', '""') %]"
[% END %]
$$
    )
;

INSERT INTO action_trigger.environment ( event_def, path) VALUES (
    (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'CSV Output for Import Items from Queued Bib Records' AND
hook = 'vandelay.import_items.csv' AND
validator = 'NOOP_True' AND
reactor = 'ProcessTemplate' AND
group_field = 'record.queue.owner' AND
granularity = 'print-on-demand'	
), 'record')
    ,( (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'CSV Output for Import Items from Queued Bib Records' AND
hook = 'vandelay.import_items.csv' AND
validator = 'NOOP_True' AND
reactor = 'ProcessTemplate' AND
group_field = 'record.queue.owner' AND
granularity = 'print-on-demand'	
), 'record.attributes')
    ,( (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'CSV Output for Import Items from Queued Bib Records' AND
hook = 'vandelay.import_items.csv' AND
validator = 'NOOP_True' AND
reactor = 'ProcessTemplate' AND
group_field = 'record.queue.owner' AND
granularity = 'print-on-demand'	
), 'record.queue')
    ,( (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'CSV Output for Import Items from Queued Bib Records' AND
hook = 'vandelay.import_items.csv' AND
validator = 'NOOP_True' AND
reactor = 'ProcessTemplate' AND
group_field = 'record.queue.owner' AND
granularity = 'print-on-demand'	
), 'record.queue.owner')
;

