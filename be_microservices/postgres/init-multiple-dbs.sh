#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE DATABASE mss_auth;
  CREATE DATABASE mss_billing;
  CREATE DATABASE mss_facility;
  CREATE DATABASE mss_security;
  CREATE DATABASE mss_operations;
EOSQL
