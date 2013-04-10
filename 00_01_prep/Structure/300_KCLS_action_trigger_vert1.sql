-- Action Trigger Schema Inits

--This record already exists, rewrote as update below

--INSERT INTO action_trigger.event_definition (id, active, owner, name, hook, validator, reactor, delay, delay_field, group_field, template)
--    VALUES (38, FALSE, 1, 
--        'Hold Cancelled (No Target) Email Notification', 
--        'hold_request.cancel.expire_no_target', 
--        'HoldIsCancelled', 'SendEmail', '30 minutes', 'cancel_time', 'usr',
--$$
--[%- USE date -%]
--[%- user = target.0.usr -%]
--To: [%- params.recipient_email || user.email %]
--From: [%- params.sender_email || default_sender %]
--Subject: Hold Request Cancelled
--
--Dear [% user.family_name %], [% user.first_given_name %]
--The following holds were cancelled because no items were found to fullfil the hold.
--
--[% FOR hold IN target %]
--    Title: [% hold.bib_rec.bib_record.simple_record.title %]
--    Author: [% hold.bib_rec.bib_record.simple_record.author %]
--    Library: [% hold.pickup_lib.name %]
--    Request Date: [% date.format(helpers.format_date(hold.rrequest_time), '%Y-%m-%d') %]
--[% END %]
--
--$$);

--UPDATE VERSION OF INSERT ABOVE
UPDATE action_trigger.event_definition
    SET name = 'Hold Cancelled (No Target) Email Notification', 
	active = FALSE,
      template = (
$$
[%- USE date -%]
[%- user = target.0.usr -%]
To: [%- params.recipient_email || user.email %]
From: [%- params.sender_email || default_sender %]
Subject: Hold Request Cancelled

Dear [% user.family_name %], [% user.first_given_name %]
The following holds were cancelled because no items were found to fullfil the hold.

[% FOR hold IN target %]
    Title: [% hold.bib_rec.bib_record.simple_record.title %]
    Author: [% hold.bib_rec.bib_record.simple_record.author %]
    Library: [% hold.pickup_lib.name %]
    Request Date: [% date.format(helpers.format_date(hold.rrequest_time), '%Y-%m-%d') %]
[% END %]

$$)
WHERE owner = 1 AND 
      hook = 'hold_request.cancel.expire_no_target' AND 
      validator = 'HoldIsCancelled' AND 
      reactor = 'SendEmail' AND 
      delay = '30 minutes' AND 
      delay_field = 'cancel_time' AND 
      group_field ='usr';


INSERT INTO action_trigger.environment (event_def, path) VALUES
    ((select id from action_trigger.event_definition WHERE active = FALSE AND 
    owner = 1 AND
     name = 'Hold Cancelled (No Target) Email Notification' AND 
      hook = 'hold_request.cancel.expire_no_target' AND 
      validator = 'HoldIsCancelled' AND 
      reactor = 'SendEmail' AND 
      delay = '30 minutes' AND 
      delay_field = 'cancel_time' AND 
      group_field ='usr'), 'usr'),
    ((select id from action_trigger.event_definition WHERE active = FALSE AND 
    owner = 1 AND
     name = 'Hold Cancelled (No Target) Email Notification' AND 
      hook = 'hold_request.cancel.expire_no_target' AND 
      validator = 'HoldIsCancelled' AND 
      reactor = 'SendEmail' AND 
      delay = '30 minutes' AND 
      delay_field = 'cancel_time' AND 
      group_field ='usr'), 'pickup_lib'),
    ((select id from action_trigger.event_definition WHERE active = FALSE AND 
    owner = 1 AND
     name = 'Hold Cancelled (No Target) Email Notification' AND 
      hook = 'hold_request.cancel.expire_no_target' AND 
      validator = 'HoldIsCancelled' AND 
      reactor = 'SendEmail' AND 
      delay = '30 minutes' AND 
      delay_field = 'cancel_time' AND 
      group_field ='usr'), 'bib_rec.bib_record.simple_record');
