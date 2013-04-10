DROP FUNCTION IF EXISTS actor.stat_cat_check();
CREATE OR REPLACE FUNCTION actor.stat_cat_check() RETURNS trigger AS $func$
DECLARE
    sipfield actor.stat_cat_sip_fields%ROWTYPE;
    use_count INT;
BEGIN
    IF NEW.sip_field IS NOT NULL THEN
        SELECT INTO sipfield * FROM actor.stat_cat_sip_fields WHERE field = NEW.sip_field;
        IF sipfield.one_only THEN
            SELECT INTO use_count count(id) FROM actor.stat_cat WHERE sip_field = NEW.sip_field AND id != NEW.id;
            IF use_count > 0 THEN
                RAISE EXCEPTION 'Sip field cannot be used twice';
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$func$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS actor.address_alert_matches (
        org_unit INT, 
        street1 TEXT, 
        street2 TEXT, 
        city TEXT, 
        county TEXT, 
        state TEXT, 
        country TEXT, 
        post_code TEXT,
        mailing_address BOOL,
        billing_address BOOL
    );
CREATE OR REPLACE FUNCTION actor.address_alert_matches (
        org_unit INT, 
        street1 TEXT, 
        street2 TEXT, 
        city TEXT, 
        county TEXT, 
        state TEXT, 
        country TEXT, 
        post_code TEXT,
        mailing_address BOOL DEFAULT FALSE,
        billing_address BOOL DEFAULT FALSE
    ) RETURNS SETOF actor.address_alert AS $$

SELECT *
FROM actor.address_alert
WHERE
    active
    AND owner IN (SELECT id FROM actor.org_unit_ancestors($1)) 
    AND (
        (NOT mailing_address AND NOT billing_address)
        OR (mailing_address AND $9)
        OR (billing_address AND $10)
    )
    AND (
            (
                match_all
                AND COALESCE($2, '') ~* COALESCE(street1,   '.*')
                AND COALESCE($3, '') ~* COALESCE(street2,   '.*')
                AND COALESCE($4, '') ~* COALESCE(city,      '.*')
                AND COALESCE($5, '') ~* COALESCE(county,    '.*')
                AND COALESCE($6, '') ~* COALESCE(state,     '.*')
                AND COALESCE($7, '') ~* COALESCE(country,   '.*')
                AND COALESCE($8, '') ~* COALESCE(post_code, '.*')
            ) OR (
                NOT match_all 
                AND (  
                       $2 ~* street1
                    OR $3 ~* street2
                    OR $4 ~* city
                    OR $5 ~* county
                    OR $6 ~* state
                    OR $7 ~* country
                    OR $8 ~* post_code
                )
            )
        )
    ORDER BY actor.org_unit_proximity(owner, $1)
$$ LANGUAGE SQL;

-- given a set of activity criteria, find the most approprate activity type
DROP FUNCTION IF EXISTS actor.usr_activity_get_type ( ewho TEXT, ewhat TEXT,  ehow TEXT );
CREATE OR REPLACE FUNCTION actor.usr_activity_get_type (
        ewho TEXT, 
        ewhat TEXT, 
        ehow TEXT
    ) RETURNS SETOF config.usr_activity_type AS $$
SELECT * FROM config.usr_activity_type 
    WHERE 
        enabled AND 
        (ewho  IS NULL OR ewho  = $1) AND
        (ewhat IS NULL OR ewhat = $2) AND
        (ehow  IS NULL OR ehow  = $3) 
    ORDER BY 
        -- BOOL comparisons sort false to true
        COALESCE(ewho, '')  != COALESCE($1, ''),
        COALESCE(ewhat,'')  != COALESCE($2, ''),
        COALESCE(ehow, '')  != COALESCE($3, '') 
    LIMIT 1;
$$ LANGUAGE SQL;

-- Given the IDs of two rows in actor.org_unit, *the second being an ancestor
-- of the first*, return in array form the path from the ancestor to the
-- descendant, with each point in the path being an org_unit ID.  This is
-- useful for sorting org_units by their position in a depth-first (display
-- order) representation of the tree.
--
-- This breaks with the precedent set by actor.org_unit_full_path() and others,
-- and gets the parameters "backwards," but otherwise this function would
-- not be very usable within json_query.
DROP FUNCTION IF EXISTS actor.org_unit_simple_path(INT, INT);
CREATE OR REPLACE FUNCTION actor.org_unit_simple_path(INT, INT)
RETURNS INT[] AS $$
    WITH RECURSIVE descendant_depth(id, path) AS (
        SELECT  aou.id,
                ARRAY[aou.id]
          FROM  actor.org_unit aou
                JOIN actor.org_unit_type aout ON (aout.id = aou.ou_type)
          WHERE aou.id = $2
            UNION ALL
        SELECT  aou.id,
                dd.path || ARRAY[aou.id]
          FROM  actor.org_unit aou
                JOIN actor.org_unit_type aout ON (aout.id = aou.ou_type)
                JOIN descendant_depth dd ON (dd.id = aou.parent_ou)
    ) SELECT dd.path
        FROM actor.org_unit aou
        JOIN descendant_depth dd USING (id)
        WHERE aou.id = $1 ORDER BY dd.path;
$$ LANGUAGE SQL STABLE;

DROP FUNCTION IF EXISTS actor.org_unit_prox_update ();
CREATE OR REPLACE FUNCTION actor.org_unit_prox_update () RETURNS TRIGGER as $$
BEGIN


IF TG_OP = 'DELETE' THEN

    DELETE FROM actor.org_unit_proximity WHERE (from_org = OLD.id or to_org= OLD.id);

END IF;

IF TG_OP = 'UPDATE' THEN

    IF NEW.parent_ou <> OLD.parent_ou THEN

        DELETE FROM actor.org_unit_proximity WHERE (from_org = OLD.id or to_org= OLD.id);
            INSERT INTO actor.org_unit_proximity (from_org, to_org, prox)
            SELECT  l.id, r.id, actor.org_unit_proximity(l.id,r.id)
                FROM  actor.org_unit l, actor.org_unit r
                WHERE (l.id = NEW.id or r.id = NEW.id);

    END IF;

END IF;

IF TG_OP = 'INSERT' THEN

     INSERT INTO actor.org_unit_proximity (from_org, to_org, prox)
     SELECT  l.id, r.id, actor.org_unit_proximity(l.id,r.id)
         FROM  actor.org_unit l, actor.org_unit r
         WHERE (l.id = NEW.id or r.id = NEW.id);

END IF;

RETURN null;

END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS actor.au_updated();
--TRIGGER au_update_trig depends on this function
CREATE OR REPLACE FUNCTION actor.au_updated()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_update_time := now();
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

