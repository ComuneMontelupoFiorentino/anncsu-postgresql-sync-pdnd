-- Tabella civici referiti agli odonimi
CREATE TABLE IF NOT EXISTS accessi.civici
(
    acc_id SERIAL, -- Popolato in automatico
    geom geometry(Point, 4326) NOT NULL,
    acc_a_top_rif character varying(100) COLLATE pg_catalog."default" NOT NULL,
    acc_a_numero integer NOT NULL,
    acc_a_esponente character varying(1) COLLATE pg_catalog."default",
    acc_a_civico_comp character varying(10) COLLATE pg_catalog."default",  -- Popolato in automatico
    acc_a_rif_top_civico character varying(255) COLLATE pg_catalog."default",  -- Popolato in automatico
    acc_num_int character varying(4) COLLATE pg_catalog."default",
    acc_a_rif_top_civico_int character varying(255) COLLATE pg_catalog."default",  -- Popolato in automatico
    acc_a_sez_cens integer NOT NULL,
    acc_rif_cat_ty character varying(10) COLLATE pg_catalog."default",
    acc_rif_cat_fog integer,
    acc_rif_cat_part integer,
    acc_rif_cat_sub integer,
    progressivo_nazionale character varying(255) COLLATE pg_catalog."default", -- Popolato in automatico
    progressivo_civico character varying(255) COLLATE pg_catalog."default", -- Popolato in automatico
    allineato boolean DEFAULT false, -- Popolato in automatico
    is_civic boolean NOT NULL,
    CONSTRAINT civici_pkey PRIMARY KEY (acc_id),
    CONSTRAINT fk_acc_a_top_rif_odonimi_list FOREIGN KEY (acc_a_top_rif)
        REFERENCES stradario.odonimi_list (odonimo_completo) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_progressivo_nazionale FOREIGN KEY (progressivo_nazionale)
        REFERENCES stradario.odonimi_list (progressivo_nazionale) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);
