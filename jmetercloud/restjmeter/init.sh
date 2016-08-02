#!/bin/bash
#!set -e

psql -v ON_ERROR_STOP=1 -U postgres <<-EOSQL
    CREATE DATABASE restjmeter;
    GRANT ALL PRIVILEGES ON DATABASE restjmeter TO postgres;
EOSQL

psql -v ON_ERROR_STOP=1 -U postgres -d restjmeter <<-EOSQL
    CREATE TABLE jmeter_aggregate_report(
  id serial NOT NULL,
  testid character varying NOT NULL,
  time_stamp integer NOT NULL,
  label character varying NOT NULL,
  samples integer NOT NULL,
  average integer NOT NULL,
  median integer NOT NULL,
  perc90_line integer NOT NULL,
  perc95_line integer,
  perc99_line integer,
  min integer NOT NULL,
  max integer NOT NULL,
  error_rate double precision DEFAULT 0,
  throughput double precision,
  kb_per_sec double precision,
  CONSTRAINT jmeter_aggregate_report_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE jmeter_aggregate_report
  OWNER TO postgres;

  CREATE TABLE jmeter_jmx_log
(
  id serial NOT NULL,
  testid character varying NOT NULL,
  status character varying NOT NULL,
  time_stamp integer NOT NULL,
  jmx_content character varying,
  CONSTRAINT jmeter_jmx_log_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE jmeter_jmx_log
  OWNER TO postgres;
EOSQL