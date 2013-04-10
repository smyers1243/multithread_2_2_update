-- Auditor Schema Inits

CREATE OR REPLACE FUNCTION auditor.create_auditor_func    ( sch TEXT, tbl TEXT ) RETURNS BOOL AS $creator$
DECLARE
    column_list TEXT[];
BEGIN
    SELECT INTO column_list array_agg(a.attname)
        FROM pg_catalog.pg_attribute a
            JOIN pg_catalog.pg_class c ON a.attrelid = c.oid
            JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r' AND n.nspname = sch AND c.relname = tbl AND a.attnum > 0 AND NOT a.attisdropped;

    EXECUTE $$
        CREATE OR REPLACE FUNCTION auditor.audit_$$ || sch || $$_$$ || tbl || $$_func ()
        RETURNS TRIGGER AS $func$
        BEGIN
            INSERT INTO auditor.$$ || sch || $$_$$ || tbl || $$_history ( audit_id, audit_time, audit_action, audit_user, audit_ws, $$
            || array_to_string(column_list, ', ') || $$ )
                SELECT  nextval('auditor.$$ || sch || $$_$$ || tbl || $$_pkey_seq'),
                    now(),
                    SUBSTR(TG_OP,1,1),
                    eg_user,
                    eg_ws,
                    OLD.$$ || array_to_string(column_list, ', OLD.') || $$
                FROM auditor.get_audit_info();
            RETURN NULL;
        END;
        $func$ LANGUAGE 'plpgsql';
    $$;
    RETURN TRUE;
END;
$creator$ LANGUAGE 'plpgsql';
