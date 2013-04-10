
----------------------------------------------------------------
-- Seed data for queued record/item exports
----------------------------------------------------------------

-- ID 35, unknown hook, etc... /start
UPDATE action_trigger.event_definition SET template =
$$
[%- USE date -%]
<style>
    table { border-collapse: collapse; }
    td { padding: 5px; border-bottom: 1px solid #888; }
    th { font-weight: bold; }
</style>
[%
    # Sort the holds into copy-location buckets
    # In the main print loop, sort each bucket by callnumber before printing
    SET holds_list = [];
    SET loc_data = [];
    SET current_location = target.0.current_copy.location.id;
    FOR hold IN target;
        IF current_location != hold.current_copy.location.id;
            SET current_location = hold.current_copy.location.id;
            holds_list.push(loc_data);
            SET loc_data = [];
        END;
        SET hold_data = {
            'hold' => hold,
            'callnumber' => hold.current_copy.call_number.label
        };
        loc_data.push(hold_data);
    END;
    holds_list.push(loc_data)
%]
<table>
    <thead>
        <tr>
            <th>Title</th>
            <th>Author</th>
            <th>Shelving Location</th>
            <th>Call Number</th>
            <th>Barcode/Part</th>
            <th>Patron</th>
        </tr>
    </thead>
    <tbody>
    [% FOR loc_data IN holds_list  %]
        [% FOR hold_data IN loc_data.sort('callnumber') %]
            [%
                SET hold = hold_data.hold;
                SET copy_data = helpers.get_copy_bib_basics(hold.current_copy.id);
            %]
            <tr>
                <td>[% copy_data.title | truncate %]</td>
                <td>[% copy_data.author | truncate %]</td>
                <td>[% hold.current_copy.location.name %]</td>
                <td>[% hold.current_copy.call_number.label %]</td>
                <td>[% hold.current_copy.barcode %]
                    [% FOR part IN hold.current_copy.parts %]
                       [% part.part.label %]
                    [% END %]
                </td>
                <td>[% hold.usr.card.barcode %]</td>
            </tr>
        [% END %]
    [% END %]
    <tbody>
</table>
$$
    WHERE id = 35;

INSERT INTO action_trigger.environment (
        event_def,
        path
    ) VALUES
        (35, 'current_copy.parts'),
        (35, 'current_copy.parts.part')
;

-- ID 35, unknown hook, etc... /end


-- Do the same for the CVS version



-- create the hook and validator
INSERT INTO action_trigger.hook (key, core_type, description, passive)
  VALUES ('reservation.available', 'bresv', 'A reservation is available for pickup', false);
INSERT INTO action_trigger.validator (module, description)
  VALUES ('ReservationIsAvailable','Checked that a reserved resource is available for checkout');

  INSERT INTO action_trigger.hook (key, core_type, description, passive)
VALUES (
    'container.biblio_record_entry_bucket.csv',
    'cbreb',
    oils_i18n_gettext(
        'container.biblio_record_entry_bucket.csv',
        'Produce a CSV file representing a bookbag',
        'ath',
        'description'
    ),
    FALSE
);

INSERT INTO action_trigger.reactor (module, description)
VALUES (
    'ContainerCSV',
    oils_i18n_gettext(
        'ContainerCSV',
        'Facilitates produce a CSV file representing a bookbag by introducing an "items" variable into the TT environment, sorted as dictated according to user params',
        'atr',
        'description'
    )
);

INSERT INTO action_trigger.event_definition (
    active, owner,
    name, hook, reactor,
    validator, template
) VALUES (
     TRUE, 1,
    'Bookbag CSV', 'container.biblio_record_entry_bucket.csv', 'ContainerCSV',
    'NOOP_True',
$$
[%-
# target is the bookbag itself. The 'items' variable does not need to be in
# the environment because a special reactor will take care of filling it in.

FOR item IN items;
    bibxml = helpers.xml_doc(item.target_biblio_record_entry.marc);
    title = "";
    FOR part IN bibxml.findnodes('//*[@tag="245"]/*[@code="a" or @code="b"]');
        title = title _ part.textContent;
    END;
    author = bibxml.findnodes('//*[@tag="100"]/*[@code="a"]').textContent;

    helpers.csv_datum(title) %],[% helpers.csv_datum(author) %],[% FOR note IN item.notes; helpers.csv_datum(note.note); ","; END; "\n";
END -%]
$$
);

-- ID 20, check to see if note at end is valid
UPDATE action_trigger.event_definition SET template = 
$$
[%- USE date -%]
[%- user = target.usr -%]
To: [%- params.recipient_email || user.email %]
From: [%- params.sender_email || user.home_ou.email || default_sender %]
Subject: [% user.home_ou.name %]: library account password reset request

You have received this message because you, or somebody else, requested a reset
of your library system password. If you did not request a reset of your library
system password, just ignore this message and your current password will
continue to work.

If you did request a reset of your library system password, please perform
the following steps to continue the process of resetting your password:

1. Open the following link in a web browser: https://[% params.hostname %]/eg/opac/password_reset/[% target.uuid %]
The browser displays a password reset form.

2. Enter your new password in the password reset form in the browser. You must
enter the password twice to ensure that you do not make a mistake. If the
passwords match, you will then be able to log in to your library system account
with the new password.

$$
WHERE id = 20; -- Password reset request notification

-- ID 20

-- ID 14, no reference /start
UPDATE action_trigger.event_definition SET template = 
$$
[%- USE date -%]
[%- SET li = target; -%]
<div class="wrapper">
    <div class="summary" style='font-size:110%; font-weight:bold;'>

        <div>Title: [% helpers.get_li_attr("title", "", li.attributes) %]</div>
        <div>Author: [% helpers.get_li_attr("author", "", li.attributes) %]</div>
        <div class="count">Item Count: [% li.lineitem_details.size %]</div>
        <div class="lineid">Lineitem ID: [% li.id %]</div>
        <div>Open Holds: [% helpers.bre_open_hold_count(li.eg_bib_id) %]</div>

        [% IF li.distribution_formulas.size > 0 %]
            [% SET forms = [] %]
            [% FOREACH form IN li.distribution_formulas; forms.push(form.formula.name); END %]
            <div>Distribution Formulas: [% forms.join(',') %]</div>
        [% END %]

        [% IF li.lineitem_notes.size > 0 %]
            Lineitem Notes:
            <ul>
                [%- FOR note IN li.lineitem_notes -%]
                    <li>
                    [% IF note.alert_text %]
                        [% note.alert_text.code -%] 
                        [% IF note.value -%]
                            : [% note.value %]
                        [% END %]
                    [% ELSE %]
                        [% note.value -%] 
                    [% END %]
                    </li>
                [% END %]
            </ul>
        [% END %]
    </div>
    <br/>
    <table>
        <thead>
            <tr>
                <th>Branch</th>
                <th>Barcode</th>
                <th>Call Number</th>
                <th>Fund</th>
                <th>Shelving Location</th>
                <th>Recd.</th>
                <th>Notes</th>
            </tr>
        </thead>
        <tbody>
        [% FOREACH detail IN li.lineitem_details.sort('owning_lib') %]
            [% 
                IF detail.eg_copy_id;
                    SET copy = detail.eg_copy_id;
                    SET cn_label = copy.call_number.label;
                ELSE; 
                    SET copy = detail; 
                    SET cn_label = detail.cn_label;
                END 
            %]
            <tr>
                <!-- acq.lineitem_detail.id = [%- detail.id -%] -->
                <td style='padding:5px;'>[% detail.owning_lib.shortname %]</td>
                <td style='padding:5px;'>[% IF copy.barcode   %]<span class="barcode"  >[% detail.barcode   %]</span>[% END %]</td>
                <td style='padding:5px;'>[% IF cn_label %]<span class="cn_label" >[% cn_label  %]</span>[% END %]</td>
                <td style='padding:5px;'>[% IF detail.fund %]<span class="fund">[% detail.fund.code %] ([% detail.fund.year %])</span>[% END %]</td>
                <td style='padding:5px;'>[% copy.location.name %]</td>
                <td style='padding:5px;'>[% IF detail.recv_time %]<span class="recv_time">[% detail.recv_time %]</span>[% END %]</td>
                <td style='padding:5px;'>[% detail.note %]</td>
            </tr>
        [% END %]
        </tbody>
    </table>
</div>
$$
WHERE id = 14;

-- ID 14, no reference /end

INSERT INTO action_trigger.cleanup ( module, description ) VALUES (
    'CreateHoldNotification',
    oils_i18n_gettext(
        'CreateHoldNotification',
        'Creates a hold_notification record for each notified hold',
        'atclean',
        'description'
    )
);

--ID = 5, no reference /start
UPDATE action_trigger.event_definition 
    SET 
        cleanup_success = 'CreateHoldNotification' 
    WHERE 
        id = 5 -- stock hold-ready email event_def
        AND cleanup_success IS NULL; -- don't clobber any existing cleanup mod
		
--ID = 5, no reference /end

UPDATE action_trigger.event_definition SET template = $$
[%-
# target is the bookbag itself. The 'items' variable does not need to be in
# the environment because a special reactor will take care of filling it in.

FOR item IN items;
    bibxml = helpers.unapi_bre(item.target_biblio_record_entry, {flesh => '{mra}'});
    title = "";
    FOR part IN bibxml.findnodes('//*[@tag="245"]/*[@code="a" or @code="b"]');
        title = title _ part.textContent;
    END;
    author = bibxml.findnodes('//*[@tag="100"]/*[@code="a"]').textContent;
    item_type = bibxml.findnodes('//*[local-name()="attributes"]/*[local-name()="field"][@name="item_type"]').getAttribute('coded-value');

    helpers.csv_datum(title) %],[% helpers.csv_datum(author) %],[% helpers.csv_datum(item_type) %],[% FOR note IN item.notes; helpers.csv_datum(note.note); ","; END; "\n";
END -%]
$$
WHERE reactor = 'ContainerCSV';

INSERT INTO action_trigger.event_definition (
    active,
    owner,
    name,
    hook,
    validator,
    reactor,
    cleanup_success,
    delay,
    delay_field,
    group_field,
    template
) VALUES (
    true,
    1, -- admin
    'Hold Ready for Pickup SMS Notification',
    'hold.available',
    'HoldIsAvailable',
    'SendSMS',
    'CreateHoldNotification',
    '00:30:00',
    'shelf_time',
    'sms_notify',
    '[%- USE date -%]
[%- user = target.0.usr -%]
From: [%- params.sender_email || default_sender %]
To: [%- params.recipient_email || helpers.get_sms_gateway_email(target.0.sms_carrier,target.0.sms_notify) %]
Subject: [% target.size %] hold(s) ready

[% FOR hold IN target %][%-
  bibxml = helpers.xml_doc( hold.current_copy.call_number.record.marc );
  title = "";
  FOR part IN bibxml.findnodes(''//*[@tag="245"]/*[@code="a"]'');
    title = title _ part.textContent;
  END;
  author = bibxml.findnodes(''//*[@tag="100"]/*[@code="a"]'').textContent;
%][% hold.usr.first_given_name %]:[% title %] @ [% hold.pickup_lib.name %]
[% END %]
'
);

INSERT INTO action_trigger.environment (
    event_def,
    path
) VALUES (
    currval('action_trigger.event_definition_id_seq'),
    'current_copy.call_number.record.simple_record'
), (
    currval('action_trigger.event_definition_id_seq'),
    'usr'
), (
    currval('action_trigger.event_definition_id_seq'),
    'pickup_lib.billing_address'
);

INSERT INTO action_trigger.hook(
    key,
    core_type,
    description,
    passive
) VALUES (
    'acn.format.sms_text',
    'acn',
    oils_i18n_gettext(
        'acn.format.sms_text',
        'A text message has been requested for a call number.',
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
    template
) VALUES (
    true,
    1, -- admin
    'SMS Call Number',
    'acn.format.sms_text',
    'NOOP_True',
    'SendSMS',
    '[%- USE date -%]
From: [%- params.sender_email || default_sender %]
To: [%- params.recipient_email || helpers.get_sms_gateway_email(user_data.sms_carrier,user_data.sms_notify) %]
Subject: Call Number

[%-
  bibxml = helpers.xml_doc( target.record.marc );
  title = "";
  FOR part IN bibxml.findnodes(''//*[@tag="245"]/*[@code="a" or @code="b"]'');
    title = title _ part.textContent;
  END;
  author = bibxml.findnodes(''//*[@tag="100"]/*[@code="a"]'').textContent;
%]
Call Number: [% target.label %]
Location: [% helpers.get_most_populous_location( target.id ).name %]
Library: [% target.owning_lib.name %]
[%- IF title %]
Title: [% title %]
[%- END %]
[%- IF author %]
Author: [% author %]
[%- END %]
'
);

INSERT INTO action_trigger.environment (
    event_def,
    path
) VALUES (
    currval('action_trigger.event_definition_id_seq'),
    'record.simple_record'
), (
    currval('action_trigger.event_definition_id_seq'),
    'owning_lib.billing_address'
);

INSERT INTO action_trigger.hook (key, core_type, description, passive)
VALUES (
    'circ.format.history.csv',
    'circ',
    oils_i18n_gettext(
        'circ.format.history.csv',
        'Produce CSV of circulation history',
        'ath',
        'description'
    ),
    FALSE
);

INSERT INTO action_trigger.event_definition (
    active, owner, name, hook, reactor, validator, group_field, template) 
VALUES (
    TRUE, 1, 'Circ History CSV', 'circ.format.history.csv', 'ProcessTemplate', 'NOOP_True', 'usr',
$$
Title,Author,Call Number,Barcode,Format
[%-
FOR circ IN target;
    bibxml = helpers.unapi_bre(circ.target_copy.call_number.record, {flesh => '{mra}'});
    title = "";
    FOR part IN bibxml.findnodes('//*[@tag="245"]/*[@code="a" or @code="b"]');
        title = title _ part.textContent;
    END;
    author = bibxml.findnodes('//*[@tag="100"]/*[@code="a"]').textContent;
    item_type = bibxml.findnodes('//*[local-name()="attributes"]/*[local-name()="field"][@name="item_type"]').getAttribute('coded-value') %]

    [%- helpers.csv_datum(title) -%],
    [%- helpers.csv_datum(author) -%],
    [%- helpers.csv_datum(circ.target_copy.call_number.label) -%],
    [%- helpers.csv_datum(circ.target_copy.barcode) -%],
    [%- helpers.csv_datum(item_type) %]
[%- END -%]
$$
);

INSERT INTO action_trigger.environment (event_def, path)
    VALUES (
        currval('action_trigger.event_definition_id_seq'),
        'target_copy.call_number'
    );

UPDATE action_trigger.event_definition SET template = $$
<div>
    <style> li { padding: 8px; margin 5px; }</style>
    <ol>
    [% FOR cbreb IN target %]
    [% FOR item IN cbreb.items;
        bre_id = item.target_biblio_record_entry;

        bibxml = helpers.unapi_bre(bre_id, {flesh => '{mra}'});
        FOR part IN bibxml.findnodes('//*[@tag="245"]/*[@code="a" or @code="b"]');
            title = title _ part.textContent;
        END;

        author = bibxml.findnodes('//*[@tag="100"]/*[@code="a"]').textContent;
        item_type = bibxml.findnodes('//*[local-name()="attributes"]/*[local-name()="field"][@name="item_type"]').getAttribute('coded-value');
        publisher = bibxml.findnodes('//*[@tag="260"]/*[@code="b"]').textContent;
        pubdate = bibxml.findnodes('//*[@tag="260"]/*[@code="c"]').textContent;
        isbn = bibxml.findnodes('//*[@tag="020"]/*[@code="a"]').textContent;
        issn = bibxml.findnodes('//*[@tag="022"]/*[@code="a"]').textContent;
        upc = bibxml.findnodes('//*[@tag="024"]/*[@code="a"]').textContent;
        %]

        <li>
            Bib ID# [% bre_id %]<br/>
            [% IF isbn %]ISBN: [% isbn %]<br/>[% END %]
            [% IF issn %]ISSN: [% issn %]<br/>[% END %]
            [% IF upc  %]UPC:  [% upc %]<br/>[% END %]
            Title: [% title %]<br />
            Author: [% author %]<br />
            Publication Info: [% publisher %] [% pubdate %]<br/>
            Item Type: [% item_type %]
        </li>
    [% END %]
    [% END %]
    </ol>
</div>
$$ 
WHERE hook = 'biblio.format.record_entry.print' AND id < 100; -- sample data


UPDATE action_trigger.event_definition SET delay = '00:00:00', template = $$
[%- SET user = target.0.owner -%]
To: [%- params.recipient_email || user.email %]
From: [%- params.sender_email || default_sender %]
Subject: Bibliographic Records

[% FOR cbreb IN target %]
[% FOR item IN cbreb.items;
    bre_id = item.target_biblio_record_entry;

    bibxml = helpers.unapi_bre(bre_id, {flesh => '{mra}'});
    FOR part IN bibxml.findnodes('//*[@tag="245"]/*[@code="a" or @code="b"]');
        title = title _ part.textContent;
    END;

    author = bibxml.findnodes('//*[@tag="100"]/*[@code="a"]').textContent;
    item_type = bibxml.findnodes('//*[local-name()="attributes"]/*[local-name()="field"][@name="item_type"]').getAttribute('coded-value');
    publisher = bibxml.findnodes('//*[@tag="260"]/*[@code="b"]').textContent;
    pubdate = bibxml.findnodes('//*[@tag="260"]/*[@code="c"]').textContent;
    isbn = bibxml.findnodes('//*[@tag="020"]/*[@code="a"]').textContent;
    issn = bibxml.findnodes('//*[@tag="022"]/*[@code="a"]').textContent;
    upc = bibxml.findnodes('//*[@tag="024"]/*[@code="a"]').textContent;
%]

[% loop.count %]/[% loop.size %].  Bib ID# [% bre_id %] 
[% IF isbn %]ISBN: [% isbn _ "\n" %][% END -%]
[% IF issn %]ISSN: [% issn _ "\n" %][% END -%]
[% IF upc  %]UPC:  [% upc _ "\n" %] [% END -%]
Title: [% title %]
Author: [% author %]
Publication Info: [% publisher %] [% pubdate %]
Item Type: [% item_type %]

[% END %]
[% END %]
$$ 
WHERE hook = 'biblio.format.record_entry.email' AND id < 100; -- sample data

-- remove a swath of unused environment entries

DELETE FROM action_trigger.environment env 
    USING action_trigger.event_definition def 
    WHERE env.event_def = def.id AND 
        env.path != 'items' AND 
        def.hook = 'biblio.format.record_entry.print' AND 
        def.id < 100; -- sample data

DELETE FROM action_trigger.environment env 
    USING action_trigger.event_definition def 
    WHERE env.event_def = def.id AND 
        env.path != 'items' AND 
        env.path != 'owner' AND 
        def.hook = 'biblio.format.record_entry.email' AND 
        def.id < 100; -- sample data
