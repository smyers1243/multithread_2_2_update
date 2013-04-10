INSERT INTO action_trigger.hook (key,core_type,description,passive) VALUES (
        'vandelay.queued_auth_record.email',
        'vqar', 
        oils_i18n_gettext(
            'vandelay.queued_auth_record.email',
            'An email has been requested for records in an Importer Authority Queue.',
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
        'Email Output for Queued Authority Records',
        'vandelay.queued_auth_record.email',
        'NOOP_True',
        'SendEmail',
        'queue.owner',
        NULL,
$$
[%- USE date -%]
[%- SET user = target.0.queue.owner -%]
To: [%- params.recipient_email || user.email || 'root@localhost' %]
From: [%- params.sender_email || default_sender %]
Subject: Authorities from Import Queue

Queue ID: [% target.0.queue.id %]
Queue Name: [% target.0.queue.name %]
Queue Type: [% target.0.queue.queue_type %]
Complete? [% target.0.queue.complete %]

    [% FOR vqar IN target %]
=-=-=
 Record Identifier | [% helpers.get_queued_auth_attr('rec_identifier',vqar.attributes) %]

    [% END %]

$$
    )
;

INSERT INTO action_trigger.environment ( event_def, path) VALUES (
    (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'Email Output for Queued Authority Records' AND
hook = 'vandelay.queued_auth_record.email' AND
validator = 'NOOP_True' AND
reactor = 'SendEmail' AND
group_field = 'queue.owner' --AND
--granularity = NULL	
), 'attributes')
    ,( (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'Email Output for Queued Authority Records' AND
hook = 'vandelay.queued_auth_record.email' AND
validator = 'NOOP_True' AND
reactor = 'SendEmail' AND
group_field = 'queue.owner' --AND
--granularity = NULL	
), 'queue')
    ,( (
select id from action_trigger.event_definition where 
active = TRUE AND
owner = 1 AND
name = 'Email Output for Queued Authority Records' AND
hook = 'vandelay.queued_auth_record.email' AND
validator = 'NOOP_True' AND
reactor = 'SendEmail' AND
group_field = 'queue.owner' --AND
--granularity = NULL	
), 'queue.owner')
;