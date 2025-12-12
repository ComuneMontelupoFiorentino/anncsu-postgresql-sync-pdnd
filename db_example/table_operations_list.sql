-- Tabella lista operazioni conferimento dati ad ANNCSU
CREATE TABLE IF NOT EXISTS accessi.operations_sinc_anncsu
(
    id SERIAL,
    op_ty character varying(1) COLLATE pg_catalog."default" NOT NULL,
    op_desc text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT operations_sinc_anncsu_pkey PRIMARY KEY (id),
    CONSTRAINT operations_sinc_anncsu_op_ty_key UNIQUE (op_ty)
);
-- Operazioni conferimento dati ad ANNCSU
INSERT INTO accessi.operations_sinc_anncsu(op_ty, op_desc)
VALUES ('I', 'Insert'), ('R', 'Update'), ('S', 'Delete');
