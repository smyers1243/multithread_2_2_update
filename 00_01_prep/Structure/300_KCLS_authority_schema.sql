-- Authority Schema, Insert/Update

SELECT SETVAL('authority.control_set_id_seq'::TEXT, 100);
SELECT SETVAL('authority.control_set_authority_field_id_seq'::TEXT, 1000);
SELECT SETVAL('authority.control_set_bib_field_id_seq'::TEXT, 1000);

INSERT INTO authority.control_set (id, name, description) VALUES (
    1,
    oils_i18n_gettext('1','LoC','acs','name'),
    oils_i18n_gettext('1','Library of Congress standard authority record control semantics','acs','description')
);

INSERT INTO authority.control_set_authority_field (id, control_set, main_entry, tag, sf_list, name) VALUES

-- Main entries
    (1, 1, NULL, '100', 'abcdefklmnopqrstvxyz', oils_i18n_gettext('1','Heading -- Personal Name','acsaf','name')),
    (2, 1, NULL, '110', 'abcdefgklmnoprstvxyz', oils_i18n_gettext('2','Heading -- Corporate Name','acsaf','name')),
    (3, 1, NULL, '111', 'acdefgklnpqstvxyz', oils_i18n_gettext('3','Heading -- Meeting Name','acsaf','name')),
    (4, 1, NULL, '130', 'adfgklmnoprstvxyz', oils_i18n_gettext('4','Heading -- Uniform Title','acsaf','name')),
    (5, 1, NULL, '150', 'abvxyz', oils_i18n_gettext('5','Heading -- Topical Term','acsaf','name')),
    (6, 1, NULL, '151', 'avxyz', oils_i18n_gettext('6','Heading -- Geographic Name','acsaf','name')),
    (7, 1, NULL, '155', 'avxyz', oils_i18n_gettext('7','Heading -- Genre/Form Term','acsaf','name')),
    (8, 1, NULL, '180', 'vxyz', oils_i18n_gettext('8','Heading -- General Subdivision','acsaf','name')),
    (9, 1, NULL, '181', 'vxyz', oils_i18n_gettext('9','Heading -- Geographic Subdivision','acsaf','name')),
    (10, 1, NULL, '182', 'vxyz', oils_i18n_gettext('10','Heading -- Chronological Subdivision','acsaf','name')),
    (11, 1, NULL, '185', 'vxyz', oils_i18n_gettext('11','Heading -- Form Subdivision','acsaf','name')),
    (12, 1, NULL, '148', 'avxyz', oils_i18n_gettext('12','Heading -- Chronological Term','acsaf','name')),

-- See Also From tracings
    (21, 1, 1, '500', 'abcdefiklmnopqrstvwxyz4', oils_i18n_gettext('21','See Also From Tracing -- Personal Name','acsaf','name')),
    (22, 1, 2, '510', 'abcdefgiklmnoprstvwxyz4', oils_i18n_gettext('22','See Also From Tracing -- Corporate Name','acsaf','name')),
    (23, 1, 3, '511', 'acdefgiklnpqstvwxyz4', oils_i18n_gettext('23','See Also From Tracing -- Meeting Name','acsaf','name')),
    (24, 1, 4, '530', 'adfgiklmnoprstvwxyz4', oils_i18n_gettext('24','See Also From Tracing -- Uniform Title','acsaf','name')),
    (25, 1, 5, '550', 'abivwxyz4', oils_i18n_gettext('25','See Also From Tracing -- Topical Term','acsaf','name')),
    (26, 1, 6, '551', 'aivwxyz4', oils_i18n_gettext('26','See Also From Tracing -- Geographic Name','acsaf','name')),
    (27, 1, 7, '555', 'aivwxyz4', oils_i18n_gettext('27','See Also From Tracing -- Genre/Form Term','acsaf','name')),
    (28, 1, 8, '580', 'ivwxyz4', oils_i18n_gettext('28','See Also From Tracing -- General Subdivision','acsaf','name')),
    (29, 1, 9, '581', 'ivwxyz4', oils_i18n_gettext('29','See Also From Tracing -- Geographic Subdivision','acsaf','name')),
    (30, 1, 10, '582', 'ivwxyz4', oils_i18n_gettext('30','See Also From Tracing -- Chronological Subdivision','acsaf','name')),
    (31, 1, 11, '585', 'ivwxyz4', oils_i18n_gettext('31','See Also From Tracing -- Form Subdivision','acsaf','name')),
    (32, 1, 12, '548', 'aivwxyz4', oils_i18n_gettext('32','See Also From Tracing -- Chronological Term','acsaf','name')),

