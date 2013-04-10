-- Serial Schema

UPDATE serial.issuance SET holding_code = holding_code;

-- fix up missing holding_code fields from serial.issuance
UPDATE serial.issuance siss
    SET holding_type = scap.type
    FROM serial.caption_and_pattern scap
    WHERE scap.id = siss.caption_and_pattern AND siss.holding_type IS NULL;