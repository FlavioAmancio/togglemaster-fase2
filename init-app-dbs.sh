#!/bin/bash
set -e

# Cria os dois bancos de dados adicionais
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE flags_db;
    CREATE DATABASE targeting_db;
EOSQL

# Roda o init.sql do flag-service no flags_db
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "flags_db" -f /docker-entrypoint-initdb.d/flag-init.sql

# Roda o init.sql do targeting-service no targeting_db
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "targeting_db" -f /docker-entrypoint-initdb.d/targeting-init.sql