-- Linking entries
    (41, 1, 1, '700', 'abcdefghjklmnopqrstvwxyz25', oils_i18n_gettext('41','Established Heading Linking Entry -- Personal Name','acsaf','name')),
    (42, 1, 2, '710', 'abcdefghklmnoprstvwxyz25', oils_i18n_gettext('42','Established Heading Linking Entry -- Corporate Name','acsaf','name')),
    (43, 1, 3, '711', 'acdefghklnpqstvwxyz25', oils_i18n_gettext('43','Established Heading Linking Entry -- Meeting Name','acsaf','name')),
    (44, 1, 4, '730', 'adfghklmnoprstvwxyz25', oils_i18n_gettext('44','Established Heading Linking Entry -- Uniform Title','acsaf','name')),
    (45, 1, 5, '750', 'abvwxyz25', oils_i18n_gettext('45','Established Heading Linking Entry -- Topical Term','acsaf','name')),
    (46, 1, 6, '751', 'avwxyz25', oils_i18n_gettext('46','Established Heading Linking Entry -- Geographic Name','acsaf','name')),
    (47, 1, 7, '755', 'avwxyz25', oils_i18n_gettext('47','Established Heading Linking Entry -- Genre/Form Term','acsaf','name')),
    (48, 1, 8, '780', 'vwxyz25', oils_i18n_gettext('48','Subdivision Linking Entry -- General Subdivision','acsaf','name')),
    (49, 1, 9, '781', 'vwxyz25', oils_i18n_gettext('49','Subdivision Linking Entry -- Geographic Subdivision','acsaf','name')),
    (50, 1, 10, '782', 'vwxyz25', oils_i18n_gettext('50','Subdivision Linking Entry -- Chronological Subdivision','acsaf','name')),
    (51, 1, 11, '785', 'vwxyz25', oils_i18n_gettext('51','Subdivision Linking Entry -- Form Subdivision','acsaf','name')),
    (52, 1, 12, '748', 'avwxyz25', oils_i18n_gettext('52','Established Heading Linking Entry -- Chronological Term','acsaf','name')),

-- See From tracings
    (61, 1, 1, '400', 'abcdefiklmnopqrstvwxyz4', oils_i18n_gettext('61','See Also Tracing -- Personal Name','acsaf','name')),
    (62, 1, 2, '410', 'abcdefgiklmnoprstvwxyz4', oils_i18n_gettext('62','See Also Tracing -- Corporate Name','acsaf','name')),
    (63, 1, 3, '411', 'acdefgiklnpqstvwxyz4', oils_i18n_gettext('63','See Also Tracing -- Meeting Name','acsaf','name')),
    (64, 1, 4, '430', 'adfgiklmnoprstvwxyz4', oils_i18n_gettext('64','See Also Tracing -- Uniform Title','acsaf','name')),
    (65, 1, 5, '450', 'abivwxyz4', oils_i18n_gettext('65','See Also Tracing -- Topical Term','acsaf','name')),
    (66, 1, 6, '451', 'aivwxyz4', oils_i18n_gettext('66','See Also Tracing -- Geographic Name','acsaf','name')),
    (67, 1, 7, '455', 'aivwxyz4', oils_i18n_gettext('67','See Also Tracing -- Genre/Form Term','acsaf','name')),
    (68, 1, 8, '480', 'ivwxyz4', oils_i18n_gettext('68','See Also Tracing -- General Subdivision','acsaf','name')),
    (69, 1, 9, '481', 'ivwxyz4', oils_i18n_gettext('69','See Also Tracing -- Geographic Subdivision','acsaf','name')),
    (70, 1, 10, '482', 'ivwxyz4', oils_i18n_gettext('70','See Also Tracing -- Chronological Subdivision','acsaf','name')),
    (71, 1, 11, '485', 'ivwxyz4', oils_i18n_gettext('71','See Also Tracing -- Form Subdivision','acsaf','name')),
    (72, 1, 12, '448', 'aivwxyz4', oils_i18n_gettext('72','See Also Tracing -- Chronological Term','acsaf','name'));

INSERT INTO authority.browse_axis (code,name,description,sorter) VALUES
    ('title','Title','Title axis','titlesort'),
    ('author','Author','Author axis','titlesort'),
    ('subject','Subject','Subject axis','titlesort'),
    ('topic','Topic','Topic Subject axis','titlesort');

