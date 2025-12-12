-- Tabella odonimi
CREATE TABLE IF NOT EXISTS stradario.odonimi_list
(
    id SERIAL,
    odonimo_completo text COLLATE pg_catalog."default" NOT NULL UNIQUE,
    progressivo_nazionale character varying(255) COLLATE pg_catalog."default" NOT NULL UNIQUE,
    CONSTRAINT odonimi_list_pkey PRIMARY KEY (id)
);
