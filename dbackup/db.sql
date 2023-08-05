--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3 (Ubuntu 15.3-1.pgdg23.04+1)
-- Dumped by pg_dump version 15.3 (Ubuntu 15.3-1.pgdg23.04+1)

-- Started on 2023-08-05 08:48:27 -03

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
--
-- TOC entry 3722 (class 1262 OID 38562)
-- Name: de; Type: DATABASE; Schema: -; Owner: derole
--

CREATE DATABASE de WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE de OWNER TO derole;

\connect de

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

--
-- TOC entry 3723 (class 0 OID 0)
-- Name: de; Type: DATABASE PROPERTIES; Schema: -; Owner: derole
--

ALTER DATABASE de SET lc_time TO 'pt_BR.utf8';
ALTER DATABASE de SET lc_monetary TO 'pt_BR.utf8';
ALTER DATABASE de SET lc_numeric TO 'pt_BR.utf8';
ALTER DATABASE de SET lc_messages TO 'pt_BR.utf8';


\connect de

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

--
-- TOC entry 6 (class 2615 OID 38563)
-- Name: accounting; Type: SCHEMA; Schema: -; Owner: derole
--

CREATE SCHEMA accounting;


ALTER SCHEMA accounting OWNER TO derole;

--
-- TOC entry 7 (class 2615 OID 38564)
-- Name: auth; Type: SCHEMA; Schema: -; Owner: derole
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO derole;

--
-- TOC entry 8 (class 2615 OID 38565)
-- Name: entities; Type: SCHEMA; Schema: -; Owner: derole
--

CREATE SCHEMA entities;


ALTER SCHEMA entities OWNER TO derole;

--
-- TOC entry 10 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 9 (class 2615 OID 38566)
-- Name: syslogic; Type: SCHEMA; Schema: -; Owner: derole
--

CREATE SCHEMA syslogic;


ALTER SCHEMA syslogic OWNER TO derole;

--
-- TOC entry 2 (class 3079 OID 38567)
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- TOC entry 3725 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


--
-- TOC entry 340 (class 1255 OID 38752)
-- Name: sync_bas_all_columns_trigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_bas_all_columns_trigger() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    -- The INSERT operation is used to add any new columns to the bas_all_columns table
    -- This is achieved by selecting from information_schema.columns (src) and left joining with bas_all_columns (tgt)
    -- The WHERE clause filters to only include columns in the specified schemas, and where the column does not already exist in bas_all_columns
    -- The ORDER BY clause orders the results by schema name and table name, although this has no impact on the final state of bas_all_columns
    
    INSERT INTO syslogic.bas_all_columns (sch_name, tab_name, col_name, text_id,data_type)
    SELECT src.table_schema, src.table_name, src.column_name,
        src.table_schema || '.' || src.table_name || '.' || src.column_name,
        src.data_type
    FROM information_schema.columns AS src
    LEFT JOIN syslogic.bas_all_columns AS tgt
    ON src.table_schema || '.' || src.table_name || '.' || src.column_name = tgt.text_id
    WHERE (src.table_schema='accounting'
        OR src.table_schema='auth'
        OR src.table_schema='entities'
        OR src.table_schema='syslogic')
        AND tgt.text_id IS NULL
    ORDER BY src.table_schema ASC, src.table_name ASC;

    -- The DELETE operation is used to remove any columns from bas_all_columns that no longer exist in the database
    -- This is achieved by selecting from bas_all_columns (bas) where there is not a corresponding record in information_schema.columns
    -- Again, the WHERE clause filters to only include columns in the specified schemas
    DELETE FROM syslogic.bas_all_columns
    WHERE text_id IN (
        SELECT text_id
        FROM syslogic.bas_all_columns bas
        WHERE NOT EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE (table_schema || '.' || table_name || '.' || column_name) = bas.text_id
            AND table_schema IN ('accounting', 'auth', 'entities', 'syslogic')
        )
    );
END;
$$;


ALTER FUNCTION public.sync_bas_all_columns_trigger() OWNER TO postgres;

--
-- TOC entry 341 (class 1255 OID 38753)
-- Name: delete_bas_data_dic(); Type: FUNCTION; Schema: syslogic; Owner: postgres
--

CREATE FUNCTION syslogic.delete_bas_data_dic() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM syslogic.bas_data_dic
    WHERE col_id = OLD.text_id;
    RETURN OLD;
END;
$$;


ALTER FUNCTION syslogic.delete_bas_data_dic() OWNER TO postgres;

--
-- TOC entry 342 (class 1255 OID 38754)
-- Name: insert_bas_data_dic(); Type: FUNCTION; Schema: syslogic; Owner: postgres
--

CREATE FUNCTION syslogic.insert_bas_data_dic() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO syslogic.bas_data_dic(col_id, en_us, pt_br,def_class,def_name)
    VALUES (NEW.text_id, NEW.col_name, NEW.col_name,'1','Column ' || NEW.text_id);
    RETURN NEW;
END;
$$;


ALTER FUNCTION syslogic.insert_bas_data_dic() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 38755)
-- Name: bas_acc_chart; Type: TABLE; Schema: accounting; Owner: derole
--

CREATE TABLE accounting.bas_acc_chart (
    acc_id integer NOT NULL,
    acc_name text NOT NULL,
    init_balance numeric(20,2) DEFAULT 0 NOT NULL,
    balance numeric(20,2) DEFAULT 0 NOT NULL,
    inactive boolean DEFAULT false NOT NULL,
    tree_id public.ltree
);


ALTER TABLE accounting.bas_acc_chart OWNER TO derole;

--
-- TOC entry 3726 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE bas_acc_chart; Type: COMMENT; Schema: accounting; Owner: derole
--

COMMENT ON TABLE accounting.bas_acc_chart IS 'Rules:

    It is prohibited to change the first level of the account. An account belonging to an asset must remain as it is and cannot be altered with the code of the first level, such as using the number 1, for example. The same applies to other accounts: the first level of the code cannot be changed.
    It is prohibited to delete the level 1 of any account.
    It is prohibited to create any account with only the first level (creating new trees is forbidden).
    It is prohibited to update an account in a way that it becomes a descendant of itself.';


--
-- TOC entry 220 (class 1259 OID 38763)
-- Name: bas_acc_chart_acc_id_seq; Type: SEQUENCE; Schema: accounting; Owner: derole
--

CREATE SEQUENCE accounting.bas_acc_chart_acc_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE accounting.bas_acc_chart_acc_id_seq OWNER TO derole;

--
-- TOC entry 3727 (class 0 OID 0)
-- Dependencies: 220
-- Name: bas_acc_chart_acc_id_seq; Type: SEQUENCE OWNED BY; Schema: accounting; Owner: derole
--

ALTER SEQUENCE accounting.bas_acc_chart_acc_id_seq OWNED BY accounting.bas_acc_chart.acc_id;


--
-- TOC entry 221 (class 1259 OID 38764)
-- Name: eve_acc_entries; Type: TABLE; Schema: accounting; Owner: derole
--

CREATE TABLE accounting.eve_acc_entries (
    entry_id integer NOT NULL,
    debit numeric(20,2) DEFAULT 0 NOT NULL,
    credit numeric(20,2) NOT NULL,
    bus_trans_id integer NOT NULL,
    acc_id integer NOT NULL
);


ALTER TABLE accounting.eve_acc_entries OWNER TO derole;

--
-- TOC entry 222 (class 1259 OID 38768)
-- Name: eve_acc_entries_entry_id_seq; Type: SEQUENCE; Schema: accounting; Owner: derole
--

CREATE SEQUENCE accounting.eve_acc_entries_entry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE accounting.eve_acc_entries_entry_id_seq OWNER TO derole;

--
-- TOC entry 3728 (class 0 OID 0)
-- Dependencies: 222
-- Name: eve_acc_entries_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: accounting; Owner: derole
--

ALTER SEQUENCE accounting.eve_acc_entries_entry_id_seq OWNED BY accounting.eve_acc_entries.entry_id;


--
-- TOC entry 223 (class 1259 OID 38769)
-- Name: eve_bus_transactions; Type: TABLE; Schema: accounting; Owner: derole
--

CREATE TABLE accounting.eve_bus_transactions (
    trans_id integer NOT NULL,
    trans_date date DEFAULT (CURRENT_TIMESTAMP)::timestamp without time zone NOT NULL,
    occur_date date DEFAULT (CURRENT_TIMESTAMP)::timestamp without time zone NOT NULL,
    entity_id integer DEFAULT 0 NOT NULL,
    trans_value numeric(20,2) DEFAULT 0 NOT NULL,
    memo text
);


ALTER TABLE accounting.eve_bus_transactions OWNER TO derole;

--
-- TOC entry 224 (class 1259 OID 38778)
-- Name: eve_bus_transactions_trans_id_seq; Type: SEQUENCE; Schema: accounting; Owner: derole
--

CREATE SEQUENCE accounting.eve_bus_transactions_trans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE accounting.eve_bus_transactions_trans_id_seq OWNER TO derole;

