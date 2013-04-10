INSERT INTO action_trigger.hook (key,core_type,description,passive) VALUES (
        'vandelay.queued_bib_record.print',
        'vqbr', 
        oils_i18n_gettext(
            'vandelay.queued_bib_record.print',
            'Print output has been requested for records in an Importer Bib Queue.',
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
        'Print Output for Queued Bib Records',
        'vandelay.queued_bib_record.print',
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

    [% FOR vqbr IN target %]
=-=-=
 Title of work    | [% helpers.get_queued_bib_attr('title',vqbr.attributes) %]
 Author of work   | [% helpers.get_queued_bib_attr('author',vqbr.attributes) %]
 Language of work | [% helpers.get_queued_bib_attr('language',vqbr.attributes) %]
 Pagination       | [% helpers.get_queued_bib_attr('pagination',vqbr.attributes) %]
 ISBN             | [% helpers.get_queued_bib_attr('isbn',vqbr.attributes) %]
 ISSN             | [% helpers.get_queued_bib_attr('issn',vqbr.attributes) %]
 Price            | [% helpers.get_queued_bib_attr('price',vqbr.attributes) %]
 Accession Number | [% helpers.get_queued_bib_attr('rec_identifier',vqbr.attributes) %]
 TCN Value        | [% helpers.get_queued_bib_attr('eg_tcn',vqbr.attributes) %]
 TCN Source       | [% helpers.get_queued_bib_attr('eg_tcn_source',vqbr.attributes) %]
 Internal ID      | [% helpers.get_queued_bib_attr('eg_identifier',vqbr.attributes) %]
 Publisher        | [% helpers.get_queued_bib_attr('publisher',vqbr.attributes) %]
 Publication Date | [% helpers.get_queued_bib_attr('pubdate',vqbr.attributes) %]
 Edition          | [% helpers.get_queued_bib_attr('edition',vqbr.attributes) %]
 Item Barcode     | [% helpers.get_queued_bib_attr('item_barcode',vqbr.attributes) %]

    [% END %]
</pre>
$$
    )
;

INSERT INTO action_trigger.environment ( event_def, path) VALUES (
    (
select id from action_trigger.event_definition where 
active = TRUE	AND
owner = 1	AND
name = 'Print Output for Queued Bib Records'	AND
hook = 'vandelay.queued_bib_record.print'	AND
validator = 'NOOP_True'	AND
reactor = 'ProcessTemplate'	AND
group_field = 'queue.owner'	AND
granularity = 'print-on-demand'	
)
, 'attributes')
    ,( (
select id from action_trigger.event_definition where 
active = TRUE	AND
owner = 1	AND
name = 'Print Output for Queued Bib Records'	AND
hook = 'vandelay.queued_bib_record.print'	AND
validator = 'NOOP_True'	AND
reactor = 'ProcessTemplate'	AND
group_field = 'queue.owner'	AND
granularity = 'print-on-demand'	
)
, 'queue')
;

UPDATE action_trigger.event_definition SET template = $$
[%- USE date -%]
<pre>
Queue ID: [% target.0.queue.id %]
Queue Name: [% target.0.queue.name %]
Queue Type: [% target.0.queue.queue_type %]
Complete? [% target.0.queue.complete %]

    [% FOR vqbr IN target %]
=-=-=
 Title of work    | [% helpers.get_queued_bib_attr('title',vqbr.attributes) %]
 Author of work   | [% helpers.get_queued_bib_attr('author',vqbr.attributes) %]
 Language of work | [% helpers.get_queued_bib_attr('language',vqbr.attributes) %]
 Pagination       | [% helpers.get_queued_bib_attr('pagination',vqbr.attributes) %]
 ISBN             | [% helpers.get_queued_bib_attr('isbn',vqbr.attributes) %]
 ISSN             | [% helpers.get_queued_bib_attr('issn',vqbr.attributes) %]
 Price            | [% helpers.get_queued_bib_attr('price',vqbr.attributes) %]
 Accession Number | [% helpers.get_queued_bib_attr('rec_identifier',vqbr.attributes) %]
 TCN Value        | [% helpers.get_queued_bib_attr('eg_tcn',vqbr.attributes) %]
 TCN Source       | [% helpers.get_queued_bib_attr('eg_tcn_source',vqbr.attributes) %]
 Internal ID      | [% helpers.get_queued_bib_attr('eg_identifier',vqbr.attributes) %]
 Publisher        | [% helpers.get_queued_bib_attr('publisher',vqbr.attributes) %]
 Publication Date | [% helpers.get_queued_bib_attr('pubdate',vqbr.attributes) %]
 Edition          | [% helpers.get_queued_bib_attr('edition',vqbr.attributes) %]
 Item Barcode     | [% helpers.get_queued_bib_attr('item_barcode',vqbr.attributes) %]
 Import Error     | [% vqbr.import_error %]
 Error Detail     | [% vqbr.error_detail %]
 Match Count      | [% vqbr.matches.size %]

    [% END %]
</pre>
$$
WHERE (
active = TRUE	AND
owner = 1	AND
name = 'Print Output for Queued Bib Records'	AND
hook = 'vandelay.queued_bib_record.print'	AND
validator = 'NOOP_True'	AND
reactor = 'ProcessTemplate'	AND
group_field = 'queue.owner'	AND
granularity = 'print-on-demand'	
)
;

INSERT INTO action_trigger.environment (event_def, path) VALUES ((
select id from action_trigger.event_definition where 
active = TRUE	AND
owner = 1	AND
name = 'Print Output for Queued Bib Records'	AND
hook = 'vandelay.queued_bib_record.print'	AND
validator = 'NOOP_True'	AND
reactor = 'ProcessTemplate'	AND
group_field = 'queue.owner'	AND
granularity = 'print-on-demand'	
)
, 'matches');