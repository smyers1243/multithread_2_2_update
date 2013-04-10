INSERT INTO action_trigger.hook (key,core_type,description,passive) VALUES (
        'vandelay.import_items.print',
        'vii', 
        oils_i18n_gettext(
            'vandelay.import_items.print',
            'Print output has been requested for Import Items from records in an Importer Bib Queue.',
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
        'Print Output for Import Items from Queued Bib Records',
        'vandelay.import_items.print',
        'NOOP_True',
        'ProcessTemplate',
        'record.queue.owner',
        'print-on-demand',
$$
[%- USE date -%]
<pre>
Queue ID: [% target.0.record.queue.id %]
Queue Name: [% target.0.record.queue.name %]
Queue Type: [% target.0.record.queue.queue_type %]
Complete? [% target.0.record.queue.complete %]

    [% FOR vii IN target %]
=-=-=
 Import Item ID         | [% vii.id %]
 Title of work          | [% helpers.get_queued_bib_attr('title',vii.record.attributes) %]
 ISBN                   | [% helpers.get_queued_bib_attr('isbn',vii.record.attributes) %]
 Attribute Definition   | [% vii.definition %]
 Import Error           | [% vii.import_error %]
 Import Error Detail    | [% vii.error_detail %]
 Owning Library         | [% vii.owning_lib %]
 Circulating Library    | [% vii.circ_lib %]
 Call Number            | [% vii.call_number %]
 Copy Number            | [% vii.copy_number %]
 Status                 | [% vii.status.name %]
 Shelving Location      | [% vii.location.name %]
 Circulate              | [% vii.circulate %]
 Deposit                | [% vii.deposit %]
 Deposit Amount         | [% vii.deposit_amount %]
 Reference              | [% vii.ref %]
 Holdable               | [% vii.holdable %]
 Price                  | [% vii.price %]
 Barcode                | [% vii.barcode %]
 Circulation Modifier   | [% vii.circ_modifier %]
 Circulate As MARC Type | [% vii.circ_as_type %]
 Alert Message          | [% vii.alert_message %]
 Public Note            | [% vii.pub_note %]
 Private Note           | [% vii.priv_note %]
 OPAC Visible           | [% vii.opac_visible %]

    [% END %]
</pre>
$$
    )
;

INSERT INTO action_trigger.environment ( event_def, path) VALUES (
    (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'Print Output for Import Items from Queued Bib Records' AND
hook = 'vandelay.import_items.print' AND
validator = 'NOOP_True' AND
reactor = 'ProcessTemplate' AND
group_field = 'record.queue.owner' AND
granularity = 'print-on-demand'	
), 'record')
    ,( (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'Print Output for Import Items from Queued Bib Records' AND
hook = 'vandelay.import_items.print' AND
validator = 'NOOP_True' AND
reactor = 'ProcessTemplate' AND
group_field = 'record.queue.owner' AND
granularity = 'print-on-demand'	
), 'record.attributes')
    ,( (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'Print Output for Import Items from Queued Bib Records' AND
hook = 'vandelay.import_items.print' AND
validator = 'NOOP_True' AND
reactor = 'ProcessTemplate' AND
group_field = 'record.queue.owner' AND
granularity = 'print-on-demand'	
), 'record.queue')
    ,( (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'Print Output for Import Items from Queued Bib Records' AND
hook = 'vandelay.import_items.print' AND
validator = 'NOOP_True' AND
reactor = 'ProcessTemplate' AND
group_field = 'record.queue.owner' AND
granularity = 'print-on-demand'	
), 'record.queue.owner')
;

