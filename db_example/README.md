# UTILITÀ PER CREAZIONE DB POSTGRESQL PER LA GESTIONE E CONFERIMENTO DEI CIVICI

Questo repository contiene gli script SQL utili per creare e gestire il database **Toponomastica** di esempio, utilizzabile per la gestione di odonimi, civici e processi di sincronizzazione verso ANNCSU.

La cartella `db_example/` include:

- la definizione degli schemi (stradario, accessi)

- le tabelle principali

- le funzioni PL/pgSQL

- i trigger per la sincronizzazione

- la vista per l’esportazione delle coordinate

Gli script sono stati suddivisi per favorire manutenzione, versionamento e lettura

## Requisiti

Per utilizzare questi script è necessario installare:

**PostgreSQL 15+**

**PostGIS 3.3+**

**PgAdmin4** (opzionale)

## Struttura cartella

```bash
|── db_example/
    |── 01_schemas.sql
    |── 02_extensions.sql
    |── 03_table_odonimi.sql
    |── 04_table_civici.sql
    |── 05_table_operations_list.sql
    |── 06_table_operations.sql
    |── 07_views.sql
    |── 08_functions_triggers.sql
    |── README.md

```

## Installazione

    > NOTA
    >
    > Gli script non contengono **CREATE DATABASE**, per permettere flessibilità negli ambienti di sviluppo.
    > Dovrà preliminarmente essere creato il database.
    > Esempio **CREATE DATABASE** toponomastica`.

Esegui gli script contenuti nei file **.sql**


