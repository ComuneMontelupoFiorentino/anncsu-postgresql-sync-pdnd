-- Funzione per salvare il timestamp di conferimento dati
CREATE OR REPLACE FUNCTION accessi.trg_sync_anncsu_queue_allineato_time()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    -- Se allineato passa a TRUE
    IF (NEW.allineato = true) AND (OLD.allineato IS DISTINCT FROM TRUE) THEN
        NEW.allineato_time := NOW();
    END IF;

    RETURN NEW;
END;
$BODY$;
-- Trigger per salvare il timestamp di conferimento dati
CREATE OR REPLACE TRIGGER tg_sync_anncsu_queue_allineato_time
    BEFORE UPDATE OF allineato
    ON accessi.sync_anncsu_queue
    FOR EACH ROW
    EXECUTE FUNCTION accessi.trg_sync_anncsu_queue_allineato_time();
-- ************************************ 
-- Funzioni per sincronizzare DB con ANNCSU
-- ************************************ 
CREATE OR REPLACE FUNCTION accessi.anncsu_sync_delete_civici_fc()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
    existing_id INTEGER;
    existing_op CHAR(1);
BEGIN
	-- Verirfico se è un civico ANNCSU
	IF OLD.is_civic IS DISTINCT FROM TRUE THEN
        RETURN OLD;
    END IF;
	
    -- Verifica eventuale operazione non allineata
    SELECT id, operazione
    INTO existing_id, existing_op
    FROM accessi.sync_anncsu_queue
    WHERE id_civico = OLD.acc_id
      AND allineato = false
    ORDER BY id DESC
    LIMIT 1;

    IF existing_id IS NOT NULL THEN

        -- Caso 1: 'S' → non fare nulla
        IF existing_op = 'S' THEN
            RETURN OLD;
        END IF;

        -- Caso 2: 'I' → elimina e basta
        IF existing_op = 'I' THEN
            DELETE FROM accessi.sync_anncsu_queue WHERE id = existing_id;
            RETURN OLD;
        END IF;

        -- Caso 3: 'R' → elimina e poi inserisci nuova 'S'
        IF existing_op = 'R' THEN
            DELETE FROM accessi.sync_anncsu_queue WHERE id = existing_id;
        END IF;
    END IF;

    -- Inserisci operazione di soppressione
    INSERT INTO accessi.sync_anncsu_queue
    (
        id_civico,
        progressivo_nazionale,
        progressivo_civico,
        civico,
        esponente,
        sezione_censimento,
        coord_x,
        coord_y,
        metodo,
        operazione
    )
    VALUES
    (
        OLD.acc_id,
        OLD.progressivo_nazionale,
        OLD.progressivo_civico,
        OLD.acc_a_numero::varchar,
        OLD.acc_a_esponente,
        OLD.acc_a_sez_cens,
        ROUND(ST_X(ST_Transform(OLD.geom, 4326))::numeric, 6),
        ROUND(ST_Y(ST_Transform(OLD.geom, 4326))::numeric, 6),
        3,
        'S'
    );

    RETURN OLD;
END;
$BODY$;

CREATE OR REPLACE TRIGGER anncsu_sync_delete_civici_tr
    AFTER DELETE
    ON accessi.civici
    FOR EACH ROW
    EXECUTE FUNCTION accessi.anncsu_sync_delete_civici_fc();
CREATE OR REPLACE FUNCTION accessi.anncsu_sync_insertcivici_fc()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    -- Se NON è il civico principale, non sincronizza
    IF NEW.is_civic IS DISTINCT FROM TRUE THEN
        RETURN NEW;
    END IF;

    INSERT INTO accessi.sync_anncsu_queue
    (
        id_civico,
        progressivo_nazionale,
        progressivo_civico,
        civico,
        esponente,
        sezione_censimento,
        coord_x,
        coord_y,
        metodo,
        operazione
    )
    VALUES
    (
        NEW.acc_id,
        NEW.progressivo_nazionale,
        NEW.progressivo_civico,
        NEW.acc_a_numero::varchar,
        NEW.acc_a_esponente,
        NEW.acc_a_sez_cens,
        ROUND(ST_X(ST_Transform(NEW.geom, 4326))::numeric, 6),
        ROUND(ST_Y(ST_Transform(NEW.geom, 4326))::numeric, 6),
        3,
        'I'
    );

    RETURN NEW;
END;
$BODY$;
CREATE OR REPLACE TRIGGER anncsu_sync_insert_civici_tr
    AFTER INSERT
    ON accessi.civici
    FOR EACH ROW
    EXECUTE FUNCTION accessi.anncsu_sync_insertcivici_fc();
CREATE OR REPLACE FUNCTION accessi.anncsu_sync_update_civici_fc()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
    existing_id INTEGER;
