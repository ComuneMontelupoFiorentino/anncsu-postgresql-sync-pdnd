-- Tabella processo conferimento ad ANNCSU
CREATE TABLE IF NOT EXISTS accessi.sync_anncsu_queue
(
    id SERIAL,
    id_civico integer NOT NULL,
    progressivo_nazionale character varying(255) COLLATE pg_catalog."default" NOT NULL,
    progressivo_civico character varying(255) COLLATE pg_catalog."default",
    esponente character varying(10) COLLATE pg_catalog."default",
    sezione_censimento integer NOT NULL,
    coord_x numeric(20,6) NOT NULL,
    coord_y numeric(20,6) NOT NULL,
    metodo integer NOT NULL DEFAULT 3,
    operazione character varying(1) COLLATE pg_catalog."default" NOT NULL,
    allineato boolean DEFAULT false,
    error text COLLATE pg_catalog."default",
    civico character varying(10) COLLATE pg_catalog."default" NOT NULL,
    allineato_time timestamp without time zone,
    CONSTRAINT sync_anncsu_queue_pkey PRIMARY KEY (id),
    CONSTRAINT sync_anncsu_queue_operazione_fkey FOREIGN KEY (operazione)
        REFERENCES accessi.operations_sinc_anncsu (op_ty) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);
