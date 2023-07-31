SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS de;

CREATE DATABASE de WITH
  OWNER = derole
  TEMPLATE = template0
  ENCODING = 'UTF8'
  LC_COLLATE = 'pt_BR.utf8'
  LC_CTYPE = 'pt_BR.utf8'
  CONNECTION LIMIT = -1;

\connect de

ALTER DATABASE de SET lc_time TO 'pt_BR.utf8';
ALTER DATABASE de SET lc_monetary TO 'pt_BR.utf8';
ALTER DATABASE de SET lc_numeric TO 'pt_BR.utf8';
ALTER DATABASE de SET lc_messages TO 'pt_BR.utf8';