--
-- TOC entry 3729 (class 0 OID 0)
-- Dependencies: 224
-- Name: eve_bus_transactions_trans_id_seq; Type: SEQUENCE OWNED BY; Schema: accounting; Owner: derole
--

ALTER SEQUENCE accounting.eve_bus_transactions_trans_id_seq OWNED BY accounting.eve_bus_transactions.trans_id;


--
-- TOC entry 225 (class 1259 OID 38779)
-- Name: bas_entities; Type: TABLE; Schema: entities; Owner: derole
--

CREATE TABLE entities.bas_entities (
    entity_id integer NOT NULL,
    entity_name text NOT NULL,
    entity_parent integer,
    entity_password text,
    email text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE entities.bas_entities OWNER TO derole;

--
-- TOC entry 3730 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE bas_entities; Type: COMMENT; Schema: entities; Owner: derole
--

COMMENT ON TABLE entities.bas_entities IS 'Descrição: Essa tabela armazena as informações básicas das entidades (usuários) registradas no sistema, como nome, email, senha e data de criação.

Integração: A tabela é a principal tabela de entidades do sistema e é referenciada por outras tabelas, como auth.eve_access_tokens e auth.bas_permissions, por meio da chave primária id.

Exemplos de uso: A tabela é utilizada para armazenar e gerenciar as informações básicas de cada entidade (usuário) registrada no sistema. Ela serve como base para a autenticação, autorização e outras funcionalidades relacionadas aos usuários.';


--
-- TOC entry 226 (class 1259 OID 38785)
-- Name: vw_eve_acc_entries; Type: VIEW; Schema: accounting; Owner: derole
--

CREATE VIEW accounting.vw_eve_acc_entries AS
 SELECT child.bus_trans_id AS parent_id,
    child.entry_id,
    parent.trans_date,
    parent.occur_date,
    parent.memo,
    child.debit,
    child.credit,
    child.acc_id,
    parent.entity_id,
    acc.acc_name,
    entt.entity_name
   FROM (((accounting.eve_acc_entries child
     JOIN accounting.eve_bus_transactions parent ON ((child.bus_trans_id = parent.trans_id)))
     JOIN accounting.bas_acc_chart acc ON ((child.acc_id = acc.acc_id)))
     JOIN entities.bas_entities entt ON ((parent.entity_id = entt.entity_id)));


ALTER TABLE accounting.vw_eve_acc_entries OWNER TO derole;

--
-- TOC entry 227 (class 1259 OID 38790)
-- Name: bas_permissions; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.bas_permissions (
    permission_id integer NOT NULL,
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE auth.bas_permissions OWNER TO derole;

--
-- TOC entry 3731 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE bas_permissions; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.bas_permissions IS 'Descrição: Essa tabela representa as permissões atribuídas a uma entidade (usuário) específica em relação a determinados recursos ou funcionalidades do sistema.

Integração: A tabela possui duas chaves estrangeiras: entity_id, que referencia a tabela entities.bas_entities, e role_id, que referencia a tabela entities.bas_roles. Isso permite relacionar uma entidade a um papel específico e, assim, determinar suas permissões.

Exemplos de uso: A tabela é utilizada para gerenciar as permissões de cada entidade (usuário) em relação a recursos ou funcionalidades específicas do sistema. Com base nas permissões atribuídas, é possível controlar o acesso dos usuários a determinadas partes do sistema.';


--
-- TOC entry 228 (class 1259 OID 38794)
-- Name: bas_permissions_permission_id_seq; Type: SEQUENCE; Schema: auth; Owner: derole
--

CREATE SEQUENCE auth.bas_permissions_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE auth.bas_permissions_permission_id_seq OWNER TO derole;

--
-- TOC entry 3732 (class 0 OID 0)
-- Dependencies: 228
-- Name: bas_permissions_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_permissions_permission_id_seq OWNED BY auth.bas_permissions.permission_id;


--
-- TOC entry 229 (class 1259 OID 38795)
-- Name: bas_roles; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.bas_roles (
    role_id integer NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE auth.bas_roles OWNER TO derole;

--
-- TOC entry 3733 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE bas_roles; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.bas_roles IS 'Descrição: Essa tabela armazena os diferentes papéis ou funções atribuídos aos usuários do sistema.

Integração: A tabela é referenciada pela tabela auth.bas_permissions por meio da chave primária id, permitindo que cada permissão seja associada a um papel específico.

Exemplos de uso: A tabela é utilizada para definir e gerenciar os papéis disponíveis no sistema. Os papéis podem ter diferentes níveis de autoridade e acesso, permitindo controlar quais recursos e funcionalidades os usuários podem acessar com base no papel atribuído a eles.';


--
-- TOC entry 230 (class 1259 OID 38800)
-- Name: bas_roles_role_id_seq; Type: SEQUENCE; Schema: auth; Owner: derole
--

CREATE SEQUENCE auth.bas_roles_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE auth.bas_roles_role_id_seq OWNER TO derole;

--
-- TOC entry 3734 (class 0 OID 0)
-- Dependencies: 230
-- Name: bas_roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_roles_role_id_seq OWNED BY auth.bas_roles.role_id;


--
-- TOC entry 231 (class 1259 OID 38801)
-- Name: bas_table_permissions; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.bas_table_permissions (
    tpermission_id integer NOT NULL,
    table_id integer NOT NULL,
    role_id integer NOT NULL,
    can_read boolean NOT NULL,
    can_write boolean NOT NULL,
    can_delete boolean NOT NULL
);


ALTER TABLE auth.bas_table_permissions OWNER TO derole;

--
-- TOC entry 232 (class 1259 OID 38804)
-- Name: bas_table_permissions_tpermission_id_seq; Type: SEQUENCE; Schema: auth; Owner: derole
--

CREATE SEQUENCE auth.bas_table_permissions_tpermission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auth.bas_table_permissions_tpermission_id_seq OWNER TO derole;

--
-- TOC entry 3735 (class 0 OID 0)
-- Dependencies: 232
-- Name: bas_table_permissions_tpermission_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_table_permissions_tpermission_id_seq OWNED BY auth.bas_table_permissions.tpermission_id;


--
-- TOC entry 233 (class 1259 OID 38805)
-- Name: bas_tables; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.bas_tables (
    table_id integer NOT NULL,
    table_name text NOT NULL
);


ALTER TABLE auth.bas_tables OWNER TO derole;

--
-- TOC entry 234 (class 1259 OID 38810)
-- Name: bas_tables_table_id_seq; Type: SEQUENCE; Schema: auth; Owner: derole
--

CREATE SEQUENCE auth.bas_tables_table_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auth.bas_tables_table_id_seq OWNER TO derole;

--
-- TOC entry 3736 (class 0 OID 0)
-- Dependencies: 234
-- Name: bas_tables_table_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_tables_table_id_seq OWNED BY auth.bas_tables.table_id;


--
-- TOC entry 235 (class 1259 OID 38811)
-- Name: bas_users; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.bas_users (
    user_id integer NOT NULL,
    user_name text NOT NULL,
    user_password text NOT NULL,
    email text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auth.bas_users OWNER TO derole;

--
-- TOC entry 3737 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE bas_users; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.bas_users IS 'Descrição: Essa tabela armazena as informações básicas das entidades (usuários) registradas no sistema, como nome, email, senha e data de criação.
Integração: A tabela é a principal tabela de entidades do sistema e é referenciada por outras tabelas, como auth.eve_access_tokens e auth.bas_permissions, por meio da chave primária id.
Exemplos de uso: A tabela é utilizada para armazenar e gerenciar as informações básicas de cada entidade (usuário) registrada no sistema. Ela serve como base para a autenticação, autorização e outras funcionalidades relacionadas aos usuários.';


--
-- TOC entry 236 (class 1259 OID 38817)
-- Name: bas_users_user_id_seq; Type: SEQUENCE; Schema: auth; Owner: derole
--

CREATE SEQUENCE auth.bas_users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auth.bas_users_user_id_seq OWNER TO derole;

--
-- TOC entry 3738 (class 0 OID 0)
-- Dependencies: 236
-- Name: bas_users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_users_user_id_seq OWNED BY auth.bas_users.user_id;


--
-- TOC entry 237 (class 1259 OID 38818)
-- Name: eve_access_tokens; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.eve_access_tokens (
    token_id integer NOT NULL,
    token text NOT NULL,
    user_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auth.eve_access_tokens OWNER TO derole;

--
-- TOC entry 3739 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE eve_access_tokens; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.eve_access_tokens IS 'Descrição: Esta tabela armazena os tokens de acesso gerados para autenticar e autorizar as entidades (usuários) no sistema.

Integração: A tabela possui uma chave estrangeira user_id que referencia a tabela entities.bas_entities, estabelecendo uma relação entre o token de acesso e o usuário associado.

Exemplos de uso: A tabela é utilizada para armazenar e validar os tokens de acesso durante o processo de autenticação. É possível consultar essa tabela para verificar se um token de acesso é válido e obter o ID do usuário correspondente.';


--
-- TOC entry 238 (class 1259 OID 38824)
-- Name: eve_access_tokens_token_id_seq; Type: SEQUENCE; Schema: auth; Owner: derole
--

CREATE SEQUENCE auth.eve_access_tokens_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE auth.eve_access_tokens_token_id_seq OWNER TO derole;

--
-- TOC entry 3740 (class 0 OID 0)
-- Dependencies: 238
-- Name: eve_access_tokens_token_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.eve_access_tokens_token_id_seq OWNED BY auth.eve_access_tokens.token_id;


--
-- TOC entry 239 (class 1259 OID 38825)
-- Name: eve_audit_log; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.eve_audit_log (
    log_id integer NOT NULL,
    user_id integer NOT NULL,
    activity text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE auth.eve_audit_log OWNER TO derole;

--
-- TOC entry 3741 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE eve_audit_log; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.eve_audit_log IS 'Descrição: Esta tabela registra as atividades e ações realizadas no sistema, permitindo rastrear e auditar as operações.
Integração: A tabela possui uma chave estrangeira entity_id que referencia a tabela entities.bas_entities, permitindo relacionar uma atividade registrada com a entidade (usuário) associada à ação.
Exemplos de uso: A tabela é utilizada para registrar informações relevantes sobre atividades específicas, como criação, atualização ou exclusão de registros. Isso permite acompanhar as alterações feitas no sistema e, se necessário, identificar as entidades (usuários) envolvidas nas ações.';


--
-- TOC entry 240 (class 1259 OID 38831)
-- Name: eve_audit_log_log_id_seq; Type: SEQUENCE; Schema: auth; Owner: derole
--

CREATE SEQUENCE auth.eve_audit_log_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE auth.eve_audit_log_log_id_seq OWNER TO derole;

--
-- TOC entry 3742 (class 0 OID 0)
-- Dependencies: 240
-- Name: eve_audit_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.eve_audit_log_log_id_seq OWNED BY auth.eve_audit_log.log_id;


--
-- TOC entry 241 (class 1259 OID 38832)
-- Name: eve_refresh_tokens; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.eve_refresh_tokens (
    rtoken_id integer NOT NULL,
    token text NOT NULL,
    user_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auth.eve_refresh_tokens OWNER TO derole;

--
-- TOC entry 3743 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE eve_refresh_tokens; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.eve_refresh_tokens IS 'Descrição: Essa tabela armazena os tokens de atualização usados para renovar os tokens de acesso expirados sem a necessidade de fazer login novamente.

Integração: A tabela possui uma chave estrangeira user_id que referencia a tabela entities.bas_entities, estabelecendo uma relação entre o token de atualização e o usuário associado.

Exemplos de uso: Durante o processo de renovação do token de acesso, a tabela é consultada para verificar se um token de atualização é válido e obter o ID do usuário correspondente. Com base nessas informações, um novo token de acesso pode ser emitido.';


--
-- TOC entry 242 (class 1259 OID 38838)
-- Name: eve_refresh_tokens_rtoken_id_seq; Type: SEQUENCE; Schema: auth; Owner: derole
--

CREATE SEQUENCE auth.eve_refresh_tokens_rtoken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE auth.eve_refresh_tokens_rtoken_id_seq OWNER TO derole;

--
-- TOC entry 3744 (class 0 OID 0)
-- Dependencies: 242
-- Name: eve_refresh_tokens_rtoken_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.eve_refresh_tokens_rtoken_id_seq OWNED BY auth.eve_refresh_tokens.rtoken_id;


--
-- TOC entry 243 (class 1259 OID 38839)
-- Name: bas_entities_entity_id_seq; Type: SEQUENCE; Schema: entities; Owner: derole
--

CREATE SEQUENCE entities.bas_entities_entity_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities.bas_entities_entity_id_seq OWNER TO derole;

--
-- TOC entry 3745 (class 0 OID 0)
-- Dependencies: 243
-- Name: bas_entities_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: derole
--

ALTER SEQUENCE entities.bas_entities_entity_id_seq OWNED BY entities.bas_entities.entity_id;


--
-- TOC entry 244 (class 1259 OID 38840)
-- Name: todos; Type: TABLE; Schema: public; Owner: derole
--

CREATE TABLE public.todos (
    id integer NOT NULL,
    text text NOT NULL,
    done boolean DEFAULT false NOT NULL
);


ALTER TABLE public.todos OWNER TO derole;

--
-- TOC entry 245 (class 1259 OID 38846)
-- Name: todos_id_seq; Type: SEQUENCE; Schema: public; Owner: derole
--

CREATE SEQUENCE public.todos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.todos_id_seq OWNER TO derole;

--
-- TOC entry 3746 (class 0 OID 0)
-- Dependencies: 245
-- Name: todos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: derole
--

ALTER SEQUENCE public.todos_id_seq OWNED BY public.todos.id;


--
-- TOC entry 246 (class 1259 OID 38847)
-- Name: bas_all_columns; Type: TABLE; Schema: syslogic; Owner: derole
--

CREATE TABLE syslogic.bas_all_columns (
    text_id text NOT NULL,
    sch_name text NOT NULL,
    tab_name text NOT NULL,
    col_name text NOT NULL,
    show_front_end boolean DEFAULT true NOT NULL,
    data_type text
);


ALTER TABLE syslogic.bas_all_columns OWNER TO derole;

--
-- TOC entry 247 (class 1259 OID 38853)
-- Name: bas_data_dic; Type: TABLE; Schema: syslogic; Owner: derole
--

CREATE TABLE syslogic.bas_data_dic (
    def_id integer NOT NULL,
    def_name text,
    def_class integer,
    col_id text,
    en_us text,
    pt_br text,
    on_allowed_language_list boolean
);


ALTER TABLE syslogic.bas_data_dic OWNER TO derole;

--
-- TOC entry 3747 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE bas_data_dic; Type: COMMENT; Schema: syslogic; Owner: derole
--

COMMENT ON TABLE syslogic.bas_data_dic IS 'Data Dictionary';


--
-- TOC entry 248 (class 1259 OID 38858)
-- Name: bas_data_dic_class; Type: TABLE; Schema: syslogic; Owner: derole
--

CREATE TABLE syslogic.bas_data_dic_class (
    class_id integer NOT NULL,
    class_name text NOT NULL,
    "Description" text
);


ALTER TABLE syslogic.bas_data_dic_class OWNER TO derole;

--
-- TOC entry 249 (class 1259 OID 38863)
-- Name: bas_data_dic_class_class_id_seq; Type: SEQUENCE; Schema: syslogic; Owner: derole
--

CREATE SEQUENCE syslogic.bas_data_dic_class_class_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE syslogic.bas_data_dic_class_class_id_seq OWNER TO derole;

--
-- TOC entry 3748 (class 0 OID 0)
-- Dependencies: 249
-- Name: bas_data_dic_class_class_id_seq; Type: SEQUENCE OWNED BY; Schema: syslogic; Owner: derole
--

ALTER SEQUENCE syslogic.bas_data_dic_class_class_id_seq OWNED BY syslogic.bas_data_dic_class.class_id;


--
-- TOC entry 250 (class 1259 OID 38864)
-- Name: bas_data_dic_def_id_seq; Type: SEQUENCE; Schema: syslogic; Owner: derole
--

CREATE SEQUENCE syslogic.bas_data_dic_def_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE syslogic.bas_data_dic_def_id_seq OWNER TO derole;

--
-- TOC entry 3749 (class 0 OID 0)
-- Dependencies: 250
-- Name: bas_data_dic_def_id_seq; Type: SEQUENCE OWNED BY; Schema: syslogic; Owner: derole
--

ALTER SEQUENCE syslogic.bas_data_dic_def_id_seq OWNED BY syslogic.bas_data_dic.def_id;


--
-- TOC entry 3469 (class 2604 OID 38960)
-- Name: bas_acc_chart acc_id; Type: DEFAULT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.bas_acc_chart ALTER COLUMN acc_id SET DEFAULT nextval('accounting.bas_acc_chart_acc_id_seq'::regclass);


--
-- TOC entry 3473 (class 2604 OID 38961)
-- Name: eve_acc_entries entry_id; Type: DEFAULT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_acc_entries ALTER COLUMN entry_id SET DEFAULT nextval('accounting.eve_acc_entries_entry_id_seq'::regclass);


--
-- TOC entry 3475 (class 2604 OID 38962)
-- Name: eve_bus_transactions trans_id; Type: DEFAULT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_bus_transactions ALTER COLUMN trans_id SET DEFAULT nextval('accounting.eve_bus_transactions_trans_id_seq'::regclass);


--
-- TOC entry 3482 (class 2604 OID 38963)
-- Name: bas_permissions permission_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_permissions ALTER COLUMN permission_id SET DEFAULT nextval('auth.bas_permissions_permission_id_seq'::regclass);


--
-- TOC entry 3484 (class 2604 OID 38964)
-- Name: bas_roles role_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_roles ALTER COLUMN role_id SET DEFAULT nextval('auth.bas_roles_role_id_seq'::regclass);


--
-- TOC entry 3485 (class 2604 OID 38965)
-- Name: bas_table_permissions tpermission_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions ALTER COLUMN tpermission_id SET DEFAULT nextval('auth.bas_table_permissions_tpermission_id_seq'::regclass);


--
-- TOC entry 3486 (class 2604 OID 38966)
-- Name: bas_tables table_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_tables ALTER COLUMN table_id SET DEFAULT nextval('auth.bas_tables_table_id_seq'::regclass);


--
-- TOC entry 3487 (class 2604 OID 38967)
-- Name: bas_users user_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_users ALTER COLUMN user_id SET DEFAULT nextval('auth.bas_users_user_id_seq'::regclass);


--
-- TOC entry 3489 (class 2604 OID 38968)
-- Name: eve_access_tokens token_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_access_tokens ALTER COLUMN token_id SET DEFAULT nextval('auth.eve_access_tokens_token_id_seq'::regclass);


--
-- TOC entry 3491 (class 2604 OID 38969)
-- Name: eve_audit_log log_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_audit_log ALTER COLUMN log_id SET DEFAULT nextval('auth.eve_audit_log_log_id_seq'::regclass);


--
-- TOC entry 3493 (class 2604 OID 38970)
-- Name: eve_refresh_tokens rtoken_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_refresh_tokens ALTER COLUMN rtoken_id SET DEFAULT nextval('auth.eve_refresh_tokens_rtoken_id_seq'::regclass);


--
-- TOC entry 3480 (class 2604 OID 38971)
-- Name: bas_entities entity_id; Type: DEFAULT; Schema: entities; Owner: derole
--

ALTER TABLE ONLY entities.bas_entities ALTER COLUMN entity_id SET DEFAULT nextval('entities.bas_entities_entity_id_seq'::regclass);


--
-- TOC entry 3495 (class 2604 OID 38972)
-- Name: todos id; Type: DEFAULT; Schema: public; Owner: derole
--

ALTER TABLE ONLY public.todos ALTER COLUMN id SET DEFAULT nextval('public.todos_id_seq'::regclass);


--
-- TOC entry 3498 (class 2604 OID 38973)
-- Name: bas_data_dic def_id; Type: DEFAULT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_data_dic ALTER COLUMN def_id SET DEFAULT nextval('syslogic.bas_data_dic_def_id_seq'::regclass);


--
-- TOC entry 3499 (class 2604 OID 38974)
-- Name: bas_data_dic_class class_id; Type: DEFAULT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_data_dic_class ALTER COLUMN class_id SET DEFAULT nextval('syslogic.bas_data_dic_class_class_id_seq'::regclass);


--
-- TOC entry 3686 (class 0 OID 38755)
-- Dependencies: 219
-- Data for Name: bas_acc_chart; Type: TABLE DATA; Schema: accounting; Owner: derole
--

COPY accounting.bas_acc_chart (acc_id, acc_name, init_balance, balance, inactive, tree_id) FROM stdin;
1	Root	0.00	0.00	f	0
2	Ativo	0.00	0.00	f	0.1
3	Passivo	0.00	0.00	f	0.2
4	Receitas	0.00	0.00	f	0.3
5	Despesas	0.00	0.00	f	0.4
6	Patrimônio Líquido	0.00	0.00	f	0.5
7	Ativo Circulante	0.00	0.00	f	0.1.001
8	Ativo Não Circulante	0.00	0.00	f	0.1.002
9	Passivo Circulante	0.00	0.00	f	0.2.001
10	Passivo Não Circulante	0.00	0.00	f	0.2.002
11	Receitas Operacionais	0.00	0.00	f	0.3.001
12	Receitas Não Operacionais	0.00	0.00	f	0.3.002
13	Despesas Operacionais	0.00	0.00	f	0.4.001
14	Despesas Não Operacionais	0.00	0.00	f	0.4.002
15	Capital Social	0.00	0.00	f	0.5.001
16	Reservas de Lucros	0.00	0.00	f	0.5.002
17	Caixa	0.00	0.00	f	0.1.001.001
18	Bancos Conta Movimento	0.00	0.00	f	0.1.001.002
19	Aplicações Financeiras	0.00	0.00	f	0.1.001.003
20	Contas a Receber	0.00	0.00	f	0.1.001.004
21	Estoque	0.00	0.00	f	0.1.001.005
22	Imobilizado	0.00	0.00	f	0.1.002.001
23	Investimentos	0.00	0.00	f	0.1.002.002
24	Fornecedores	0.00	0.00	f	0.2.001.001
25	Salários a Pagar	0.00	0.00	f	0.2.001.002
26	Impostos a Pagar	0.00	0.00	f	0.2.001.003
27	Empréstimos a Pagar	0.00	0.00	f	0.2.002.001
28	Financiamentos	0.00	0.00	f	0.2.002.002
29	Venda de Produtos	0.00	0.00	f	0.3.001.001
30	Venda de Serviços	0.00	0.00	f	0.3.001.002
31	Receita Financeira	0.00	0.00	f	0.3.002.001
32	Custo dos Produtos Vendidos	0.00	0.00	f	0.4.001.001
33	Despesas com Vendas	0.00	0.00	f	0.4.001.002
34	Despesas Administrativas	0.00	0.00	f	0.4.001.003
35	Despesas Financeiras	0.00	0.00	f	0.4.002.001
36	Reservas de Capital	0.00	0.00	f	0.5.002.001
37	Lucros Acumulados	0.00	0.00	f	0.5.002.002
38	Banco do Brasil	0.00	0.00	f	0.1.001.002.001
39	Caixa Econômica	0.00	0.00	f	0.1.001.002.002
40	Santander	0.00	0.00	f	0.1.001.002.003
41	Bradesco	0.00	0.00	f	0.1.001.002.004
42	Itaú	0.00	0.00	f	0.1.001.002.005
43	Material de Escritório	0.00	0.00	f	0.4.001.003.001
44	Lanches	0.00	0.00	f	0.4.001.003.002
45	Produtos de Limpeza	0.00	0.00	f	0.4.001.003.003
46	Salários e Ordenados	0.00	0.00	f	0.4.001.003.004
47	Aluguéis	0.00	0.00	f	0.4.001.003.005
48	Energia Elétrica	0.00	0.00	f	0.4.001.003.006
49	Água	0.00	0.00	f	0.4.001.003.007
50	Internet	0.00	0.00	f	0.4.001.003.008
51	Manutenção e Reparos	0.00	0.00	f	0.4.001.003.009
52	Depreciação	0.00	0.00	f	0.4.001.003.010
53	Viagens e Deslocamentos	0.00	0.00	f	0.4.001.003.011
54	Treinamentos	0.00	0.00	f	0.4.001.003.012
55	Impostos e Taxas	0.00	0.00	f	0.4.001.003.013
\.


--
-- TOC entry 3688 (class 0 OID 38764)
-- Dependencies: 221
-- Data for Name: eve_acc_entries; Type: TABLE DATA; Schema: accounting; Owner: derole
--

COPY accounting.eve_acc_entries (entry_id, debit, credit, bus_trans_id, acc_id) FROM stdin;
7	0.00	150.00	3	18
11	0.00	600.00	4	18
15	0.00	1000.00	5	18
25	400.00	0.00	8	13
26	200.00	0.00	8	22
27	0.00	400.00	8	18
28	0.00	200.00	8	27
5	150.00	0.00	3	33
9	600.00	0.00	4	22
13	1000.00	0.00	5	22
2	100.00	0.00	5	22
4	0.00	100.00	5	18
\.


--
-- TOC entry 3690 (class 0 OID 38769)
-- Dependencies: 223
-- Data for Name: eve_bus_transactions; Type: TABLE DATA; Schema: accounting; Owner: derole
--

COPY accounting.eve_bus_transactions (trans_id, trans_date, occur_date, entity_id, trans_value, memo) FROM stdin;
2	2023-07-05	2023-07-05	5	0.00	Licenciamento de software Microsoft Office para a equipe
3	2023-07-10	2023-07-10	6	0.00	Compra de anúncios no Google AdWords
4	2023-07-15	2023-07-15	7	0.00	Compra de servidores na Amazon AWS
5	2023-07-20	2023-07-20	8	0.00	Compra de iPhones para a equipe de vendas
8	2023-08-05	2023-08-05	11	0.00	Atualização do sistema IBM Watson
9	2023-08-10	2023-08-10	12	0.00	Licenciamento de software Adobe Creative Cloud para a equipe de design
10	2023-08-15	2023-08-15	13	0.00	Renovação de licenças Oracle Database
11	2023-08-20	2023-08-20	14	0.00	Despesas de viagem com Uber
14	2023-09-05	2023-09-05	17	0.00	Assinatura Spotify Premium para a equipe
17	2023-09-20	2023-09-20	20	0.00	Compra de produtos de limpeza Procter & Gamble
18	2023-09-25	2023-09-25	21	0.00	Compra de produtos de higiene pessoal Johnson & Johnson
\.


--
-- TOC entry 3693 (class 0 OID 38790)
-- Dependencies: 227
-- Data for Name: bas_permissions; Type: TABLE DATA; Schema: auth; Owner: derole
--

COPY auth.bas_permissions (permission_id, user_id, role_id, created_at) FROM stdin;
\.


--
-- TOC entry 3695 (class 0 OID 38795)
-- Dependencies: 229
-- Data for Name: bas_roles; Type: TABLE DATA; Schema: auth; Owner: derole
--

COPY auth.bas_roles (role_id, name, description) FROM stdin;
\.


--
-- TOC entry 3697 (class 0 OID 38801)
-- Dependencies: 231
-- Data for Name: bas_table_permissions; Type: TABLE DATA; Schema: auth; Owner: derole
--

COPY auth.bas_table_permissions (tpermission_id, table_id, role_id, can_read, can_write, can_delete) FROM stdin;
\.


--
-- TOC entry 3699 (class 0 OID 38805)
-- Dependencies: 233
-- Data for Name: bas_tables; Type: TABLE DATA; Schema: auth; Owner: derole
--

COPY auth.bas_tables (table_id, table_name) FROM stdin;
\.


--
-- TOC entry 3701 (class 0 OID 38811)
-- Dependencies: 235
-- Data for Name: bas_users; Type: TABLE DATA; Schema: auth; Owner: derole
--

COPY auth.bas_users (user_id, user_name, user_password, email, created_at) FROM stdin;
1	Frederico Sarmento	sdfhsdfg	sdfgsdfg	2023-07-08 14:47:03.503518
\.


--
-- TOC entry 3703 (class 0 OID 38818)
-- Dependencies: 237
-- Data for Name: eve_access_tokens; Type: TABLE DATA; Schema: auth; Owner: derole
--

COPY auth.eve_access_tokens (token_id, token, user_id, created_at) FROM stdin;
\.


--
-- TOC entry 3705 (class 0 OID 38825)
-- Dependencies: 239
-- Data for Name: eve_audit_log; Type: TABLE DATA; Schema: auth; Owner: derole
--

COPY auth.eve_audit_log (log_id, user_id, activity, created_at) FROM stdin;
\.


--
-- TOC entry 3707 (class 0 OID 38832)
-- Dependencies: 241
-- Data for Name: eve_refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: derole
--

COPY auth.eve_refresh_tokens (rtoken_id, token, user_id, created_at) FROM stdin;
\.


--
-- TOC entry 3692 (class 0 OID 38779)
-- Dependencies: 225
-- Data for Name: bas_entities; Type: TABLE DATA; Schema: entities; Owner: derole
--

COPY entities.bas_entities (entity_id, entity_name, entity_parent, entity_password, email, created_at) FROM stdin;
5	Microsoft	\N	\N	\N	2023-08-04 15:34:10.273656
6	Google	\N	\N	\N	2023-08-04 15:34:10.273656
7	Amazon	\N	\N	\N	2023-08-04 15:34:10.273656
8	Apple	\N	\N	\N	2023-08-04 15:34:10.273656
9	Facebook	\N	\N	\N	2023-08-04 15:34:10.273656
10	Intel	\N	\N	\N	2023-08-04 15:34:10.273656
11	IBM	\N	\N	\N	2023-08-04 15:34:10.273656
12	Adobe	\N	\N	\N	2023-08-04 15:34:10.273656
13	Oracle	\N	\N	\N	2023-08-04 15:34:10.273656
14	Uber	\N	\N	\N	2023-08-04 15:34:10.273656
15	Netflix	\N	\N	\N	2023-08-04 15:34:10.273656
16	Tesla	\N	\N	\N	2023-08-04 15:34:10.273656
17	Spotify	\N	\N	\N	2023-08-04 15:34:10.273656
18	Twitter	\N	\N	\N	2023-08-04 15:34:10.273656
19	Walmart	\N	\N	\N	2023-08-04 15:34:10.273656
20	Procter & Gamble	\N	\N	\N	2023-08-04 15:34:10.273656
21	Johnson & Johnson	\N	\N	\N	2023-08-04 15:34:10.273656
22	Unilever	\N	\N	\N	2023-08-04 15:34:10.273656
23	Pfizer	\N	\N	\N	2023-08-04 15:34:10.273656
24	General Motors	\N	\N	\N	2023-08-04 15:34:10.273656
25	Ford	\N	\N	\N	2023-08-04 15:34:10.273656
26	Boeing	\N	\N	\N	2023-08-04 15:34:10.273656
27	Coca-Cola	\N	\N	\N	2023-08-04 15:34:10.273656
28	PepsiCo	\N	\N	\N	2023-08-04 15:34:10.273656
29	Starbucks	\N	\N	\N	2023-08-04 15:34:10.273656
30	McDonald's	\N	\N	\N	2023-08-04 15:34:10.273656
31	Adidas	\N	\N	\N	2023-08-04 15:34:10.273656
32	Nike	\N	\N	\N	2023-08-04 15:34:10.273656
33	HSBC	\N	\N	\N	2023-08-04 15:34:10.273656
34	JP Morgan Chase	\N	\N	\N	2023-08-04 15:34:10.273656
\.


--
-- TOC entry 3710 (class 0 OID 38840)
-- Dependencies: 244
-- Data for Name: todos; Type: TABLE DATA; Schema: public; Owner: derole
--

COPY public.todos (id, text, done) FROM stdin;
17	maluco	f
18	beleza	f
19	tá foda	f
20	conseguir	f
\.


--
-- TOC entry 3712 (class 0 OID 38847)
-- Dependencies: 246
-- Data for Name: bas_all_columns; Type: TABLE DATA; Schema: syslogic; Owner: derole
--

COPY syslogic.bas_all_columns (text_id, sch_name, tab_name, col_name, show_front_end, data_type) FROM stdin;
accounting.bas_acc_chart.acc_id	accounting	bas_acc_chart	acc_id	t	smallint
accounting.bas_acc_chart.init_balance	accounting	bas_acc_chart	init_balance	t	numeric
accounting.bas_acc_chart.acc_name	accounting	bas_acc_chart	acc_name	t	text
accounting.bas_acc_chart.inactive	accounting	bas_acc_chart	inactive	t	boolean
accounting.bas_acc_chart.balance	accounting	bas_acc_chart	balance	t	numeric
auth.bas_permissions.permission_id	auth	bas_permissions	permission_id	t	integer
auth.bas_permissions.role_id	auth	bas_permissions	role_id	t	integer
auth.bas_permissions.user_id	auth	bas_permissions	user_id	t	integer
auth.bas_roles.description	auth	bas_roles	description	t	text
auth.bas_roles.name	auth	bas_roles	name	t	text
auth.bas_roles.role_id	auth	bas_roles	role_id	t	integer
auth.bas_table_permissions.tpermission_id	auth	bas_table_permissions	tpermission_id	t	integer
auth.bas_table_permissions.can_delete	auth	bas_table_permissions	can_delete	t	boolean
auth.bas_table_permissions.can_read	auth	bas_table_permissions	can_read	t	boolean
auth.bas_table_permissions.role_id	auth	bas_table_permissions	role_id	t	integer
auth.bas_table_permissions.table_id	auth	bas_table_permissions	table_id	t	integer
auth.bas_table_permissions.can_write	auth	bas_table_permissions	can_write	t	boolean
auth.bas_tables.table_id	auth	bas_tables	table_id	t	integer
auth.bas_users.user_name	auth	bas_users	user_name	t	text
auth.bas_users.user_id	auth	bas_users	user_id	t	integer
auth.bas_users.created_at	auth	bas_users	created_at	t	timestamp with time zone
auth.eve_access_tokens.token_id	auth	eve_access_tokens	token_id	t	integer
auth.eve_access_tokens.user_id	auth	eve_access_tokens	user_id	t	integer
auth.eve_audit_log.log_id	auth	eve_audit_log	log_id	t	integer
auth.eve_audit_log.user_id	auth	eve_audit_log	user_id	t	integer
auth.eve_audit_log.activity	auth	eve_audit_log	activity	t	text
auth.eve_refresh_tokens.user_id	auth	eve_refresh_tokens	user_id	t	integer
auth.eve_refresh_tokens.rtoken_id	auth	eve_refresh_tokens	rtoken_id	t	integer
entities.bas_entities.entity_parent	entities	bas_entities	entity_parent	t	bigint
entities.bas_entities.entity_id	entities	bas_entities	entity_id	t	integer
entities.bas_entities.created_at	entities	bas_entities	created_at	t	timestamp with time zone
entities.bas_entities.entity_name	entities	bas_entities	entity_name	t	text
syslogic.bas_all_columns.data_type	syslogic	bas_all_columns	data_type	t	text
syslogic.bas_all_columns.sch_name	syslogic	bas_all_columns	sch_name	t	text
syslogic.bas_all_columns.show_front_end	syslogic	bas_all_columns	show_front_end	t	boolean
syslogic.bas_all_columns.text_id	syslogic	bas_all_columns	text_id	t	text
syslogic.bas_all_columns.tab_name	syslogic	bas_all_columns	tab_name	t	text
syslogic.bas_all_columns.col_name	syslogic	bas_all_columns	col_name	t	text
syslogic.bas_data_dic.def_class	syslogic	bas_data_dic	def_class	t	numeric
syslogic.bas_data_dic.def_id	syslogic	bas_data_dic	def_id	t	integer
auth.eve_access_tokens.created_at	auth	eve_access_tokens	created_at	t	timestamp with time zone
auth.eve_audit_log.created_at	auth	eve_audit_log	created_at	t	timestamp with time zone
auth.bas_permissions.created_at	auth	bas_permissions	created_at	t	timestamp with time zone
auth.eve_refresh_tokens.created_at	auth	eve_refresh_tokens	created_at	t	timestamp with time zone
syslogic.bas_data_dic.def_name	syslogic	bas_data_dic	def_name	t	text
syslogic.bas_data_dic.col_id	syslogic	bas_data_dic	col_id	t	text
syslogic.bas_data_dic.en_us	syslogic	bas_data_dic	en_us	t	text
syslogic.bas_data_dic.pt_br	syslogic	bas_data_dic	pt_br	t	text
syslogic.bas_data_dic_class.class_name	syslogic	bas_data_dic_class	class_name	t	text
syslogic.bas_data_dic_class.class_id	syslogic	bas_data_dic_class	class_id	t	integer
auth.bas_tables.table_name	auth	bas_tables	table_name	t	text
auth.bas_users.email	auth	bas_users	email	t	text
auth.bas_users.user_password	auth	bas_users	user_password	t	text
auth.eve_access_tokens.token	auth	eve_access_tokens	token	t	text
auth.eve_refresh_tokens.token	auth	eve_refresh_tokens	token	t	text
entities.bas_entities.email	entities	bas_entities	email	t	text
entities.bas_entities.entity_password	entities	bas_entities	entity_password	t	text
syslogic.bas_data_dic_class.Description	syslogic	bas_data_dic_class	Description	t	text
syslogic.bas_data_dic.on_allowed_language_list	syslogic	bas_data_dic	on_allowed_language_list	t	boolean
accounting.eve_acc_entries.debit	accounting	eve_acc_entries	debit	t	numeric
accounting.eve_acc_entries.credit	accounting	eve_acc_entries	credit	t	numeric
accounting.eve_acc_entries.entry_id	accounting	eve_acc_entries	entry_id	t	integer
accounting.eve_bus_transactions.trans_date	accounting	eve_bus_transactions	trans_date	t	date
accounting.eve_bus_transactions.trans_value	accounting	eve_bus_transactions	trans_value	t	numeric
accounting.eve_bus_transactions.memo	accounting	eve_bus_transactions	memo	t	text
accounting.eve_bus_transactions.entity_id	accounting	eve_bus_transactions	entity_id	t	integer
accounting.eve_bus_transactions.trans_id	accounting	eve_bus_transactions	trans_id	t	integer
accounting.eve_bus_transactions.occur_date	accounting	eve_bus_transactions	occur_date	t	date
accounting.eve_acc_entries.acc_id	accounting	eve_acc_entries	acc_id	t	integer
accounting.eve_acc_entries.bus_trans_id	accounting	eve_acc_entries	bus_trans_id	t	integer
accounting.vw_eve_acc_entries.acc_id	accounting	vw_eve_acc_entries	acc_id	t	integer
accounting.vw_eve_acc_entries.entity_id	accounting	vw_eve_acc_entries	entity_id	t	integer
accounting.vw_eve_acc_entries.trans_date	accounting	vw_eve_acc_entries	trans_date	t	date
accounting.vw_eve_acc_entries.entry_id	accounting	vw_eve_acc_entries	entry_id	t	integer
accounting.vw_eve_acc_entries.memo	accounting	vw_eve_acc_entries	memo	t	text
accounting.vw_eve_acc_entries.occur_date	accounting	vw_eve_acc_entries	occur_date	t	date
accounting.vw_eve_acc_entries.credit	accounting	vw_eve_acc_entries	credit	t	numeric
accounting.vw_eve_acc_entries.debit	accounting	vw_eve_acc_entries	debit	t	numeric
accounting.vw_eve_acc_entries.acc_name	accounting	vw_eve_acc_entries	acc_name	t	text
accounting.vw_eve_acc_entries.entity_name	accounting	vw_eve_acc_entries	entity_name	t	text
accounting.vw_eve_acc_entries.parent_id	accounting	vw_eve_acc_entries	parent_id	t	integer
accounting.bas_acc_chart.tree_id	accounting	bas_acc_chart	tree_id	t	USER-DEFINED
\.


--
-- TOC entry 3713 (class 0 OID 38853)
-- Dependencies: 247
-- Data for Name: bas_data_dic; Type: TABLE DATA; Schema: syslogic; Owner: derole
--

COPY syslogic.bas_data_dic (def_id, def_name, def_class, col_id, en_us, pt_br, on_allowed_language_list) FROM stdin;
264	Column accounting.bas_acc_chart.acc_id	1	accounting.bas_acc_chart.acc_id	acc_id	acc_id	\N
265	Column accounting.bas_acc_chart.init_balance	1	accounting.bas_acc_chart.init_balance	init_balance	init_balance	\N
266	Column accounting.bas_acc_chart.acc_name	1	accounting.bas_acc_chart.acc_name	acc_name	acc_name	\N
268	Column accounting.bas_acc_chart.inactive	1	accounting.bas_acc_chart.inactive	inactive	inactive	\N
270	Column accounting.bas_acc_chart.balance	1	accounting.bas_acc_chart.balance	balance	balance	\N
478	Column accounting.vw_eve_acc_entries.acc_name	1	accounting.vw_eve_acc_entries.acc_name	Account	Conta	\N
479	Column accounting.vw_eve_acc_entries.entity_name	1	accounting.vw_eve_acc_entries.entity_name	Entity	Entidade	\N
294	Column auth.bas_permissions.created_at	1	auth.bas_permissions.created_at	created_at	created_at	\N
295	Column auth.bas_permissions.permission_id	1	auth.bas_permissions.permission_id	permission_id	permission_id	\N
296	Column auth.bas_permissions.role_id	1	auth.bas_permissions.role_id	role_id	role_id	\N
297	Column auth.bas_permissions.user_id	1	auth.bas_permissions.user_id	user_id	user_id	\N
298	Column auth.bas_roles.description	1	auth.bas_roles.description	description	description	\N
299	Column auth.bas_roles.name	1	auth.bas_roles.name	name	name	\N
300	Column auth.bas_roles.role_id	1	auth.bas_roles.role_id	role_id	role_id	\N
301	Column auth.bas_table_permissions.tpermission_id	1	auth.bas_table_permissions.tpermission_id	tpermission_id	tpermission_id	\N
302	Column auth.bas_table_permissions.can_delete	1	auth.bas_table_permissions.can_delete	can_delete	can_delete	\N
303	Column auth.bas_table_permissions.can_read	1	auth.bas_table_permissions.can_read	can_read	can_read	\N
304	Column auth.bas_table_permissions.role_id	1	auth.bas_table_permissions.role_id	role_id	role_id	\N
305	Column auth.bas_table_permissions.table_id	1	auth.bas_table_permissions.table_id	table_id	table_id	\N
306	Column auth.bas_table_permissions.can_write	1	auth.bas_table_permissions.can_write	can_write	can_write	\N
307	Column auth.bas_tables.table_name	1	auth.bas_tables.table_name	table_name	table_name	\N
308	Column auth.bas_tables.table_id	1	auth.bas_tables.table_id	table_id	table_id	\N
309	Column auth.bas_users.user_name	1	auth.bas_users.user_name	user_name	user_name	\N
310	Column auth.bas_users.user_id	1	auth.bas_users.user_id	user_id	user_id	\N
311	Column auth.bas_users.email	1	auth.bas_users.email	email	email	\N
312	Column auth.bas_users.created_at	1	auth.bas_users.created_at	created_at	created_at	\N
313	Column auth.bas_users.user_password	1	auth.bas_users.user_password	user_password	user_password	\N
314	Column auth.eve_access_tokens.token_id	1	auth.eve_access_tokens.token_id	token_id	token_id	\N
315	Column auth.eve_access_tokens.user_id	1	auth.eve_access_tokens.user_id	user_id	user_id	\N
316	Column auth.eve_access_tokens.token	1	auth.eve_access_tokens.token	token	token	\N
317	Column auth.eve_access_tokens.created_at	1	auth.eve_access_tokens.created_at	created_at	created_at	\N
318	Column auth.eve_audit_log.created_at	1	auth.eve_audit_log.created_at	created_at	created_at	\N
319	Column auth.eve_audit_log.log_id	1	auth.eve_audit_log.log_id	log_id	log_id	\N
320	Column auth.eve_audit_log.user_id	1	auth.eve_audit_log.user_id	user_id	user_id	\N
321	Column auth.eve_audit_log.activity	1	auth.eve_audit_log.activity	activity	activity	\N
322	Column auth.eve_refresh_tokens.created_at	1	auth.eve_refresh_tokens.created_at	created_at	created_at	\N
323	Column auth.eve_refresh_tokens.user_id	1	auth.eve_refresh_tokens.user_id	user_id	user_id	\N
324	Column auth.eve_refresh_tokens.rtoken_id	1	auth.eve_refresh_tokens.rtoken_id	rtoken_id	rtoken_id	\N
325	Column auth.eve_refresh_tokens.token	1	auth.eve_refresh_tokens.token	token	token	\N
326	Column entities.bas_entities.email	1	entities.bas_entities.email	email	email	\N
327	Column entities.bas_entities.entity_password	1	entities.bas_entities.entity_password	entity_password	entity_password	\N
328	Column entities.bas_entities.entity_parent	1	entities.bas_entities.entity_parent	entity_parent	entity_parent	\N
329	Column entities.bas_entities.entity_id	1	entities.bas_entities.entity_id	entity_id	entity_id	\N
330	Column entities.bas_entities.created_at	1	entities.bas_entities.created_at	created_at	created_at	\N
331	Column entities.bas_entities.entity_name	1	entities.bas_entities.entity_name	entity_name	entity_name	\N
332	Column syslogic.bas_all_columns.data_type	1	syslogic.bas_all_columns.data_type	data_type	data_type	\N
333	Column syslogic.bas_all_columns.sch_name	1	syslogic.bas_all_columns.sch_name	sch_name	sch_name	\N
334	Column syslogic.bas_all_columns.show_front_end	1	syslogic.bas_all_columns.show_front_end	show_front_end	show_front_end	\N
335	Column syslogic.bas_all_columns.text_id	1	syslogic.bas_all_columns.text_id	text_id	text_id	\N
336	Column syslogic.bas_all_columns.tab_name	1	syslogic.bas_all_columns.tab_name	tab_name	tab_name	\N
337	Column syslogic.bas_all_columns.col_name	1	syslogic.bas_all_columns.col_name	col_name	col_name	\N
338	Column syslogic.bas_data_dic.def_class	1	syslogic.bas_data_dic.def_class	def_class	def_class	\N
339	Column syslogic.bas_data_dic.def_id	1	syslogic.bas_data_dic.def_id	def_id	def_id	\N
340	Column syslogic.bas_data_dic.def_name	1	syslogic.bas_data_dic.def_name	def_name	def_name	\N
341	Column syslogic.bas_data_dic.col_id	1	syslogic.bas_data_dic.col_id	col_id	col_id	\N
345	Column syslogic.bas_data_dic_class.class_name	1	syslogic.bas_data_dic_class.class_name	class_name	class_name	\N
346	Column syslogic.bas_data_dic_class.class_id	1	syslogic.bas_data_dic_class.class_id	class_id	class_id	\N
342	Column syslogic.bas_data_dic.en_us	1	syslogic.bas_data_dic.en_us	en_us	en_us	t
344	Column syslogic.bas_data_dic.pt_br	1	syslogic.bas_data_dic.pt_br	pt_br	pt_br	t
397	Column syslogic.bas_data_dic.on_allowed_language_list	1	syslogic.bas_data_dic.on_allowed_language_list	on_allowed_language_list	on_allowed_language_list	\N
383	Column syslogic.bas_data_dic_class.Description	1	syslogic.bas_data_dic_class.Description	Description	Description	\N
433	Column accounting.vw_eve_acc_entries.acc_id	1	accounting.vw_eve_acc_entries.acc_id	Account ID	Conta	\N
434	Column accounting.vw_eve_acc_entries.entity_id	1	accounting.vw_eve_acc_entries.entity_id	Entity ID	Entidade	\N
436	Column accounting.vw_eve_acc_entries.entry_id	1	accounting.vw_eve_acc_entries.entry_id	Acc Entry	Código do Registro	\N
480	Column accounting.vw_eve_acc_entries.parent_id	1	accounting.vw_eve_acc_entries.parent_id	Transaction	Transação	\N
421	Column accounting.eve_acc_entries.debit	1	accounting.eve_acc_entries.debit	Debit	debit	\N
422	Column accounting.eve_acc_entries.credit	1	accounting.eve_acc_entries.credit	Credit	credit	\N
425	Column accounting.eve_bus_transactions.trans_value	1	accounting.eve_bus_transactions.trans_value	trans_value	trans_value	\N
423	Column accounting.eve_acc_entries.entry_id	1	accounting.eve_acc_entries.entry_id	Entry ID	entry_id	\N
424	Column accounting.eve_bus_transactions.trans_date	1	accounting.eve_bus_transactions.trans_date	Transaction Date	trans_date	\N
426	Column accounting.eve_bus_transactions.memo	1	accounting.eve_bus_transactions.memo	Memo	memo	\N
427	Column accounting.eve_bus_transactions.entity_id	1	accounting.eve_bus_transactions.entity_id	Entity	entity_id	\N
428	Column accounting.eve_bus_transactions.trans_id	1	accounting.eve_bus_transactions.trans_id	Transaction ID	trans_id	\N
429	Column accounting.eve_bus_transactions.occur_date	1	accounting.eve_bus_transactions.occur_date	Occur Date	occur_date	\N
431	Column accounting.eve_acc_entries.acc_id	1	accounting.eve_acc_entries.acc_id	Account	acc_id	\N
432	Column accounting.eve_acc_entries.bus_trans_id	1	accounting.eve_acc_entries.bus_trans_id	Transaction ID	bus_trans_id	\N
435	Column accounting.vw_eve_acc_entries.trans_date	1	accounting.vw_eve_acc_entries.trans_date	Transaction Date	Data da Transação	\N
438	Column accounting.vw_eve_acc_entries.memo	1	accounting.vw_eve_acc_entries.memo	Memo	Descrição	\N
439	Column accounting.vw_eve_acc_entries.occur_date	1	accounting.vw_eve_acc_entries.occur_date	Occurrence Date	Ocorrência	\N
440	Column accounting.vw_eve_acc_entries.credit	1	accounting.vw_eve_acc_entries.credit	Source	Origem	\N
441	Column accounting.vw_eve_acc_entries.debit	1	accounting.vw_eve_acc_entries.debit	Destination	Destino	\N
481	Column accounting.bas_acc_chart.tree_id	1	accounting.bas_acc_chart.tree_id	tree_id	tree_id	\N
\.


--
-- TOC entry 3714 (class 0 OID 38858)
-- Dependencies: 248
-- Data for Name: bas_data_dic_class; Type: TABLE DATA; Schema: syslogic; Owner: derole
--

COPY syslogic.bas_data_dic_class (class_id, class_name, "Description") FROM stdin;
1	Column Name	Columns' names in the database tables. It doesn't include tables created on frontend.
2	Basic Interface Object	Buttons, labels, titles etc.
\.


--
-- TOC entry 3750 (class 0 OID 0)
-- Dependencies: 220
-- Name: bas_acc_chart_acc_id_seq; Type: SEQUENCE SET; Schema: accounting; Owner: derole
--

SELECT pg_catalog.setval('accounting.bas_acc_chart_acc_id_seq', 55, true);


--
-- TOC entry 3751 (class 0 OID 0)
-- Dependencies: 222
-- Name: eve_acc_entries_entry_id_seq; Type: SEQUENCE SET; Schema: accounting; Owner: derole
--

SELECT pg_catalog.setval('accounting.eve_acc_entries_entry_id_seq', 30003, true);


--
-- TOC entry 3752 (class 0 OID 0)
-- Dependencies: 224
-- Name: eve_bus_transactions_trans_id_seq; Type: SEQUENCE SET; Schema: accounting; Owner: derole
--

SELECT pg_catalog.setval('accounting.eve_bus_transactions_trans_id_seq', 31, true);


--
-- TOC entry 3753 (class 0 OID 0)
-- Dependencies: 228
-- Name: bas_permissions_permission_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.bas_permissions_permission_id_seq', 1, false);


--
-- TOC entry 3754 (class 0 OID 0)
-- Dependencies: 230
-- Name: bas_roles_role_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.bas_roles_role_id_seq', 1, false);


--
-- TOC entry 3755 (class 0 OID 0)
-- Dependencies: 232
-- Name: bas_table_permissions_tpermission_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.bas_table_permissions_tpermission_id_seq', 1, false);


--
-- TOC entry 3756 (class 0 OID 0)
-- Dependencies: 234
-- Name: bas_tables_table_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.bas_tables_table_id_seq', 1, false);


--
-- TOC entry 3757 (class 0 OID 0)
-- Dependencies: 236
-- Name: bas_users_user_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.bas_users_user_id_seq', 1, true);


--
-- TOC entry 3758 (class 0 OID 0)
-- Dependencies: 238
-- Name: eve_access_tokens_token_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.eve_access_tokens_token_id_seq', 1, false);


--
-- TOC entry 3759 (class 0 OID 0)
-- Dependencies: 240
-- Name: eve_audit_log_log_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.eve_audit_log_log_id_seq', 1, false);


--
-- TOC entry 3760 (class 0 OID 0)
-- Dependencies: 242
-- Name: eve_refresh_tokens_rtoken_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.eve_refresh_tokens_rtoken_id_seq', 1, false);


--
-- TOC entry 3761 (class 0 OID 0)
-- Dependencies: 243
-- Name: bas_entities_entity_id_seq; Type: SEQUENCE SET; Schema: entities; Owner: derole
--

SELECT pg_catalog.setval('entities.bas_entities_entity_id_seq', 34, true);


--
-- TOC entry 3762 (class 0 OID 0)
-- Dependencies: 245
-- Name: todos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: derole
--

SELECT pg_catalog.setval('public.todos_id_seq', 20, true);


--
-- TOC entry 3763 (class 0 OID 0)
-- Dependencies: 249
-- Name: bas_data_dic_class_class_id_seq; Type: SEQUENCE SET; Schema: syslogic; Owner: derole
--

SELECT pg_catalog.setval('syslogic.bas_data_dic_class_class_id_seq', 2, true);


--
-- TOC entry 3764 (class 0 OID 0)
-- Dependencies: 250
-- Name: bas_data_dic_def_id_seq; Type: SEQUENCE SET; Schema: syslogic; Owner: derole
--

SELECT pg_catalog.setval('syslogic.bas_data_dic_def_id_seq', 492, true);


--
-- TOC entry 3501 (class 2606 OID 38881)
-- Name: bas_acc_chart bas_acc_chart_pkey; Type: CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.bas_acc_chart
    ADD CONSTRAINT bas_acc_chart_pkey PRIMARY KEY (acc_id);


--
-- TOC entry 3503 (class 2606 OID 38883)
-- Name: eve_acc_entries eve_acc_entries_pkey; Type: CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_acc_entries
    ADD CONSTRAINT eve_acc_entries_pkey PRIMARY KEY (entry_id);


--
-- TOC entry 3505 (class 2606 OID 38885)
-- Name: eve_bus_transactions eve_bus_transactions_pkey; Type: CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_bus_transactions
    ADD CONSTRAINT eve_bus_transactions_pkey PRIMARY KEY (trans_id);


--
-- TOC entry 3509 (class 2606 OID 38887)
-- Name: bas_permissions bas_permissions_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_permissions
    ADD CONSTRAINT bas_permissions_pkey PRIMARY KEY (permission_id);


--
-- TOC entry 3511 (class 2606 OID 38889)
-- Name: bas_roles bas_roles_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_roles
    ADD CONSTRAINT bas_roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 3513 (class 2606 OID 38891)
-- Name: bas_table_permissions bas_table_permissions_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_pkey PRIMARY KEY (tpermission_id);


--
-- TOC entry 3515 (class 2606 OID 38893)
-- Name: bas_tables bas_tables_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_tables
    ADD CONSTRAINT bas_tables_pkey PRIMARY KEY (table_id);


--
-- TOC entry 3517 (class 2606 OID 38895)
-- Name: bas_users bas_users_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_users
    ADD CONSTRAINT bas_users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3519 (class 2606 OID 38897)
-- Name: eve_access_tokens eve_access_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_access_tokens
    ADD CONSTRAINT eve_access_tokens_pkey PRIMARY KEY (token_id);


--
-- TOC entry 3521 (class 2606 OID 38899)
-- Name: eve_audit_log eve_audit_log_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_audit_log
    ADD CONSTRAINT eve_audit_log_pkey PRIMARY KEY (log_id);


--
-- TOC entry 3523 (class 2606 OID 38901)
-- Name: eve_refresh_tokens eve_refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_refresh_tokens
    ADD CONSTRAINT eve_refresh_tokens_pkey PRIMARY KEY (rtoken_id);


--
-- TOC entry 3507 (class 2606 OID 38903)
-- Name: bas_entities bas_entities_pkey; Type: CONSTRAINT; Schema: entities; Owner: derole
--

ALTER TABLE ONLY entities.bas_entities
    ADD CONSTRAINT bas_entities_pkey PRIMARY KEY (entity_id);


--
-- TOC entry 3525 (class 2606 OID 38905)
-- Name: todos todos_pkey; Type: CONSTRAINT; Schema: public; Owner: derole
--

ALTER TABLE ONLY public.todos
    ADD CONSTRAINT todos_pkey PRIMARY KEY (id);


--
-- TOC entry 3527 (class 2606 OID 38907)
-- Name: bas_all_columns bas_all_columns_pkey; Type: CONSTRAINT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_all_columns
    ADD CONSTRAINT bas_all_columns_pkey PRIMARY KEY (text_id);


--
-- TOC entry 3531 (class 2606 OID 38909)
-- Name: bas_data_dic_class bas_data_dic_class_pkey; Type: CONSTRAINT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_data_dic_class
    ADD CONSTRAINT bas_data_dic_class_pkey PRIMARY KEY (class_id);


--
-- TOC entry 3529 (class 2606 OID 38911)
-- Name: bas_data_dic bas_data_dic_pkey; Type: CONSTRAINT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_data_dic
    ADD CONSTRAINT bas_data_dic_pkey PRIMARY KEY (def_id);


--
-- TOC entry 3541 (class 2620 OID 38912)
-- Name: bas_all_columns delete_bas_data_dic_trigger; Type: TRIGGER; Schema: syslogic; Owner: derole
--

CREATE TRIGGER delete_bas_data_dic_trigger AFTER DELETE ON syslogic.bas_all_columns FOR EACH ROW EXECUTE FUNCTION syslogic.delete_bas_data_dic();


--
-- TOC entry 3542 (class 2620 OID 38913)
-- Name: bas_all_columns insert_bas_data_dic_trigger; Type: TRIGGER; Schema: syslogic; Owner: derole
--

CREATE TRIGGER insert_bas_data_dic_trigger AFTER INSERT ON syslogic.bas_all_columns FOR EACH ROW EXECUTE FUNCTION syslogic.insert_bas_data_dic();


--
-- TOC entry 3532 (class 2606 OID 38914)
-- Name: eve_acc_entries eve_acc_entries_bus_trans_id_fkey; Type: FK CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_acc_entries
    ADD CONSTRAINT eve_acc_entries_bus_trans_id_fkey FOREIGN KEY (bus_trans_id) REFERENCES accounting.eve_bus_transactions(trans_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3533 (class 2606 OID 38919)
-- Name: eve_bus_transactions eve_bus_transactions_entity_id_fkey; Type: FK CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_bus_transactions
    ADD CONSTRAINT eve_bus_transactions_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entities.bas_entities(entity_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3534 (class 2606 OID 38924)
-- Name: bas_permissions bas_permissions_entity_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_permissions
    ADD CONSTRAINT bas_permissions_entity_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) NOT VALID;


--
-- TOC entry 3535 (class 2606 OID 38929)
-- Name: bas_table_permissions bas_table_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES auth.bas_roles(role_id) ON DELETE CASCADE;


--
-- TOC entry 3536 (class 2606 OID 38934)
-- Name: bas_table_permissions bas_table_permissions_table_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_table_id_fkey FOREIGN KEY (table_id) REFERENCES auth.bas_tables(table_id) ON DELETE CASCADE;


--
-- TOC entry 3537 (class 2606 OID 38939)
-- Name: eve_access_tokens eve_access_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_access_tokens
    ADD CONSTRAINT eve_access_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3538 (class 2606 OID 38944)
-- Name: eve_audit_log eve_audit_log_entity_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_audit_log
    ADD CONSTRAINT eve_audit_log_entity_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) NOT VALID;


--
-- TOC entry 3539 (class 2606 OID 38949)
-- Name: eve_refresh_tokens eve_refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_refresh_tokens
    ADD CONSTRAINT eve_refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3540 (class 2606 OID 38954)
-- Name: bas_data_dic bas_data_dic_col_id_fkey; Type: FK CONSTRAINT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_data_dic
    ADD CONSTRAINT bas_data_dic_col_id_fkey FOREIGN KEY (col_id) REFERENCES syslogic.bas_all_columns(text_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3724 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 3468 (class 3466 OID 38975)
-- Name: sync_bas_all_columns_event; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER sync_bas_all_columns_event ON ddl_command_end
         WHEN TAG IN ('ALTER TABLE', 'CREATE TABLE', 'DROP TABLE')
   EXECUTE FUNCTION public.sync_bas_all_columns_trigger();


ALTER EVENT TRIGGER sync_bas_all_columns_event OWNER TO postgres;

-- Completed on 2023-08-05 08:48:27 -03

--
-- PostgreSQL database dump complete
--