BEGIN
    /*
     * Procedi SOLO se:
     *  - uno dei campi di interesse è cambiato (numero, esponente, geom)
     *  - E il record risultante NEW è is_civic = TRUE
     *
     * NOTA: eventuali cambi a is_civic non causano l'invio di 'S' o altre operazioni.
     */
    IF NOT (
           (NEW.acc_a_esponente IS DISTINCT FROM OLD.acc_a_esponente)
        OR (NEW.acc_a_numero   IS DISTINCT FROM OLD.acc_a_numero)
        OR (NEW.progressivo_nazionale IS DISTINCT FROM OLD.progressivo_nazionale)
		OR (NEW.geom           IS DISTINCT FROM OLD.geom)
       )
       OR NEW.is_civic IS NOT TRUE
    THEN
        RETURN NEW;
    END IF;

    -- Cerca eventuale record non allineato esistente per questo acc_id
    SELECT id INTO existing_id
    FROM accessi.sync_anncsu_queue
    WHERE id_civico = NEW.acc_id
      AND allineato = false
      AND operazione IN ('I','R')
    ORDER BY id DESC
    LIMIT 1;

    IF existing_id IS NOT NULL THEN
        -- Aggiorna il record già presente (lo marca come "R" - replace/update)
        UPDATE accessi.sync_anncsu_queue
        SET
            progressivo_nazionale = NEW.progressivo_nazionale,
            progressivo_civico     = NEW.progressivo_civico,
            civico                 = NEW.acc_a_numero::varchar,
            esponente              = NEW.acc_a_esponente,
            sezione_censimento     = NEW.acc_a_sez_cens,
            coord_x                = ROUND(ST_X(ST_Transform(NEW.geom, 4326))::numeric, 6),
            coord_y                = ROUND(ST_Y(ST_Transform(NEW.geom, 4326))::numeric, 6),
            metodo                 = 3,
            operazione             = 'R'
        WHERE id = existing_id;
    ELSE
        -- Inserisce nuovo record "R"
        INSERT INTO accessi.sync_anncsu_queue (
            id_civico,
            progressivo_nazionale,
            progressivo_civico,
            civico,
            esponente,
            sezione_censimento,
            coord_x,
            coord_y,
            metodo,
            operazione
        )
        VALUES (
            NEW.acc_id,
            NEW.progressivo_nazionale,
            NEW.progressivo_civico,
            NEW.acc_a_numero::varchar,
            NEW.acc_a_esponente,
            NEW.acc_a_sez_cens,
            ROUND(ST_X(ST_Transform(NEW.geom, 4326))::numeric, 6),
            ROUND(ST_Y(ST_Transform(NEW.geom, 4326))::numeric, 6),
            3,
            'R'
        );
    END IF;

    -- Imposta il record come non allineato nella tabella principale
    UPDATE accessi.civici
    SET allineato = false
    WHERE acc_id = NEW.acc_id;

    RETURN NEW;
END;
$BODY$;

-- ************************************ 
-- Funzione per popolamento automatico dei campo
-- Totla funzione per sezione censuaria
-- ************************************ 
CREATE OR REPLACE TRIGGER anncsu_sync_update_civici_tr
    AFTER UPDATE 
    ON accessi.civici
    FOR EACH ROW
    EXECUTE FUNCTION accessi.anncsu_sync_update_civici_fc();

CREATE OR REPLACE FUNCTION accessi.aut_updating_fields_civici_fc()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
    v_progressivo TEXT;
    v_sez INTEGER;
    v_zon_n TEXT;
    v_zon_n_quota DOUBLE PRECISION;
    v_is_civic TEXT;
BEGIN

    --  Civico composto: via+civico+esponente 
    NEW.acc_a_civico_comp := NEW.acc_a_numero::text || COALESCE(NEW.acc_a_esponente, '');
    NEW.acc_a_rif_top_civico := NEW.acc_a_top_rif || '-' || NEW.acc_a_civico_comp;

    --  Civico composto: via+civico+esponente+interno

    IF NEW.acc_num_int IS NOT NULL THEN
        NEW.acc_a_rif_top_civico_int :=
            NEW.acc_a_top_rif || '-' || NEW.acc_a_civico_comp || 'int' || NEW.acc_num_int;
    ELSE
        NEW.acc_a_rif_top_civico_int := NULL;
    END IF;

    -- Progressivo nazionale
    SELECT s.progressivo_nazionale
     INTO v_progressivo
     FROM stradario.odonimi_list s
    WHERE s.odonimo_completo = NEW.acc_a_top_rif
    LIMIT 1;

    NEW.progressivo_nazionale := v_progressivo;

    -- Setta "Is civic" di default lo setta come true, se esiste come false
	SELECT 1
	  INTO v_is_civic
	  FROM accessi.civici
	 WHERE acc_a_rif_top_civico = NEW.acc_a_rif_top_civico
	   AND is_civic = TRUE
	 LIMIT 1;
	
	IF FOUND THEN
	    -- C’è già un civico uguale → NON è un civico
	    NEW.is_civic := FALSE;
	ELSE
	    NEW.is_civic := TRUE;
	END IF;

    RETURN NEW;
END;
$BODY$;

CREATE OR REPLACE TRIGGER aut_updating_fields_civici_tr
    BEFORE INSERT OR UPDATE 
    ON accessi.civici
    FOR EACH ROW
    EXECUTE FUNCTION accessi.aut_updating_fields_civici_fc();
