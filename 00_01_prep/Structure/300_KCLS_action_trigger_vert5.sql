INSERT INTO action_trigger.hook (key,core_type,description,passive) VALUES (
        'vandelay.queued_auth_record.print',
        'vqar', 
        oils_i18n_gettext(
            'vandelay.queued_auth_record.print',
            'Print output has been requested for records in an Importer Authority Queue.',
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
        'Print Output for Queued Authority Records',
        'vandelay.queued_auth_record.print',
        'NOOP_True',
        'ProcessTemplate',
        'queue.owner',
        'print-on-demand',
$$
[%- USE date -%]
<pre>
Queue ID: [% target.0.queue.id %]
Queue Name: [% target.0.queue.name %]
Queue Type: [% target.0.queue.queue_type %]
Complete? [% target.0.queue.complete %]

    [% FOR vqar IN target %]
=-=-=
 Record Identifier | [% helpers.get_queued_auth_attr('rec_identifier',vqar.attributes) %]

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
name = 'Print Output for Queued Authority Records' AND
hook = 'vandelay.queued_auth_record.print' AND
validator = 'NOOP_True' AND
reactor = 'ProcessTemplate' AND
group_field = 'queue.owner' AND
granularity = 'print-on-demand'	
), 'attributes')
    ,( (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'Print Output for Queued Authority Records' AND
hook = 'vandelay.queued_auth_record.print' AND
validator = 'NOOP_True' AND
reactor = 'ProcessTemplate' AND
group_field = 'queue.owner' AND
granularity = 'print-on-demand'	
), 'queue')
;