INSERT INTO authority.browse_axis_authority_field_map (axis,field) VALUES
    ('author',  1 ),
    ('author',  2 ),
    ('author',  3 ),
    ('title',   4 ),
    ('topic',   5 ),
    ('subject', 5 ),
    ('subject', 6 ),
    ('subject', 7 ),
    ('subject', 12);

	--Look into Union vs Union All for this one.  Union ALL might be quicker since it will just stack the result sets and we don't want this to compare
INSERT INTO authority.control_set_bib_field (tag, authority_field) 
    SELECT '100', id FROM authority.control_set_authority_field WHERE tag IN ('100')
        UNION ALL
    SELECT '600', id FROM authority.control_set_authority_field WHERE tag IN ('100','180','181','182','185')
        UNION ALL
    SELECT '700', id FROM authority.control_set_authority_field WHERE tag IN ('100')
        UNION ALL
    SELECT '800', id FROM authority.control_set_authority_field WHERE tag IN ('100')
        UNION ALL

    SELECT '110', id FROM authority.control_set_authority_field WHERE tag IN ('110')
        UNION ALL
    SELECT '610', id FROM authority.control_set_authority_field WHERE tag IN ('110')
        UNION ALL
    SELECT '710', id FROM authority.control_set_authority_field WHERE tag IN ('110')
        UNION ALL
    SELECT '810', id FROM authority.control_set_authority_field WHERE tag IN ('110')
        UNION ALL

    SELECT '111', id FROM authority.control_set_authority_field WHERE tag IN ('111')
        UNION ALL
    SELECT '611', id FROM authority.control_set_authority_field WHERE tag IN ('111')
        UNION ALL
    SELECT '711', id FROM authority.control_set_authority_field WHERE tag IN ('111')
        UNION ALL
    SELECT '811', id FROM authority.control_set_authority_field WHERE tag IN ('111')
        UNION ALL

    SELECT '130', id FROM authority.control_set_authority_field WHERE tag IN ('130')
        UNION ALL
    SELECT '240', id FROM authority.control_set_authority_field WHERE tag IN ('130')
        UNION ALL
    SELECT '630', id FROM authority.control_set_authority_field WHERE tag IN ('130')
        UNION ALL
    SELECT '730', id FROM authority.control_set_authority_field WHERE tag IN ('130')
        UNION ALL
    SELECT '830', id FROM authority.control_set_authority_field WHERE tag IN ('130')
        UNION ALL

    SELECT '648', id FROM authority.control_set_authority_field WHERE tag IN ('148')
        UNION ALL

    SELECT '650', id FROM authority.control_set_authority_field WHERE tag IN ('150','180','181','182','185')
        UNION ALL
    SELECT '651', id FROM authority.control_set_authority_field WHERE tag IN ('151','180','181','182','185')
        UNION ALL
    SELECT '655', id FROM authority.control_set_authority_field WHERE tag IN ('155','180','181','182','185')
;

INSERT INTO authority.thesaurus (code, name, control_set) VALUES
    ('a', oils_i18n_gettext('a','Library of Congress Subject Headings','at','name'), 1),
    ('b', oils_i18n_gettext('b',$$LC subject headings for children's literature$$,'at','name'), 1), -- silly vim '
    ('c', oils_i18n_gettext('c','Medical Subject Headings','at','name'), 1),
    ('d', oils_i18n_gettext('d','National Agricultural Library subject authority file','at','name'), 1),
    ('k', oils_i18n_gettext('k','Canadian Subject Headings','at','name'), 1),
    ('n', oils_i18n_gettext('n','Not applicable','at','name'), 1),
    ('r', oils_i18n_gettext('r','Art and Architecture Thesaurus','at','name'), 1),
    ('s', oils_i18n_gettext('s','Sears List of Subject Headings','at','name'), 1),
    ('v', oils_i18n_gettext('v','Repertoire de vedettes-matiere','at','name'), 1),
    ('z', oils_i18n_gettext('z','Other','at','name'), 1),
    ('|', oils_i18n_gettext('|','No attempt to code','at','name'), 1);

UPDATE authority.control_set_authority_field SET nfi = '2'
    WHERE id IN (4,24,44,64);
	
-- Don't tie "No attempt to code" to LoC
UPDATE authority.thesaurus SET control_set = NULL WHERE code = '|';
UPDATE authority.record_entry SET control_set = NULL WHERE id IN (SELECT record FROM authority.rec_descriptor WHERE thesaurus = '|');