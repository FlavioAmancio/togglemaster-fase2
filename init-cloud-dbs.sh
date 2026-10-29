#!/bin/bash
set -e

# Garante que o cliente psql esteja instalado no seu Ubuntu
if ! command -v psql &> /dev/null; then
    echo "Instalando postgresql-client..."
    sudo apt update && sudo apt install -y postgresql-client
fi

export PGPASSWORD="ToggleMaster2024!"

echo "================================================================"
echo "💉 INICIALIZANDO TABELAS NOS BANCOS RDS DA AWS"
echo "================================================================"

# 1. Auth DB
echo "1/3 -> Criando tabelas no auth-db..."
psql -h auth-db.cb2bxp6qijl7.us-east-1.rds.amazonaws.com \
     -U postgres \
     -d auth_db \
     -f ./auth-service/db/init.sql

# 2. Flag DB
echo "2/3 -> Criando tabelas no flag-db..."
psql -h flag-db.cb2bxp6qijl7.us-east-1.rds.amazonaws.com \
     -U postgres \
     -d flags_db \
     -f ./flag-service/db/init.sql

# 3. Targeting DB
echo "3/3 -> Criando tabelas no targeting-db..."
psql -h targeting-db.cb2bxp6qijl7.us-east-1.rds.amazonaws.com \
     -U postgres \
     -d targeting_db \
     -f ./targeting-service/db/init.sql

echo "================================================================"
echo "✅ TODAS AS TABELAS FORAM CRIADAS COM SUCESSO NOS BANCOS DA NUVEM!"
echo "================================================================"