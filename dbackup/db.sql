--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4 (Ubuntu 15.4-1.pgdg23.04+1)
-- Dumped by pg_dump version 15.4 (Ubuntu 15.4-1.pgdg23.04+1)

-- Started on 2023-08-22 15:58:59 -03

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
-- TOC entry 3726 (class 1262 OID 38562)
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
-- TOC entry 3727 (class 0 OID 0)
-- Name: de; Type: DATABASE PROPERTIES; Schema: -; Owner: derole
--

ALTER DATABASE de SET lc_time TO 'en_US.utf8';
ALTER DATABASE de SET lc_monetary TO 'en_US.utf8';
ALTER DATABASE de SET lc_numeric TO 'en_US.utf8';
ALTER DATABASE de SET lc_messages TO 'en_US.utf8';


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
-- TOC entry 3729 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


--
-- TOC entry 343 (class 1255 OID 39079)
-- Name: bas_acc_chart_delete_cascade_after_delete(); Type: FUNCTION; Schema: accounting; Owner: derole
--

CREATE FUNCTION accounting.bas_acc_chart_delete_cascade_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM accounting.bas_acc_chart WHERE tree_id <@ OLD.tree_id::ltree;
    RETURN OLD;
END;
$$;


ALTER FUNCTION accounting.bas_acc_chart_delete_cascade_after_delete() OWNER TO derole;

--
-- TOC entry 345 (class 1255 OID 39082)
-- Name: bas_acc_chart_update_children_after_update_parent(); Type: FUNCTION; Schema: accounting; Owner: derole
--

CREATE FUNCTION accounting.bas_acc_chart_update_children_after_update_parent() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update children by setting their path to their current value
    -- This will trigger the AFTER UPDATE trigger for each child
    UPDATE accounting.bas_acc_chart 
    SET path = path
    WHERE tree_id <@ NEW.tree_id AND tree_id <> NEW.tree_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION accounting.bas_acc_chart_update_children_after_update_parent() OWNER TO derole;

--
-- TOC entry 344 (class 1255 OID 39080)
-- Name: bas_acc_chart_update_path_before_insert_or_update(); Type: FUNCTION; Schema: accounting; Owner: derole
--

CREATE FUNCTION accounting.bas_acc_chart_update_path_before_insert_or_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    parent_path text;
BEGIN
    -- Verificando se não é um nodo raiz (que teria apenas um nível no tree_id)
    IF nlevel(NEW.tree_id::ltree) > 1 THEN
        -- Pegando o subpath sem o último elemento
        SELECT path INTO parent_path
        FROM accounting.bas_acc_chart
        WHERE tree_id = subpath(NEW.tree_id::ltree, 0, nlevel(NEW.tree_id::ltree) - 1);

        -- Se encontramos um caminho para o parent, concatenamos com o novo nome da conta.
        -- Caso contrário, apenas usamos o nome da nova conta.
        IF parent_path IS NOT NULL THEN
            NEW.path := parent_path || ' > ' || NEW.acc_name;
        ELSE
            NEW.path := NEW.acc_name;
        END IF;
    ELSE
        -- Se é um nodo raiz, apenas usamos o nome da conta.
        NEW.path := NEW.acc_name;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION accounting.bas_acc_chart_update_path_before_insert_or_update() OWNER TO derole;

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
    tree_id public.ltree,
    path text
);


ALTER TABLE accounting.bas_acc_chart OWNER TO derole;

--
-- TOC entry 3730 (class 0 OID 0)
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
-- TOC entry 3731 (class 0 OID 0)
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
-- TOC entry 3732 (class 0 OID 0)
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
    trans_date timestamp with time zone DEFAULT (CURRENT_TIMESTAMP)::timestamp without time zone NOT NULL,
    occur_date timestamp with time zone,
    entity_id integer DEFAULT 0 NOT NULL,
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
-- TOC entry 3733 (class 0 OID 0)
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
-- TOC entry 3734 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE bas_entities; Type: COMMENT; Schema: entities; Owner: derole
--

COMMENT ON TABLE entities.bas_entities IS 'Descrição: Essa tabela armazena as informações básicas das entidades (usuários) registradas no sistema, como nome, email, senha e data de criação.

Integração: A tabela é a principal tabela de entidades do sistema e é referenciada por outras tabelas, como auth.eve_access_tokens e auth.bas_permissions, por meio da chave primária id.

Exemplos de uso: A tabela é utilizada para armazenar e gerenciar as informações básicas de cada entidade (usuário) registrada no sistema. Ela serve como base para a autenticação, autorização e outras funcionalidades relacionadas aos usuários.';


--
-- TOC entry 250 (class 1259 OID 39064)
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
    entt.entity_name,
    acc.path
   FROM (((accounting.eve_acc_entries child
     JOIN accounting.eve_bus_transactions parent ON ((child.bus_trans_id = parent.trans_id)))
     JOIN accounting.bas_acc_chart acc ON ((child.acc_id = acc.acc_id)))
     JOIN entities.bas_entities entt ON ((parent.entity_id = entt.entity_id)));


ALTER TABLE accounting.vw_eve_acc_entries OWNER TO derole;

--
-- TOC entry 226 (class 1259 OID 38790)
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
-- TOC entry 3735 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE bas_permissions; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.bas_permissions IS 'Descrição: Essa tabela representa as permissões atribuídas a uma entidade (usuário) específica em relação a determinados recursos ou funcionalidades do sistema.

Integração: A tabela possui duas chaves estrangeiras: entity_id, que referencia a tabela entities.bas_entities, e role_id, que referencia a tabela entities.bas_roles. Isso permite relacionar uma entidade a um papel específico e, assim, determinar suas permissões.

Exemplos de uso: A tabela é utilizada para gerenciar as permissões de cada entidade (usuário) em relação a recursos ou funcionalidades específicas do sistema. Com base nas permissões atribuídas, é possível controlar o acesso dos usuários a determinadas partes do sistema.';


--
-- TOC entry 227 (class 1259 OID 38794)
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
-- TOC entry 3736 (class 0 OID 0)
-- Dependencies: 227
-- Name: bas_permissions_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_permissions_permission_id_seq OWNED BY auth.bas_permissions.permission_id;


--
-- TOC entry 228 (class 1259 OID 38795)
-- Name: bas_roles; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.bas_roles (
    role_id integer NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE auth.bas_roles OWNER TO derole;

--
-- TOC entry 3737 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE bas_roles; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.bas_roles IS 'Descrição: Essa tabela armazena os diferentes papéis ou funções atribuídos aos usuários do sistema.

Integração: A tabela é referenciada pela tabela auth.bas_permissions por meio da chave primária id, permitindo que cada permissão seja associada a um papel específico.

Exemplos de uso: A tabela é utilizada para definir e gerenciar os papéis disponíveis no sistema. Os papéis podem ter diferentes níveis de autoridade e acesso, permitindo controlar quais recursos e funcionalidades os usuários podem acessar com base no papel atribuído a eles.';


--
-- TOC entry 229 (class 1259 OID 38800)
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
-- TOC entry 3738 (class 0 OID 0)
-- Dependencies: 229
-- Name: bas_roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_roles_role_id_seq OWNED BY auth.bas_roles.role_id;


--
-- TOC entry 230 (class 1259 OID 38801)
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
-- TOC entry 231 (class 1259 OID 38804)
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
-- TOC entry 3739 (class 0 OID 0)
-- Dependencies: 231
-- Name: bas_table_permissions_tpermission_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_table_permissions_tpermission_id_seq OWNED BY auth.bas_table_permissions.tpermission_id;


--
-- TOC entry 232 (class 1259 OID 38805)
-- Name: bas_tables; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.bas_tables (
    table_id integer NOT NULL,
    table_name text NOT NULL
);


ALTER TABLE auth.bas_tables OWNER TO derole;

--
-- TOC entry 233 (class 1259 OID 38810)
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
-- TOC entry 3740 (class 0 OID 0)
-- Dependencies: 233
-- Name: bas_tables_table_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_tables_table_id_seq OWNED BY auth.bas_tables.table_id;


--
-- TOC entry 234 (class 1259 OID 38811)
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
-- TOC entry 3741 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE bas_users; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.bas_users IS 'Descrição: Essa tabela armazena as informações básicas das entidades (usuários) registradas no sistema, como nome, email, senha e data de criação.
Integração: A tabela é a principal tabela de entidades do sistema e é referenciada por outras tabelas, como auth.eve_access_tokens e auth.bas_permissions, por meio da chave primária id.
Exemplos de uso: A tabela é utilizada para armazenar e gerenciar as informações básicas de cada entidade (usuário) registrada no sistema. Ela serve como base para a autenticação, autorização e outras funcionalidades relacionadas aos usuários.';


--
-- TOC entry 235 (class 1259 OID 38817)
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
-- TOC entry 3742 (class 0 OID 0)
-- Dependencies: 235
-- Name: bas_users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_users_user_id_seq OWNED BY auth.bas_users.user_id;


--
-- TOC entry 236 (class 1259 OID 38818)
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
-- TOC entry 3743 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE eve_access_tokens; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.eve_access_tokens IS 'Descrição: Esta tabela armazena os tokens de acesso gerados para autenticar e autorizar as entidades (usuários) no sistema.

Integração: A tabela possui uma chave estrangeira user_id que referencia a tabela entities.bas_entities, estabelecendo uma relação entre o token de acesso e o usuário associado.

Exemplos de uso: A tabela é utilizada para armazenar e validar os tokens de acesso durante o processo de autenticação. É possível consultar essa tabela para verificar se um token de acesso é válido e obter o ID do usuário correspondente.';


--
-- TOC entry 237 (class 1259 OID 38824)
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
-- TOC entry 3744 (class 0 OID 0)
-- Dependencies: 237
-- Name: eve_access_tokens_token_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.eve_access_tokens_token_id_seq OWNED BY auth.eve_access_tokens.token_id;


--
-- TOC entry 238 (class 1259 OID 38825)
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
-- TOC entry 3745 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE eve_audit_log; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.eve_audit_log IS 'Descrição: Esta tabela registra as atividades e ações realizadas no sistema, permitindo rastrear e auditar as operações.
Integração: A tabela possui uma chave estrangeira entity_id que referencia a tabela entities.bas_entities, permitindo relacionar uma atividade registrada com a entidade (usuário) associada à ação.
Exemplos de uso: A tabela é utilizada para registrar informações relevantes sobre atividades específicas, como criação, atualização ou exclusão de registros. Isso permite acompanhar as alterações feitas no sistema e, se necessário, identificar as entidades (usuários) envolvidas nas ações.';


--
-- TOC entry 239 (class 1259 OID 38831)
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
-- TOC entry 3746 (class 0 OID 0)
-- Dependencies: 239
-- Name: eve_audit_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.eve_audit_log_log_id_seq OWNED BY auth.eve_audit_log.log_id;


--
-- TOC entry 240 (class 1259 OID 38832)
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
-- TOC entry 3747 (class 0 OID 0)
-- Dependencies: 240
-- Name: TABLE eve_refresh_tokens; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.eve_refresh_tokens IS 'Descrição: Essa tabela armazena os tokens de atualização usados para renovar os tokens de acesso expirados sem a necessidade de fazer login novamente.

Integração: A tabela possui uma chave estrangeira user_id que referencia a tabela entities.bas_entities, estabelecendo uma relação entre o token de atualização e o usuário associado.

Exemplos de uso: Durante o processo de renovação do token de acesso, a tabela é consultada para verificar se um token de atualização é válido e obter o ID do usuário correspondente. Com base nessas informações, um novo token de acesso pode ser emitido.';


--
-- TOC entry 241 (class 1259 OID 38838)
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
-- TOC entry 3748 (class 0 OID 0)
-- Dependencies: 241
-- Name: eve_refresh_tokens_rtoken_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.eve_refresh_tokens_rtoken_id_seq OWNED BY auth.eve_refresh_tokens.rtoken_id;


--
-- TOC entry 242 (class 1259 OID 38839)
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
-- TOC entry 3749 (class 0 OID 0)
-- Dependencies: 242
-- Name: bas_entities_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: derole
--

ALTER SEQUENCE entities.bas_entities_entity_id_seq OWNED BY entities.bas_entities.entity_id;


--
-- TOC entry 243 (class 1259 OID 38840)
-- Name: todos; Type: TABLE; Schema: public; Owner: derole
--

CREATE TABLE public.todos (
    id integer NOT NULL,
    text text NOT NULL,
    done boolean DEFAULT false NOT NULL
);


ALTER TABLE public.todos OWNER TO derole;

--
-- TOC entry 244 (class 1259 OID 38846)
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
-- TOC entry 3750 (class 0 OID 0)
-- Dependencies: 244
-- Name: todos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: derole
--

ALTER SEQUENCE public.todos_id_seq OWNED BY public.todos.id;


--
-- TOC entry 245 (class 1259 OID 38847)
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
-- TOC entry 246 (class 1259 OID 38853)
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
-- TOC entry 3751 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE bas_data_dic; Type: COMMENT; Schema: syslogic; Owner: derole
--

COMMENT ON TABLE syslogic.bas_data_dic IS 'Data Dictionary';


--
-- TOC entry 247 (class 1259 OID 38858)
-- Name: bas_data_dic_class; Type: TABLE; Schema: syslogic; Owner: derole
--

CREATE TABLE syslogic.bas_data_dic_class (
    class_id integer NOT NULL,
    class_name text NOT NULL,
    "Description" text
);


ALTER TABLE syslogic.bas_data_dic_class OWNER TO derole;

--
-- TOC entry 248 (class 1259 OID 38863)
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
-- TOC entry 3752 (class 0 OID 0)
-- Dependencies: 248
-- Name: bas_data_dic_class_class_id_seq; Type: SEQUENCE OWNED BY; Schema: syslogic; Owner: derole
--

ALTER SEQUENCE syslogic.bas_data_dic_class_class_id_seq OWNED BY syslogic.bas_data_dic_class.class_id;


--
-- TOC entry 249 (class 1259 OID 38864)
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
-- TOC entry 3753 (class 0 OID 0)
-- Dependencies: 249
-- Name: bas_data_dic_def_id_seq; Type: SEQUENCE OWNED BY; Schema: syslogic; Owner: derole
--

ALTER SEQUENCE syslogic.bas_data_dic_def_id_seq OWNED BY syslogic.bas_data_dic.def_id;


--
-- TOC entry 3472 (class 2604 OID 38960)
-- Name: bas_acc_chart acc_id; Type: DEFAULT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.bas_acc_chart ALTER COLUMN acc_id SET DEFAULT nextval('accounting.bas_acc_chart_acc_id_seq'::regclass);


--
-- TOC entry 3476 (class 2604 OID 38961)
-- Name: eve_acc_entries entry_id; Type: DEFAULT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_acc_entries ALTER COLUMN entry_id SET DEFAULT nextval('accounting.eve_acc_entries_entry_id_seq'::regclass);


--
-- TOC entry 3478 (class 2604 OID 38962)
-- Name: eve_bus_transactions trans_id; Type: DEFAULT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_bus_transactions ALTER COLUMN trans_id SET DEFAULT nextval('accounting.eve_bus_transactions_trans_id_seq'::regclass);


--
-- TOC entry 3483 (class 2604 OID 38963)
-- Name: bas_permissions permission_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_permissions ALTER COLUMN permission_id SET DEFAULT nextval('auth.bas_permissions_permission_id_seq'::regclass);


--
-- TOC entry 3485 (class 2604 OID 38964)
-- Name: bas_roles role_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_roles ALTER COLUMN role_id SET DEFAULT nextval('auth.bas_roles_role_id_seq'::regclass);


--
-- TOC entry 3486 (class 2604 OID 38965)
-- Name: bas_table_permissions tpermission_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions ALTER COLUMN tpermission_id SET DEFAULT nextval('auth.bas_table_permissions_tpermission_id_seq'::regclass);


--
-- TOC entry 3487 (class 2604 OID 38966)
-- Name: bas_tables table_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_tables ALTER COLUMN table_id SET DEFAULT nextval('auth.bas_tables_table_id_seq'::regclass);


--
-- TOC entry 3488 (class 2604 OID 38967)
-- Name: bas_users user_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_users ALTER COLUMN user_id SET DEFAULT nextval('auth.bas_users_user_id_seq'::regclass);


--
-- TOC entry 3490 (class 2604 OID 38968)
-- Name: eve_access_tokens token_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_access_tokens ALTER COLUMN token_id SET DEFAULT nextval('auth.eve_access_tokens_token_id_seq'::regclass);


--
-- TOC entry 3492 (class 2604 OID 38969)
-- Name: eve_audit_log log_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_audit_log ALTER COLUMN log_id SET DEFAULT nextval('auth.eve_audit_log_log_id_seq'::regclass);


--
-- TOC entry 3494 (class 2604 OID 38970)
-- Name: eve_refresh_tokens rtoken_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_refresh_tokens ALTER COLUMN rtoken_id SET DEFAULT nextval('auth.eve_refresh_tokens_rtoken_id_seq'::regclass);


--
-- TOC entry 3481 (class 2604 OID 38971)
-- Name: bas_entities entity_id; Type: DEFAULT; Schema: entities; Owner: derole
--

ALTER TABLE ONLY entities.bas_entities ALTER COLUMN entity_id SET DEFAULT nextval('entities.bas_entities_entity_id_seq'::regclass);


--
-- TOC entry 3496 (class 2604 OID 38972)
-- Name: todos id; Type: DEFAULT; Schema: public; Owner: derole
--

ALTER TABLE ONLY public.todos ALTER COLUMN id SET DEFAULT nextval('public.todos_id_seq'::regclass);


--
-- TOC entry 3499 (class 2604 OID 38973)
-- Name: bas_data_dic def_id; Type: DEFAULT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_data_dic ALTER COLUMN def_id SET DEFAULT nextval('syslogic.bas_data_dic_def_id_seq'::regclass);


--
-- TOC entry 3500 (class 2604 OID 38974)
-- Name: bas_data_dic_class class_id; Type: DEFAULT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_data_dic_class ALTER COLUMN class_id SET DEFAULT nextval('syslogic.bas_data_dic_class_class_id_seq'::regclass);


--
-- TOC entry 3690 (class 0 OID 38755)
-- Dependencies: 219
-- Data for Name: bas_acc_chart; Type: TABLE DATA; Schema: accounting; Owner: derole
--

INSERT INTO accounting.bas_acc_chart VALUES (112, 'Visa Card Clarissa', 0.00, -8214.73, false, '002.002', 'Liability > Visa Card Clarissa');
INSERT INTO accounting.bas_acc_chart VALUES (113, 'ELO Card', 0.00, 0.00, false, '002.003', 'Liability > ELO Card');
INSERT INTO accounting.bas_acc_chart VALUES (114, 'Master Card Fred', 0.00, 0.00, false, '002.004', 'Liability > Master Card Fred');
INSERT INTO accounting.bas_acc_chart VALUES (227, 'Software Sale - Frederico', 0.00, 0.00, false, '003.005', 'Revenue > Software Sale - Frederico');
INSERT INTO accounting.bas_acc_chart VALUES (116, 'Clarissa', 0.00, 0.00, false, '003.002', 'Revenue > Clarissa');
INSERT INTO accounting.bas_acc_chart VALUES (1, 'ROOT', 0.00, 0.00, false, '000', 'ROOT');
INSERT INTO accounting.bas_acc_chart VALUES (2, 'Asset', 0.00, 31541.18, false, '001', 'Asset');
INSERT INTO accounting.bas_acc_chart VALUES (107, 'Drawer Clarissa', 0.00, 259.30, false, '001.001.003', 'Asset > Cash > Drawer Clarissa');
INSERT INTO accounting.bas_acc_chart VALUES (102, 'Wallet Clarissa', 0.00, 50.00, false, '001.001.001', 'Asset > Cash > Wallet Clarissa');
INSERT INTO accounting.bas_acc_chart VALUES (198, 'Bank', 0.00, 513.10, false, '001.002', 'Asset > Bank');
INSERT INTO accounting.bas_acc_chart VALUES (104, 'CEF Frederico', 0.00, 0.00, false, '001.002.001', 'Asset > Bank > CEF Frederico');
INSERT INTO accounting.bas_acc_chart VALUES (109, 'BB Clarissa', 0.00, 513.10, false, '001.002.002', 'Asset > Bank > BB Clarissa');
INSERT INTO accounting.bas_acc_chart VALUES (108, 'Savings CEF Frederico', 0.00, 0.00, false, '001.003.001', 'Asset > Savings > Savings CEF Frederico');
INSERT INTO accounting.bas_acc_chart VALUES (110, 'Savings BB Clarissa', 0.00, 30301.59, false, '001.003.002', 'Asset > Savings > Savings BB Clarissa');
INSERT INTO accounting.bas_acc_chart VALUES (201, 'Daniel’s Box', 0.00, 0.00, false, '001.001.004', 'Asset > Cash > Daniel’s Box');
INSERT INTO accounting.bas_acc_chart VALUES (3, 'Liability', 0.00, -11127.07, false, '002', 'Liability');
INSERT INTO accounting.bas_acc_chart VALUES (4, 'Revenue', 0.00, -0.20, false, '003', 'Revenue');
INSERT INTO accounting.bas_acc_chart VALUES (5, 'Expense', 0.00, 21713.02, false, '004', 'Expense');
INSERT INTO accounting.bas_acc_chart VALUES (105, 'Reversal', 0.00, 0.00, false, '001.004', 'Asset > Reversal');
INSERT INTO accounting.bas_acc_chart VALUES (106, 'Inventory', 0.00, 335.29, false, '001.005', 'Asset > Inventory');
INSERT INTO accounting.bas_acc_chart VALUES (111, 'Master Card Clarissa', 0.00, -2795.83, false, '002.001', 'Liability > Master Card Clarissa');
INSERT INTO accounting.bas_acc_chart VALUES (115, 'Rent Agostinho', 0.00, 0.00, false, '003.001', 'Revenue > Rent Agostinho');
INSERT INTO accounting.bas_acc_chart VALUES (117, 'Clarissa Ind. Transport', 0.00, 0.00, false, '003.003', 'Revenue > Clarissa Ind. Transport');
INSERT INTO accounting.bas_acc_chart VALUES (118, 'Savings Interest', 0.00, 0.00, false, '003.004', 'Revenue > Savings Interest');
INSERT INTO accounting.bas_acc_chart VALUES (119, 'Food', 0.00, 924.10, false, '004.001', 'Expense > Food');
INSERT INTO accounting.bas_acc_chart VALUES (134, 'Initial Balances', 0.00, -40789.27, false, '005.001', 'PL > Initial Balances');
INSERT INTO accounting.bas_acc_chart VALUES (197, 'Cash', 0.00, 391.20, false, '001.001', 'Asset > Cash');
INSERT INTO accounting.bas_acc_chart VALUES (199, 'Savings', 0.00, 30301.59, false, '001.003', 'Asset > Savings');
INSERT INTO accounting.bas_acc_chart VALUES (120, 'House', 0.00, 6386.68, false, '004.002', 'Expense > House');
INSERT INTO accounting.bas_acc_chart VALUES (121, 'Unknown Expenses', 0.00, 525.69, false, '004.003', 'Expense > Unknown Expenses');
INSERT INTO accounting.bas_acc_chart VALUES (122, 'Not Registered', 0.00, 60.00, false, '004.004', 'Expense > Not Registered');
INSERT INTO accounting.bas_acc_chart VALUES (123, 'Entertainment', 0.00, 1947.33, false, '004.005', 'Expense > Entertainment');
INSERT INTO accounting.bas_acc_chart VALUES (124, 'Education', 0.00, 0.00, false, '004.006', 'Expense > Education');
INSERT INTO accounting.bas_acc_chart VALUES (125, 'Company', 0.00, 0.00, false, '004.007', 'Expense > Company');
INSERT INTO accounting.bas_acc_chart VALUES (126, 'Children', 0.00, 5771.50, false, '004.008', 'Expense > Children');
INSERT INTO accounting.bas_acc_chart VALUES (135, 'Snack', 0.00, 28.78, false, '004.001.001', 'Expense > Food > Snack');
INSERT INTO accounting.bas_acc_chart VALUES (136, 'Restaurant', 0.00, 80.83, false, '004.001.002', 'Expense > Food > Restaurant');
INSERT INTO accounting.bas_acc_chart VALUES (137, 'Water', 0.00, 0.00, false, '004.002.001', 'Expense > House > Water');
INSERT INTO accounting.bas_acc_chart VALUES (138, 'Animals', 0.00, 2333.33, false, '004.002.002', 'Expense > House > Animals');
INSERT INTO accounting.bas_acc_chart VALUES (139, 'Subscriptions', 0.00, 377.00, false, '004.002.003', 'Expense > House > Subscriptions');
INSERT INTO accounting.bas_acc_chart VALUES (140, 'Bed, table and bath', 0.00, 0.00, false, '004.002.004', 'Expense > House > Bed, table and bath');
INSERT INTO accounting.bas_acc_chart VALUES (141, 'Decoration', 0.00, 15.00, false, '004.002.005', 'Expense > House > Decoration');
INSERT INTO accounting.bas_acc_chart VALUES (142, 'Electricity', 0.00, 466.40, false, '004.002.006', 'Expense > House > Electricity');
INSERT INTO accounting.bas_acc_chart VALUES (143, 'Appliances', 0.00, 1110.49, false, '004.002.007', 'Expense > House > Appliances');
INSERT INTO accounting.bas_acc_chart VALUES (144, 'Maid', 0.00, 1105.00, false, '004.002.008', 'Expense > House > Maid');
INSERT INTO accounting.bas_acc_chart VALUES (145, 'Tools and utensils', 0.00, 0.00, false, '004.002.009', 'Expense > House > Tools and utensils');
INSERT INTO accounting.bas_acc_chart VALUES (146, 'Gardener', 0.00, 150.00, false, '004.002.010', 'Expense > House > Gardener');
INSERT INTO accounting.bas_acc_chart VALUES (127, 'Hygiene & Beauty', 0.00, 50.00, false, '004.009', 'Expense > Hygiene & Beauty');
INSERT INTO accounting.bas_acc_chart VALUES (128, 'Loss', 0.00, 0.00, false, '004.010', 'Expense > Loss');
INSERT INTO accounting.bas_acc_chart VALUES (129, 'Gifts and Donations', 0.00, 925.91, false, '004.011', 'Expense > Gifts and Donations');
INSERT INTO accounting.bas_acc_chart VALUES (130, 'Leeches', 0.00, 72.67, false, '004.012', 'Expense > Leeches');
INSERT INTO accounting.bas_acc_chart VALUES (131, 'Health', 0.00, 667.98, false, '004.013', 'Expense > Health');
INSERT INTO accounting.bas_acc_chart VALUES (132, 'Transport', 0.00, 2647.72, false, '004.014', 'Expense > Transport');
INSERT INTO accounting.bas_acc_chart VALUES (133, 'Clothing', 0.00, 1731.94, false, '004.015', 'Expense > Clothing');
INSERT INTO accounting.bas_acc_chart VALUES (147, 'Maintenance and Repairs', 0.00, 341.44, false, '004.002.011', 'Expense > House > Maintenance and Repairs');
INSERT INTO accounting.bas_acc_chart VALUES (148, 'Furniture', 0.00, 100.00, false, '004.002.012', 'Expense > House > Furniture');
INSERT INTO accounting.bas_acc_chart VALUES (149, 'Consumable Products', 0.00, 23.00, false, '004.002.013', 'Expense > House > Consumable Products');
INSERT INTO accounting.bas_acc_chart VALUES (150, 'Cleaning Products', 0.00, 23.46, false, '004.002.014', 'Expense > House > Cleaning Products');
INSERT INTO accounting.bas_acc_chart VALUES (6, 'PL', 0.00, -40789.27, false, '005', 'PL');
INSERT INTO accounting.bas_acc_chart VALUES (173, 'Maintenance and Repairs', 0.00, 486.09, false, '004.014.005', 'Expense > Transport > Maintenance and Repairs');
INSERT INTO accounting.bas_acc_chart VALUES (151, 'Phone and Internet', 0.00, 341.56, false, '004.002.015', 'Expense > House > Phone and Internet');
INSERT INTO accounting.bas_acc_chart VALUES (152, 'Toys', 0.00, 1584.63, false, '004.005.001', 'Expense > Entertainment > Toys');
INSERT INTO accounting.bas_acc_chart VALUES (153, 'Tours', 0.00, 0.00, false, '004.005.002', 'Expense > Entertainment > Tours');
INSERT INTO accounting.bas_acc_chart VALUES (154, 'Trips', 0.00, 0.00, false, '004.005.003', 'Expense > Entertainment > Trips');
INSERT INTO accounting.bas_acc_chart VALUES (155, 'TagPlus', 0.00, 0.00, false, '004.007.001', 'Expense > Company > TagPlus');
INSERT INTO accounting.bas_acc_chart VALUES (156, 'Daniel', 0.00, 1075.00, false, '004.008.001', 'Expense > Children > Daniel');
INSERT INTO accounting.bas_acc_chart VALUES (157, 'Erica', 0.00, 4696.50, false, '004.008.002', 'Expense > Children > Erica');
INSERT INTO accounting.bas_acc_chart VALUES (158, 'Donations', 0.00, 880.37, false, '004.011.001', 'Expense > Gifts and Donations > Donations');
INSERT INTO accounting.bas_acc_chart VALUES (159, 'Gifts', 0.00, 45.54, false, '004.011.002', 'Expense > Gifts and Donations > Gifts');
INSERT INTO accounting.bas_acc_chart VALUES (160, 'Income Tax', 0.00, 0.00, false, '004.012.001', 'Expense > Leeches > Income Tax');
INSERT INTO accounting.bas_acc_chart VALUES (161, 'Bank Interest', 0.00, 0.00, false, '004.012.002', 'Expense > Leeches > Bank Interest');
INSERT INTO accounting.bas_acc_chart VALUES (162, 'Bank Fees', 0.00, 72.67, false, '004.012.003', 'Expense > Leeches > Bank Fees');
INSERT INTO accounting.bas_acc_chart VALUES (163, 'Consultations', 0.00, 0.00, false, '004.013.001', 'Expense > Health > Consultations');
INSERT INTO accounting.bas_acc_chart VALUES (164, 'Exams', 0.00, 0.00, false, '004.013.002', 'Expense > Health > Exams');
INSERT INTO accounting.bas_acc_chart VALUES (165, 'Glasses', 0.00, 0.00, false, '004.013.003', 'Expense > Health > Glasses');
INSERT INTO accounting.bas_acc_chart VALUES (166, 'Health Plan', 0.00, 0.00, false, '004.013.004', 'Expense > Health > Health Plan');
INSERT INTO accounting.bas_acc_chart VALUES (167, 'Medications', 0.00, 667.98, false, '004.013.005', 'Expense > Health > Medications');
INSERT INTO accounting.bas_acc_chart VALUES (168, 'Therapies', 0.00, 0.00, false, '004.013.006', 'Expense > Health > Therapies');
INSERT INTO accounting.bas_acc_chart VALUES (169, 'Fuel', 0.00, 732.76, false, '004.014.001', 'Expense > Transport > Fuel');
INSERT INTO accounting.bas_acc_chart VALUES (170, 'Parking', 0.00, 44.40, false, '004.014.002', 'Expense > Transport > Parking');
INSERT INTO accounting.bas_acc_chart VALUES (171, 'Vehicle Property Tax', 0.00, 0.00, false, '004.014.003', 'Expense > Transport > Vehicle Property Tax');
INSERT INTO accounting.bas_acc_chart VALUES (172, 'Washing', 0.00, 50.00, false, '004.014.004', 'Expense > Transport > Washing');
INSERT INTO accounting.bas_acc_chart VALUES (174, 'Tickets, taxi, etc.', 0.00, 8.50, false, '004.014.006', 'Expense > Transport > Tickets, taxi, etc.');
INSERT INTO accounting.bas_acc_chart VALUES (175, 'Insurance', 0.00, 1325.97, false, '004.014.007', 'Expense > Transport > Insurance');
INSERT INTO accounting.bas_acc_chart VALUES (103, 'Wallet Frederico', 0.00, 81.90, false, '001.001.002', 'Asset > Cash > Wallet Frederico');


--
-- TOC entry 3692 (class 0 OID 38764)
-- Dependencies: 221
-- Data for Name: eve_acc_entries; Type: TABLE DATA; Schema: accounting; Owner: derole
--

INSERT INTO accounting.eve_acc_entries VALUES (21, 0.00, 195.09, 21, 109);
INSERT INTO accounting.eve_acc_entries VALUES (22, 0.00, 100.00, 22, 102);
INSERT INTO accounting.eve_acc_entries VALUES (23, 0.00, 9.25, 23, 102);
INSERT INTO accounting.eve_acc_entries VALUES (24, 0.00, 212.87, 24, 109);
INSERT INTO accounting.eve_acc_entries VALUES (25, 0.00, 54.50, 25, 109);
INSERT INTO accounting.eve_acc_entries VALUES (26, 0.00, 8.50, 26, 102);
INSERT INTO accounting.eve_acc_entries VALUES (27, 0.00, 12.00, 27, 109);
INSERT INTO accounting.eve_acc_entries VALUES (28, 0.00, 3.00, 28, 102);
INSERT INTO accounting.eve_acc_entries VALUES (29, 0.00, 50.00, 29, 109);
INSERT INTO accounting.eve_acc_entries VALUES (30, 0.00, 120.00, 30, 107);
INSERT INTO accounting.eve_acc_entries VALUES (31, 0.00, 466.40, 31, 109);
INSERT INTO accounting.eve_acc_entries VALUES (32, 0.00, 104.59, 32, 109);
INSERT INTO accounting.eve_acc_entries VALUES (34, 0.00, 58.00, 34, 109);
INSERT INTO accounting.eve_acc_entries VALUES (35, 0.00, 112.55, 35, 109);
INSERT INTO accounting.eve_acc_entries VALUES (37, 0.00, 112.55, 37, 109);
INSERT INTO accounting.eve_acc_entries VALUES (38, 0.00, 15.87, 38, 109);
INSERT INTO accounting.eve_acc_entries VALUES (39, 0.00, 50.00, 39, 109);
INSERT INTO accounting.eve_acc_entries VALUES (40, 0.00, 51.85, 40, 109);
INSERT INTO accounting.eve_acc_entries VALUES (41, 0.00, 50.00, 41, 109);
INSERT INTO accounting.eve_acc_entries VALUES (42, 0.00, 384.76, 42, 109);
INSERT INTO accounting.eve_acc_entries VALUES (44, 0.00, 7.67, 44, 109);
INSERT INTO accounting.eve_acc_entries VALUES (45, 0.00, 50.00, 45, 109);
INSERT INTO accounting.eve_acc_entries VALUES (46, 0.00, 103.00, 46, 109);
INSERT INTO accounting.eve_acc_entries VALUES (47, 0.00, 50.00, 47, 102);
INSERT INTO accounting.eve_acc_entries VALUES (48, 0.00, 15.04, 48, 109);
INSERT INTO accounting.eve_acc_entries VALUES (49, 0.00, 15.00, 49, 102);
INSERT INTO accounting.eve_acc_entries VALUES (50, 0.00, 30.90, 50, 109);
INSERT INTO accounting.eve_acc_entries VALUES (52, 0.00, 17.93, 52, 109);
INSERT INTO accounting.eve_acc_entries VALUES (53, 0.00, 60.00, 53, 107);
INSERT INTO accounting.eve_acc_entries VALUES (54, 0.00, 223.60, 54, 109);
INSERT INTO accounting.eve_acc_entries VALUES (55, 0.00, 40.91, 55, 109);
INSERT INTO accounting.eve_acc_entries VALUES (58, 0.00, 100.00, 58, 107);
INSERT INTO accounting.eve_acc_entries VALUES (59, 0.00, 10.00, 59, 102);
INSERT INTO accounting.eve_acc_entries VALUES (60, 0.00, 6.20, 60, 102);
INSERT INTO accounting.eve_acc_entries VALUES (61, 0.00, 25.00, 61, 102);
INSERT INTO accounting.eve_acc_entries VALUES (62, 0.00, 275.54, 62, 109);
INSERT INTO accounting.eve_acc_entries VALUES (64, 0.00, 13.47, 64, 102);
INSERT INTO accounting.eve_acc_entries VALUES (65, 0.00, 137.94, 65, 109);
INSERT INTO accounting.eve_acc_entries VALUES (66, 0.00, 245.00, 66, 109);
INSERT INTO accounting.eve_acc_entries VALUES (67, 0.00, 1000.00, 67, 109);
INSERT INTO accounting.eve_acc_entries VALUES (68, 0.00, 23.00, 68, 109);
INSERT INTO accounting.eve_acc_entries VALUES (69, 0.00, 186.36, 69, 109);
INSERT INTO accounting.eve_acc_entries VALUES (70, 0.00, 10.00, 70, 102);
INSERT INTO accounting.eve_acc_entries VALUES (71, 0.00, 187.02, 71, 109);
INSERT INTO accounting.eve_acc_entries VALUES (73, 0.00, 16.97, 73, 109);
INSERT INTO accounting.eve_acc_entries VALUES (74, 0.00, 241.45, 74, 109);
INSERT INTO accounting.eve_acc_entries VALUES (75, 0.00, 264.00, 75, 109);
INSERT INTO accounting.eve_acc_entries VALUES (76, 112.55, 0.00, 76, 109);
INSERT INTO accounting.eve_acc_entries VALUES (77, 0.00, 38.98, 77, 109);
INSERT INTO accounting.eve_acc_entries VALUES (78, 0.00, 85.00, 78, 109);
INSERT INTO accounting.eve_acc_entries VALUES (80, 0.00, 1982.00, 80, 109);
INSERT INTO accounting.eve_acc_entries VALUES (81, 0.00, 35.00, 81, 102);
INSERT INTO accounting.eve_acc_entries VALUES (82, 0.00, 3.00, 82, 109);
INSERT INTO accounting.eve_acc_entries VALUES (84, 0.00, 33.44, 84, 109);
INSERT INTO accounting.eve_acc_entries VALUES (85, 0.00, 50.00, 85, 109);
INSERT INTO accounting.eve_acc_entries VALUES (86, 0.00, 41.27, 86, 109);
INSERT INTO accounting.eve_acc_entries VALUES (87, 0.00, 1.00, 87, 102);
INSERT INTO accounting.eve_acc_entries VALUES (88, 0.00, 360.05, 88, 109);
INSERT INTO accounting.eve_acc_entries VALUES (89, 0.00, 250.00, 89, 107);
INSERT INTO accounting.eve_acc_entries VALUES (91, 0.00, 50.00, 91, 109);
INSERT INTO accounting.eve_acc_entries VALUES (92, 0.00, 3.98, 92, 109);
INSERT INTO accounting.eve_acc_entries VALUES (94, 0.00, 50.00, 94, 109);
INSERT INTO accounting.eve_acc_entries VALUES (95, 0.00, 50.00, 95, 109);
INSERT INTO accounting.eve_acc_entries VALUES (97, 0.00, 159.67, 97, 109);
INSERT INTO accounting.eve_acc_entries VALUES (98, 0.00, 435.12, 98, 109);
INSERT INTO accounting.eve_acc_entries VALUES (99, 0.00, 50.00, 99, 109);
INSERT INTO accounting.eve_acc_entries VALUES (100, 0.00, 43.85, 100, 109);
INSERT INTO accounting.eve_acc_entries VALUES (101, 0.00, 50.00, 101, 109);
INSERT INTO accounting.eve_acc_entries VALUES (103, 0.00, 150.00, 103, 107);
INSERT INTO accounting.eve_acc_entries VALUES (104, 0.00, 2.00, 104, 102);
INSERT INTO accounting.eve_acc_entries VALUES (105, 0.00, 50.00, 105, 109);
INSERT INTO accounting.eve_acc_entries VALUES (106, 0.00, 50.00, 106, 109);
INSERT INTO accounting.eve_acc_entries VALUES (107, 1000.00, 0.00, 107, 109);
INSERT INTO accounting.eve_acc_entries VALUES (108, 0.00, 335.29, 108, 109);
INSERT INTO accounting.eve_acc_entries VALUES (109, 0.00, 176.07, 109, 111);
INSERT INTO accounting.eve_acc_entries VALUES (110, 0.00, 49.99, 110, 112);
INSERT INTO accounting.eve_acc_entries VALUES (111, 0.00, 58.46, 111, 111);
INSERT INTO accounting.eve_acc_entries VALUES (112, 0.00, 29.00, 112, 111);
INSERT INTO accounting.eve_acc_entries VALUES (113, 0.00, 92.89, 113, 112);
INSERT INTO accounting.eve_acc_entries VALUES (114, 0.00, 6.22, 114, 3);
INSERT INTO accounting.eve_acc_entries VALUES (115, 0.00, 179.54, 115, 112);
INSERT INTO accounting.eve_acc_entries VALUES (116, 0.00, 54.08, 116, 3);
INSERT INTO accounting.eve_acc_entries VALUES (117, 0.00, 176.07, 117, 111);
INSERT INTO accounting.eve_acc_entries VALUES (118, 0.00, 179.54, 118, 112);
INSERT INTO accounting.eve_acc_entries VALUES (119, 0.00, 58.46, 119, 111);
INSERT INTO accounting.eve_acc_entries VALUES (120, 0.00, 69.90, 120, 112);
INSERT INTO accounting.eve_acc_entries VALUES (121, 0.00, 60.15, 121, 112);
INSERT INTO accounting.eve_acc_entries VALUES (122, 0.00, 27.90, 122, 112);
INSERT INTO accounting.eve_acc_entries VALUES (123, 0.00, 168.00, 123, 112);
INSERT INTO accounting.eve_acc_entries VALUES (124, 0.00, 65.24, 124, 112);
INSERT INTO accounting.eve_acc_entries VALUES (125, 0.00, 179.54, 125, 112);
INSERT INTO accounting.eve_acc_entries VALUES (126, 0.00, 27.90, 126, 112);
INSERT INTO accounting.eve_acc_entries VALUES (127, 0.00, 27.90, 127, 112);
INSERT INTO accounting.eve_acc_entries VALUES (128, 0.00, 27.90, 128, 112);
INSERT INTO accounting.eve_acc_entries VALUES (129, 0.00, 63.33, 129, 112);
INSERT INTO accounting.eve_acc_entries VALUES (130, 0.00, 49.99, 130, 3);
INSERT INTO accounting.eve_acc_entries VALUES (131, 0.00, 176.07, 131, 111);
INSERT INTO accounting.eve_acc_entries VALUES (132, 0.00, 65.24, 132, 112);
INSERT INTO accounting.eve_acc_entries VALUES (133, 0.00, 6.22, 133, 111);
INSERT INTO accounting.eve_acc_entries VALUES (134, 0.00, 112.35, 134, 112);
INSERT INTO accounting.eve_acc_entries VALUES (135, 0.00, 49.99, 135, 112);
INSERT INTO accounting.eve_acc_entries VALUES (136, 0.00, 29.00, 136, 111);
INSERT INTO accounting.eve_acc_entries VALUES (137, 0.00, 179.54, 137, 112);
INSERT INTO accounting.eve_acc_entries VALUES (138, 0.00, 118.94, 138, 112);
INSERT INTO accounting.eve_acc_entries VALUES (139, 0.00, 139.33, 139, 112);
INSERT INTO accounting.eve_acc_entries VALUES (140, 0.00, 118.94, 140, 112);
INSERT INTO accounting.eve_acc_entries VALUES (141, 0.00, 29.00, 141, 111);
INSERT INTO accounting.eve_acc_entries VALUES (142, 0.00, 49.99, 142, 112);
INSERT INTO accounting.eve_acc_entries VALUES (143, 0.00, 118.94, 143, 112);
INSERT INTO accounting.eve_acc_entries VALUES (144, 0.00, 168.00, 144, 112);
INSERT INTO accounting.eve_acc_entries VALUES (145, 0.00, 72.67, 145, 112);
INSERT INTO accounting.eve_acc_entries VALUES (146, 0.00, 6.22, 146, 111);
INSERT INTO accounting.eve_acc_entries VALUES (147, 0.00, 227.79, 147, 112);
INSERT INTO accounting.eve_acc_entries VALUES (148, 0.00, 29.00, 148, 111);
INSERT INTO accounting.eve_acc_entries VALUES (149, 0.00, 168.00, 149, 112);
INSERT INTO accounting.eve_acc_entries VALUES (150, 0.00, 49.99, 150, 112);
INSERT INTO accounting.eve_acc_entries VALUES (151, 0.00, 29.00, 151, 3);
INSERT INTO accounting.eve_acc_entries VALUES (152, 0.00, 29.00, 152, 111);
INSERT INTO accounting.eve_acc_entries VALUES (153, 0.00, 63.33, 153, 112);
INSERT INTO accounting.eve_acc_entries VALUES (154, 0.00, 168.00, 154, 112);
INSERT INTO accounting.eve_acc_entries VALUES (155, 0.00, 54.08, 155, 112);
INSERT INTO accounting.eve_acc_entries VALUES (156, 0.00, 58.46, 156, 111);
INSERT INTO accounting.eve_acc_entries VALUES (157, 0.00, 92.89, 157, 112);
INSERT INTO accounting.eve_acc_entries VALUES (158, 0.00, 179.54, 158, 112);
INSERT INTO accounting.eve_acc_entries VALUES (159, 0.00, 69.90, 159, 112);
INSERT INTO accounting.eve_acc_entries VALUES (160, 0.00, 176.07, 160, 111);
INSERT INTO accounting.eve_acc_entries VALUES (161, 0.00, 27.90, 161, 112);
INSERT INTO accounting.eve_acc_entries VALUES (162, 0.00, 118.94, 162, 112);
INSERT INTO accounting.eve_acc_entries VALUES (163, 0.00, 176.07, 163, 111);
INSERT INTO accounting.eve_acc_entries VALUES (164, 0.00, 65.24, 164, 112);
INSERT INTO accounting.eve_acc_entries VALUES (165, 0.00, 176.07, 165, 111);
INSERT INTO accounting.eve_acc_entries VALUES (166, 0.00, 92.89, 166, 112);
INSERT INTO accounting.eve_acc_entries VALUES (167, 0.00, 92.89, 167, 112);
INSERT INTO accounting.eve_acc_entries VALUES (168, 0.00, 49.99, 168, 112);
INSERT INTO accounting.eve_acc_entries VALUES (169, 0.00, 381.50, 169, 112);
INSERT INTO accounting.eve_acc_entries VALUES (170, 0.00, 27.90, 170, 112);
INSERT INTO accounting.eve_acc_entries VALUES (171, 0.00, 191.64, 171, 111);
INSERT INTO accounting.eve_acc_entries VALUES (172, 0.00, 176.07, 172, 111);
INSERT INTO accounting.eve_acc_entries VALUES (173, 0.00, 176.07, 173, 111);
INSERT INTO accounting.eve_acc_entries VALUES (174, 0.00, 27.90, 174, 112);
INSERT INTO accounting.eve_acc_entries VALUES (175, 0.00, 86.79, 175, 111);
INSERT INTO accounting.eve_acc_entries VALUES (176, 0.00, 54.08, 176, 112);
INSERT INTO accounting.eve_acc_entries VALUES (177, 0.00, 92.89, 177, 112);
INSERT INTO accounting.eve_acc_entries VALUES (178, 0.00, 27.90, 178, 112);
INSERT INTO accounting.eve_acc_entries VALUES (179, 0.00, 92.89, 179, 112);
INSERT INTO accounting.eve_acc_entries VALUES (180, 0.00, 29.00, 180, 111);
INSERT INTO accounting.eve_acc_entries VALUES (181, 0.00, 29.00, 181, 111);
INSERT INTO accounting.eve_acc_entries VALUES (182, 0.00, 65.24, 182, 112);
INSERT INTO accounting.eve_acc_entries VALUES (183, 0.00, 69.90, 183, 112);
INSERT INTO accounting.eve_acc_entries VALUES (184, 0.00, 27.90, 184, 112);
INSERT INTO accounting.eve_acc_entries VALUES (185, 0.00, 118.94, 185, 112);
INSERT INTO accounting.eve_acc_entries VALUES (186, 0.00, 6.22, 186, 111);
INSERT INTO accounting.eve_acc_entries VALUES (187, 0.00, 118.94, 187, 112);
INSERT INTO accounting.eve_acc_entries VALUES (188, 0.00, 176.07, 188, 111);
INSERT INTO accounting.eve_acc_entries VALUES (189, 0.00, 69.90, 189, 112);
INSERT INTO accounting.eve_acc_entries VALUES (190, 0.00, 27.90, 190, 112);
INSERT INTO accounting.eve_acc_entries VALUES (191, 0.00, 60.15, 191, 112);
INSERT INTO accounting.eve_acc_entries VALUES (192, 0.00, 6.22, 192, 111);
INSERT INTO accounting.eve_acc_entries VALUES (193, 0.00, 6.22, 193, 111);
INSERT INTO accounting.eve_acc_entries VALUES (194, 0.00, 118.94, 194, 112);
INSERT INTO accounting.eve_acc_entries VALUES (195, 0.00, 112.35, 195, 112);
INSERT INTO accounting.eve_acc_entries VALUES (196, 0.00, 29.00, 196, 111);
INSERT INTO accounting.eve_acc_entries VALUES (197, 0.00, 69.90, 197, 112);
INSERT INTO accounting.eve_acc_entries VALUES (198, 0.00, 112.35, 198, 112);
INSERT INTO accounting.eve_acc_entries VALUES (199, 0.00, 153.47, 199, 112);
INSERT INTO accounting.eve_acc_entries VALUES (200, 0.00, 27.90, 200, 112);
INSERT INTO accounting.eve_acc_entries VALUES (201, 0.00, 118.94, 201, 112);
INSERT INTO accounting.eve_acc_entries VALUES (202, 0.00, 29.00, 202, 111);
INSERT INTO accounting.eve_acc_entries VALUES (203, 0.00, 89.00, 203, 112);
INSERT INTO accounting.eve_acc_entries VALUES (204, 0.00, 227.79, 204, 112);
INSERT INTO accounting.eve_acc_entries VALUES (205, 0.00, 27.90, 205, 112);
INSERT INTO accounting.eve_acc_entries VALUES (206, 0.00, 112.35, 206, 112);
INSERT INTO accounting.eve_acc_entries VALUES (207, 0.00, 168.00, 207, 112);
INSERT INTO accounting.eve_acc_entries VALUES (208, 0.00, 167.00, 208, 111);
INSERT INTO accounting.eve_acc_entries VALUES (209, 0.00, 112.35, 209, 112);
INSERT INTO accounting.eve_acc_entries VALUES (210, 0.00, 6.22, 210, 3);
INSERT INTO accounting.eve_acc_entries VALUES (211, 0.00, 227.79, 211, 112);
INSERT INTO accounting.eve_acc_entries VALUES (212, 0.00, 227.79, 212, 112);
INSERT INTO accounting.eve_acc_entries VALUES (213, 0.00, 29.00, 213, 3);
INSERT INTO accounting.eve_acc_entries VALUES (214, 0.00, 69.90, 214, 112);
INSERT INTO accounting.eve_acc_entries VALUES (215, 0.00, 69.90, 215, 112);
INSERT INTO accounting.eve_acc_entries VALUES (216, 0.00, 29.00, 216, 111);
INSERT INTO accounting.eve_acc_entries VALUES (217, 0.00, 27.90, 217, 112);
INSERT INTO accounting.eve_acc_entries VALUES (218, 0.00, 69.90, 218, 112);
INSERT INTO accounting.eve_acc_entries VALUES (219, 0.00, 29.00, 219, 111);
INSERT INTO accounting.eve_acc_entries VALUES (220, 0.00, 54.08, 220, 112);
INSERT INTO accounting.eve_acc_entries VALUES (221, 0.00, 69.90, 221, 112);
INSERT INTO accounting.eve_acc_entries VALUES (222, 0.00, 6.22, 222, 111);
INSERT INTO accounting.eve_acc_entries VALUES (223, 0.00, 176.07, 223, 111);
INSERT INTO accounting.eve_acc_entries VALUES (224, 0.00, 60.15, 224, 112);
INSERT INTO accounting.eve_acc_entries VALUES (225, 0.00, 118.94, 225, 112);
INSERT INTO accounting.eve_acc_entries VALUES (226, 0.00, 60.15, 226, 112);
INSERT INTO accounting.eve_acc_entries VALUES (227, 0.00, 227.79, 227, 112);
INSERT INTO accounting.eve_acc_entries VALUES (228, 0.00, 112.35, 228, 112);
INSERT INTO accounting.eve_acc_entries VALUES (229, 0.00, 168.00, 229, 112);
INSERT INTO accounting.eve_acc_entries VALUES (317, 0.00, 30301.59, 317, 134);
INSERT INTO accounting.eve_acc_entries VALUES (318, 30301.59, 0.00, 317, 110);
INSERT INTO accounting.eve_acc_entries VALUES (326, 0.00, 9166.76, 326, 134);
INSERT INTO accounting.eve_acc_entries VALUES (327, 9166.76, 0.00, 326, 109);
INSERT INTO accounting.eve_acc_entries VALUES (334, 0.00, 75.10, 334, 134);
INSERT INTO accounting.eve_acc_entries VALUES (335, 75.10, 0.00, 334, 103);
INSERT INTO accounting.eve_acc_entries VALUES (339, 0.00, 163.85, 339, 134);
INSERT INTO accounting.eve_acc_entries VALUES (340, 163.85, 0.00, 339, 102);
INSERT INTO accounting.eve_acc_entries VALUES (345, 0.00, 1078.00, 345, 134);
INSERT INTO accounting.eve_acc_entries VALUES (346, 1078.00, 0.00, 345, 107);
INSERT INTO accounting.eve_acc_entries VALUES (348, 9.25, 0.00, 23, 136);
INSERT INTO accounting.eve_acc_entries VALUES (354, 195.09, 0.00, 21, 169);
INSERT INTO accounting.eve_acc_entries VALUES (355, 100.00, 0.00, 22, 148);
INSERT INTO accounting.eve_acc_entries VALUES (357, 1.00, 0.00, 87, 158);
INSERT INTO accounting.eve_acc_entries VALUES (384, 335.29, 0.00, 108, 106);
INSERT INTO accounting.eve_acc_entries VALUES (389, 0.00, 3.97, 389, 134);
INSERT INTO accounting.eve_acc_entries VALUES (390, 3.97, 0.00, 389, 102);
INSERT INTO accounting.eve_acc_entries VALUES (403, 0.00, 100.00, 403, 107);
INSERT INTO accounting.eve_acc_entries VALUES (404, 100.00, 0.00, 403, 102);
INSERT INTO accounting.eve_acc_entries VALUES (409, 0.00, 100.00, 409, 109);
INSERT INTO accounting.eve_acc_entries VALUES (410, 100.00, 0.00, 409, 102);
INSERT INTO accounting.eve_acc_entries VALUES (426, 264.00, 0.00, 75, 201);
INSERT INTO accounting.eve_acc_entries VALUES (536, 0.00, 33.00, 536, 102);
INSERT INTO accounting.eve_acc_entries VALUES (537, 33.00, 0.00, 536, 136);
INSERT INTO accounting.eve_acc_entries VALUES (540, 0.00, 3.80, 540, 102);
INSERT INTO accounting.eve_acc_entries VALUES (541, 3.80, 0.00, 540, 135);
INSERT INTO accounting.eve_acc_entries VALUES (544, 0.00, 15.00, 544, 102);
INSERT INTO accounting.eve_acc_entries VALUES (545, 15.00, 0.00, 544, 127);
INSERT INTO accounting.eve_acc_entries VALUES (548, 0.00, 2.00, 548, 102);
INSERT INTO accounting.eve_acc_entries VALUES (549, 2.00, 0.00, 548, 159);
INSERT INTO accounting.eve_acc_entries VALUES (552, 0.00, 8.20, 552, 102);
INSERT INTO accounting.eve_acc_entries VALUES (553, 8.20, 0.00, 552, 170);
INSERT INTO accounting.eve_acc_entries VALUES (558, 0.00, 3.80, 558, 102);
INSERT INTO accounting.eve_acc_entries VALUES (559, 3.80, 0.00, 558, 135);
INSERT INTO accounting.eve_acc_entries VALUES (561, 0.00, 6.00, 561, 102);
INSERT INTO accounting.eve_acc_entries VALUES (562, 6.00, 0.00, 561, 170);
INSERT INTO accounting.eve_acc_entries VALUES (574, 227.79, 0.00, 212, 175);
INSERT INTO accounting.eve_acc_entries VALUES (589, 212.87, 0.00, 24, 158);
INSERT INTO accounting.eve_acc_entries VALUES (590, 54.50, 0.00, 25, 158);
INSERT INTO accounting.eve_acc_entries VALUES (591, 8.50, 0.00, 26, 174);
INSERT INTO accounting.eve_acc_entries VALUES (592, 12.00, 0.00, 27, 170);
INSERT INTO accounting.eve_acc_entries VALUES (593, 3.00, 0.00, 28, 135);
INSERT INTO accounting.eve_acc_entries VALUES (594, 50.00, 0.00, 29, 158);
INSERT INTO accounting.eve_acc_entries VALUES (595, 120.00, 0.00, 30, 147);
INSERT INTO accounting.eve_acc_entries VALUES (596, 466.40, 0.00, 31, 142);
INSERT INTO accounting.eve_acc_entries VALUES (597, 104.59, 0.00, 32, 173);
INSERT INTO accounting.eve_acc_entries VALUES (598, 58.00, 0.00, 34, 138);
INSERT INTO accounting.eve_acc_entries VALUES (599, 15.87, 0.00, 38, 136);
INSERT INTO accounting.eve_acc_entries VALUES (600, 1982.00, 0.00, 80, 157);
INSERT INTO accounting.eve_acc_entries VALUES (601, 1000.00, 0.00, 67, 156);
INSERT INTO accounting.eve_acc_entries VALUES (602, 435.12, 0.00, 98, 119);
INSERT INTO accounting.eve_acc_entries VALUES (603, 384.76, 0.00, 42, 157);
INSERT INTO accounting.eve_acc_entries VALUES (604, 381.50, 0.00, 169, 173);
INSERT INTO accounting.eve_acc_entries VALUES (605, 360.05, 0.00, 88, 167);
INSERT INTO accounting.eve_acc_entries VALUES (606, 252.08, 0.00, 62, 119);
INSERT INTO accounting.eve_acc_entries VALUES (607, 23.46, 0.00, 62, 150);
INSERT INTO accounting.eve_acc_entries VALUES (608, 245.00, 0.00, 66, 138);
INSERT INTO accounting.eve_acc_entries VALUES (609, 241.45, 0.00, 74, 151);
INSERT INTO accounting.eve_acc_entries VALUES (610, 227.79, 0.00, 211, 175);
INSERT INTO accounting.eve_acc_entries VALUES (611, 227.79, 0.00, 147, 175);
INSERT INTO accounting.eve_acc_entries VALUES (612, 223.60, 0.00, 54, 133);
INSERT INTO accounting.eve_acc_entries VALUES (613, 191.64, 0.00, 171, 169);
INSERT INTO accounting.eve_acc_entries VALUES (614, 187.02, 0.00, 71, 175);
INSERT INTO accounting.eve_acc_entries VALUES (615, 186.36, 0.00, 69, 169);
INSERT INTO accounting.eve_acc_entries VALUES (616, 179.54, 0.00, 137, 175);
INSERT INTO accounting.eve_acc_entries VALUES (617, 179.54, 0.00, 118, 175);
INSERT INTO accounting.eve_acc_entries VALUES (618, 179.54, 0.00, 125, 175);
INSERT INTO accounting.eve_acc_entries VALUES (619, 179.54, 0.00, 158, 175);
INSERT INTO accounting.eve_acc_entries VALUES (620, 176.07, 0.00, 172, 152);
INSERT INTO accounting.eve_acc_entries VALUES (621, 176.07, 0.00, 160, 152);
INSERT INTO accounting.eve_acc_entries VALUES (622, 176.07, 0.00, 117, 152);
INSERT INTO accounting.eve_acc_entries VALUES (623, 176.07, 0.00, 223, 152);
INSERT INTO accounting.eve_acc_entries VALUES (624, 176.07, 0.00, 165, 152);
INSERT INTO accounting.eve_acc_entries VALUES (625, 176.07, 0.00, 188, 152);
INSERT INTO accounting.eve_acc_entries VALUES (626, 168.00, 0.00, 149, 138);
INSERT INTO accounting.eve_acc_entries VALUES (627, 168.00, 0.00, 154, 138);
INSERT INTO accounting.eve_acc_entries VALUES (628, 15.04, 0.00, 48, 136);
INSERT INTO accounting.eve_acc_entries VALUES (629, 15.00, 0.00, 49, 141);
INSERT INTO accounting.eve_acc_entries VALUES (631, 13.47, 0.00, 64, 119);
INSERT INTO accounting.eve_acc_entries VALUES (632, 7.67, 0.00, 44, 136);
INSERT INTO accounting.eve_acc_entries VALUES (633, 3.98, 0.00, 92, 135);
INSERT INTO accounting.eve_acc_entries VALUES (634, 3.00, 0.00, 82, 135);
INSERT INTO accounting.eve_acc_entries VALUES (635, 2.00, 0.00, 104, 158);
INSERT INTO accounting.eve_acc_entries VALUES (636, 176.07, 0.00, 131, 152);
INSERT INTO accounting.eve_acc_entries VALUES (637, 176.07, 0.00, 173, 152);
INSERT INTO accounting.eve_acc_entries VALUES (638, 168.00, 0.00, 207, 138);
INSERT INTO accounting.eve_acc_entries VALUES (639, 168.00, 0.00, 229, 138);
INSERT INTO accounting.eve_acc_entries VALUES (640, 168.00, 0.00, 144, 138);
INSERT INTO accounting.eve_acc_entries VALUES (641, 167.00, 0.00, 208, 138);
INSERT INTO accounting.eve_acc_entries VALUES (642, 159.67, 0.00, 97, 169);
INSERT INTO accounting.eve_acc_entries VALUES (643, 153.47, 0.00, 199, 157);
INSERT INTO accounting.eve_acc_entries VALUES (644, 150.00, 0.00, 103, 146);
INSERT INTO accounting.eve_acc_entries VALUES (645, 139.33, 0.00, 139, 138);
INSERT INTO accounting.eve_acc_entries VALUES (646, 137.94, 0.00, 65, 133);
INSERT INTO accounting.eve_acc_entries VALUES (647, 118.94, 0.00, 187, 133);
INSERT INTO accounting.eve_acc_entries VALUES (648, 118.94, 0.00, 194, 133);
INSERT INTO accounting.eve_acc_entries VALUES (650, 118.94, 0.00, 185, 133);
INSERT INTO accounting.eve_acc_entries VALUES (651, 118.94, 0.00, 140, 133);
INSERT INTO accounting.eve_acc_entries VALUES (652, 118.94, 0.00, 162, 133);
INSERT INTO accounting.eve_acc_entries VALUES (653, 118.94, 0.00, 201, 133);
INSERT INTO accounting.eve_acc_entries VALUES (654, 112.55, 0.00, 37, 167);
INSERT INTO accounting.eve_acc_entries VALUES (655, 112.35, 0.00, 228, 138);
INSERT INTO accounting.eve_acc_entries VALUES (656, 112.35, 0.00, 209, 138);
INSERT INTO accounting.eve_acc_entries VALUES (657, 112.35, 0.00, 206, 138);
INSERT INTO accounting.eve_acc_entries VALUES (658, 112.35, 0.00, 195, 138);
INSERT INTO accounting.eve_acc_entries VALUES (659, 103.00, 0.00, 46, 147);
INSERT INTO accounting.eve_acc_entries VALUES (660, 92.89, 0.00, 157, 157);
INSERT INTO accounting.eve_acc_entries VALUES (661, 92.89, 0.00, 179, 157);
INSERT INTO accounting.eve_acc_entries VALUES (662, 92.89, 0.00, 177, 157);
INSERT INTO accounting.eve_acc_entries VALUES (663, 92.89, 0.00, 113, 157);
INSERT INTO accounting.eve_acc_entries VALUES (664, 92.89, 0.00, 167, 157);
INSERT INTO accounting.eve_acc_entries VALUES (665, 89.00, 0.00, 203, 143);
INSERT INTO accounting.eve_acc_entries VALUES (666, 86.79, 0.00, 175, 157);
INSERT INTO accounting.eve_acc_entries VALUES (667, 85.00, 0.00, 78, 147);
INSERT INTO accounting.eve_acc_entries VALUES (668, 72.67, 0.00, 145, 162);
INSERT INTO accounting.eve_acc_entries VALUES (669, 69.90, 0.00, 159, 143);
INSERT INTO accounting.eve_acc_entries VALUES (670, 69.90, 0.00, 215, 143);
INSERT INTO accounting.eve_acc_entries VALUES (671, 69.90, 0.00, 221, 143);
INSERT INTO accounting.eve_acc_entries VALUES (672, 69.90, 0.00, 183, 143);
INSERT INTO accounting.eve_acc_entries VALUES (673, 69.90, 0.00, 120, 143);
INSERT INTO accounting.eve_acc_entries VALUES (674, 69.90, 0.00, 197, 143);
INSERT INTO accounting.eve_acc_entries VALUES (675, 65.24, 0.00, 132, 157);
INSERT INTO accounting.eve_acc_entries VALUES (676, 65.24, 0.00, 182, 157);
INSERT INTO accounting.eve_acc_entries VALUES (677, 63.33, 0.00, 153, 157);
INSERT INTO accounting.eve_acc_entries VALUES (678, 60.15, 0.00, 224, 157);
INSERT INTO accounting.eve_acc_entries VALUES (679, 60.15, 0.00, 191, 157);
INSERT INTO accounting.eve_acc_entries VALUES (680, 60.15, 0.00, 121, 157);
INSERT INTO accounting.eve_acc_entries VALUES (681, 60.15, 0.00, 226, 157);
INSERT INTO accounting.eve_acc_entries VALUES (682, 60.00, 0.00, 53, 122);
INSERT INTO accounting.eve_acc_entries VALUES (683, 58.46, 0.00, 156, 121);
INSERT INTO accounting.eve_acc_entries VALUES (684, 58.46, 0.00, 111, 121);
INSERT INTO accounting.eve_acc_entries VALUES (685, 58.46, 0.00, 119, 121);
INSERT INTO accounting.eve_acc_entries VALUES (686, 54.08, 0.00, 116, 143);
INSERT INTO accounting.eve_acc_entries VALUES (688, 54.08, 0.00, 220, 143);
INSERT INTO accounting.eve_acc_entries VALUES (689, 54.08, 0.00, 155, 143);
INSERT INTO accounting.eve_acc_entries VALUES (690, 54.08, 0.00, 176, 143);
INSERT INTO accounting.eve_acc_entries VALUES (691, 51.85, 0.00, 40, 119);
INSERT INTO accounting.eve_acc_entries VALUES (692, 50.00, 0.00, 39, 158);
INSERT INTO accounting.eve_acc_entries VALUES (693, 50.00, 0.00, 45, 158);
INSERT INTO accounting.eve_acc_entries VALUES (694, 50.00, 0.00, 106, 158);
INSERT INTO accounting.eve_acc_entries VALUES (695, 50.00, 0.00, 99, 158);
INSERT INTO accounting.eve_acc_entries VALUES (696, 50.00, 0.00, 101, 158);
INSERT INTO accounting.eve_acc_entries VALUES (697, 50.00, 0.00, 85, 158);
INSERT INTO accounting.eve_acc_entries VALUES (698, 50.00, 0.00, 95, 158);
INSERT INTO accounting.eve_acc_entries VALUES (699, 50.00, 0.00, 94, 158);
INSERT INTO accounting.eve_acc_entries VALUES (700, 50.00, 0.00, 47, 172);
INSERT INTO accounting.eve_acc_entries VALUES (701, 49.99, 0.00, 142, 133);
INSERT INTO accounting.eve_acc_entries VALUES (702, 49.99, 0.00, 130, 133);
INSERT INTO accounting.eve_acc_entries VALUES (703, 49.99, 0.00, 168, 133);
INSERT INTO accounting.eve_acc_entries VALUES (704, 49.99, 0.00, 110, 133);
INSERT INTO accounting.eve_acc_entries VALUES (705, 49.99, 0.00, 150, 133);
INSERT INTO accounting.eve_acc_entries VALUES (706, 43.85, 0.00, 100, 167);
INSERT INTO accounting.eve_acc_entries VALUES (707, 41.27, 0.00, 86, 151);
INSERT INTO accounting.eve_acc_entries VALUES (708, 176.07, 0.00, 109, 143);
INSERT INTO accounting.eve_acc_entries VALUES (709, 40.91, 0.00, 55, 151);
INSERT INTO accounting.eve_acc_entries VALUES (710, 38.98, 0.00, 77, 167);
INSERT INTO accounting.eve_acc_entries VALUES (711, 168.00, 0.00, 123, 138);
INSERT INTO accounting.eve_acc_entries VALUES (712, 118.94, 0.00, 225, 133);
INSERT INTO accounting.eve_acc_entries VALUES (713, 35.00, 0.00, 81, 127);
INSERT INTO accounting.eve_acc_entries VALUES (714, 33.44, 0.00, 84, 147);
INSERT INTO accounting.eve_acc_entries VALUES (715, 30.90, 0.00, 50, 138);
INSERT INTO accounting.eve_acc_entries VALUES (716, 29.00, 0.00, 219, 139);
INSERT INTO accounting.eve_acc_entries VALUES (717, 29.00, 0.00, 181, 139);
INSERT INTO accounting.eve_acc_entries VALUES (718, 29.00, 0.00, 141, 139);
INSERT INTO accounting.eve_acc_entries VALUES (719, 29.00, 0.00, 148, 139);
INSERT INTO accounting.eve_acc_entries VALUES (720, 29.00, 0.00, 196, 139);
INSERT INTO accounting.eve_acc_entries VALUES (721, 29.00, 0.00, 202, 139);
INSERT INTO accounting.eve_acc_entries VALUES (722, 29.00, 0.00, 136, 139);
INSERT INTO accounting.eve_acc_entries VALUES (723, 29.00, 0.00, 151, 139);
INSERT INTO accounting.eve_acc_entries VALUES (724, 27.90, 0.00, 217, 123);
INSERT INTO accounting.eve_acc_entries VALUES (725, 27.90, 0.00, 190, 123);
INSERT INTO accounting.eve_acc_entries VALUES (726, 27.90, 0.00, 126, 123);
INSERT INTO accounting.eve_acc_entries VALUES (727, 27.90, 0.00, 128, 123);
INSERT INTO accounting.eve_acc_entries VALUES (728, 27.90, 0.00, 174, 123);
INSERT INTO accounting.eve_acc_entries VALUES (729, 27.90, 0.00, 122, 123);
INSERT INTO accounting.eve_acc_entries VALUES (730, 27.90, 0.00, 161, 123);
INSERT INTO accounting.eve_acc_entries VALUES (731, 27.90, 0.00, 127, 123);
INSERT INTO accounting.eve_acc_entries VALUES (732, 27.90, 0.00, 184, 123);
INSERT INTO accounting.eve_acc_entries VALUES (733, 118.94, 0.00, 138, 133);
INSERT INTO accounting.eve_acc_entries VALUES (734, 118.94, 0.00, 143, 133);
INSERT INTO accounting.eve_acc_entries VALUES (735, 25.00, 0.00, 61, 119);
INSERT INTO accounting.eve_acc_entries VALUES (737, 112.35, 0.00, 134, 138);
INSERT INTO accounting.eve_acc_entries VALUES (738, 23.00, 0.00, 68, 149);
INSERT INTO accounting.eve_acc_entries VALUES (739, 17.93, 0.00, 52, 151);
INSERT INTO accounting.eve_acc_entries VALUES (740, 16.97, 0.00, 73, 119);
INSERT INTO accounting.eve_acc_entries VALUES (741, 10.00, 0.00, 59, 158);
INSERT INTO accounting.eve_acc_entries VALUES (742, 69.90, 0.00, 214, 143);
INSERT INTO accounting.eve_acc_entries VALUES (743, 69.90, 0.00, 189, 143);
INSERT INTO accounting.eve_acc_entries VALUES (744, 69.90, 0.00, 218, 143);
INSERT INTO accounting.eve_acc_entries VALUES (745, 10.00, 0.00, 70, 119);
INSERT INTO accounting.eve_acc_entries VALUES (746, 63.33, 0.00, 129, 157);
INSERT INTO accounting.eve_acc_entries VALUES (747, 6.22, 0.00, 222, 159);
INSERT INTO accounting.eve_acc_entries VALUES (748, 50.00, 0.00, 41, 158);
INSERT INTO accounting.eve_acc_entries VALUES (749, 6.22, 0.00, 114, 159);
INSERT INTO accounting.eve_acc_entries VALUES (750, 6.22, 0.00, 192, 159);
INSERT INTO accounting.eve_acc_entries VALUES (751, 6.22, 0.00, 193, 159);
INSERT INTO accounting.eve_acc_entries VALUES (752, 29.00, 0.00, 180, 139);
INSERT INTO accounting.eve_acc_entries VALUES (753, 29.00, 0.00, 216, 139);
INSERT INTO accounting.eve_acc_entries VALUES (754, 6.20, 0.00, 60, 135);
INSERT INTO accounting.eve_acc_entries VALUES (755, 50.00, 0.00, 91, 158);
INSERT INTO accounting.eve_acc_entries VALUES (756, 92.89, 0.00, 166, 157);
INSERT INTO accounting.eve_acc_entries VALUES (757, 65.24, 0.00, 124, 157);
INSERT INTO accounting.eve_acc_entries VALUES (758, 50.00, 0.00, 105, 158);
INSERT INTO accounting.eve_acc_entries VALUES (759, 49.99, 0.00, 135, 133);
INSERT INTO accounting.eve_acc_entries VALUES (760, 29.00, 0.00, 213, 139);
INSERT INTO accounting.eve_acc_entries VALUES (761, 27.90, 0.00, 200, 123);
INSERT INTO accounting.eve_acc_entries VALUES (762, 27.90, 0.00, 205, 123);
INSERT INTO accounting.eve_acc_entries VALUES (763, 27.90, 0.00, 178, 123);
INSERT INTO accounting.eve_acc_entries VALUES (764, 27.90, 0.00, 170, 123);
INSERT INTO accounting.eve_acc_entries VALUES (765, 6.22, 0.00, 210, 159);
INSERT INTO accounting.eve_acc_entries VALUES (766, 6.22, 0.00, 186, 159);
INSERT INTO accounting.eve_acc_entries VALUES (767, 6.22, 0.00, 133, 159);


--
-- TOC entry 3694 (class 0 OID 38769)
-- Dependencies: 223
-- Data for Name: eve_bus_transactions; Type: TABLE DATA; Schema: accounting; Owner: derole
--

INSERT INTO accounting.eve_bus_transactions VALUES (60, '2018-01-16 00:00:00-02', '2018-01-17 00:00:00-02', 5, '');
INSERT INTO accounting.eve_bus_transactions VALUES (61, '2018-01-07 00:00:00-02', '2018-01-09 00:00:00-02', 5, '');
INSERT INTO accounting.eve_bus_transactions VALUES (64, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, '');
INSERT INTO accounting.eve_bus_transactions VALUES (70, '2018-01-10 00:00:00-02', '2018-01-02 00:00:00-02', 5, '');
INSERT INTO accounting.eve_bus_transactions VALUES (75, '2018-01-16 00:00:00-02', '2018-01-17 00:00:00-02', 5, '');
INSERT INTO accounting.eve_bus_transactions VALUES (80, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Pagamento de Ttulo - CAIXA ECONOMICA FEDERAL');
INSERT INTO accounting.eve_bus_transactions VALUES (81, '2018-01-10 00:00:00-02', '2018-01-17 00:00:00-02', 5, '');
INSERT INTO accounting.eve_bus_transactions VALUES (86, '2018-01-09 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'Pagto conta telefone - VIVO DF');
INSERT INTO accounting.eve_bus_transactions VALUES (87, '2018-01-16 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Guardador de carro');
INSERT INTO accounting.eve_bus_transactions VALUES (103, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Galego');
INSERT INTO accounting.eve_bus_transactions VALUES (104, '2018-01-10 00:00:00-02', '2018-01-17 00:00:00-02', 5, '');
INSERT INTO accounting.eve_bus_transactions VALUES (108, '2018-01-10 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Pagamento de Ttulo - ITAU UNIBANCO S.A.');
INSERT INTO accounting.eve_bus_transactions VALUES (109, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'SHOPTIME.COM  PARC 01/10 RIO DE JANEI');
INSERT INTO accounting.eve_bus_transactions VALUES (110, '2017-11-21 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'ZINZANE       PARC 02/07 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (111, '2017-05-16 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'PAGSEGUROUOL* PARC 08/10 OLINDA');
INSERT INTO accounting.eve_bus_transactions VALUES (112, '2018-07-13 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (113, '2017-08-14 00:00:00-03', '2018-01-08 00:00:00-02', 5, 'LOJAS AMERICA PARC 05/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (114, '2017-08-30 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MERCPAGO-MERC PARC 05/12 OSASCO');
INSERT INTO accounting.eve_bus_transactions VALUES (115, '2017-11-30 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'BB SEGUROS AU PARC 02/06 SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (116, '2017-04-20 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'VIVO PARKSHOP PARC 09/12 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (117, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'SHOPTIME.COM  PARC 01/10 RIO DE JANEI');
INSERT INTO accounting.eve_bus_transactions VALUES (98, '2018-01-12 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Credit Card Purchase - 01/12 14:36 SUPER ADEGA');
INSERT INTO accounting.eve_bus_transactions VALUES (59, '2018-01-02 00:00:00-02', '2018-01-03 00:00:00-02', 5, 'Raffle');
INSERT INTO accounting.eve_bus_transactions VALUES (21, '2018-01-02 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Gasoline');
INSERT INTO accounting.eve_bus_transactions VALUES (22, '2018-01-03 00:00:00-02', '2018-01-03 00:00:00-02', 5, 'Sofa shipping');
INSERT INTO accounting.eve_bus_transactions VALUES (23, '2018-01-07 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'Snack');
INSERT INTO accounting.eve_bus_transactions VALUES (24, '2018-01-15 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Food');
INSERT INTO accounting.eve_bus_transactions VALUES (25, '2018-01-02 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Bill Payment');
INSERT INTO accounting.eve_bus_transactions VALUES (27, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Condominium payment');
INSERT INTO accounting.eve_bus_transactions VALUES (85, '2018-05-02 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'Periodic transfer - donation - 30/11 3598      38867-X  002/012');
INSERT INTO accounting.eve_bus_transactions VALUES (91, '2018-06-02 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'Periodic transfer - donation - 30/11 3598      38867-X  002/012');
INSERT INTO accounting.eve_bus_transactions VALUES (94, '2018-07-02 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'Periodic transfer - donation - 30/11 3598      38867-X  002/012');
INSERT INTO accounting.eve_bus_transactions VALUES (95, '2018-01-02 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Periodic transfer - donation - 30/11 3598      38867-X  002/012');
INSERT INTO accounting.eve_bus_transactions VALUES (99, '2018-10-02 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'Periodic transfer - donation - 30/11 3598      38867-X  002/012');
INSERT INTO accounting.eve_bus_transactions VALUES (101, '2018-09-02 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'Periodic transfer - donation - 30/11 3598      38867-X  002/012');
INSERT INTO accounting.eve_bus_transactions VALUES (105, '2018-03-02 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'Periodic transfer - donation - 30/11 3598      38867-X  002/012');
INSERT INTO accounting.eve_bus_transactions VALUES (106, '2018-04-02 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'Periodic transfer - donation - 30/11 3598      38867-X  002/012');
INSERT INTO accounting.eve_bus_transactions VALUES (28, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Entry');
INSERT INTO accounting.eve_bus_transactions VALUES (29, '2018-11-02 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'Donation');
INSERT INTO accounting.eve_bus_transactions VALUES (31, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Electricity');
INSERT INTO accounting.eve_bus_transactions VALUES (32, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Car Repair');
INSERT INTO accounting.eve_bus_transactions VALUES (34, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Dog Washing');
INSERT INTO accounting.eve_bus_transactions VALUES (35, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Medicines');
INSERT INTO accounting.eve_bus_transactions VALUES (37, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Medicines');
INSERT INTO accounting.eve_bus_transactions VALUES (38, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Restaurant');
INSERT INTO accounting.eve_bus_transactions VALUES (42, '2018-01-15 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Bill Payment');
INSERT INTO accounting.eve_bus_transactions VALUES (44, '2018-01-12 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Manas Restaurant ');
INSERT INTO accounting.eve_bus_transactions VALUES (47, '2018-01-10 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Car Washing');
INSERT INTO accounting.eve_bus_transactions VALUES (49, '2018-01-10 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Fig seedling');
INSERT INTO accounting.eve_bus_transactions VALUES (52, '2018-01-15 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Telephone bill');
INSERT INTO accounting.eve_bus_transactions VALUES (55, '2018-01-09 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'Mobile bill');
INSERT INTO accounting.eve_bus_transactions VALUES (58, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Drawer to wallet transfer');
INSERT INTO accounting.eve_bus_transactions VALUES (71, '2018-01-02 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Insurance payment');
INSERT INTO accounting.eve_bus_transactions VALUES (74, '2018-01-09 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'Mobile bill');
INSERT INTO accounting.eve_bus_transactions VALUES (76, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Reversal');
INSERT INTO accounting.eve_bus_transactions VALUES (118, '2017-11-30 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'BB SEGUROS AU PARC 02/06 SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (119, '2017-05-16 00:00:00-03', '2018-01-08 00:00:00-02', 5, 'PAGSEGUROUOL* PARC 08/10 OLINDA');
INSERT INTO accounting.eve_bus_transactions VALUES (120, '2017-11-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'EXTRA 1347    PARC 02/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (121, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'OUTLET SP CAT PARC 02/05 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (122, '2018-01-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (123, '2017-12-27 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (124, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'FOREVER21 CAT PARC 02/05 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (125, '2017-11-30 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'BB SEGUROS AU PARC 02/06 SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (126, '2018-02-24 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (127, '2018-09-24 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (128, '2018-05-24 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (129, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'COTTON ON DO  PARC 02/03 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (130, '2017-11-21 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'ZINZANE       PARC 02/07 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (131, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'SHOPTIME.COM  PARC 01/10 RIO DE JANEI');
INSERT INTO accounting.eve_bus_transactions VALUES (132, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'FOREVER21 CAT PARC 02/05 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (133, '2017-08-30 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MERCPAGO-MERC PARC 05/12 OSASCO');
INSERT INTO accounting.eve_bus_transactions VALUES (134, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (135, '2017-11-21 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'ZINZANE       PARC 02/07 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (136, '2018-03-13 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (137, '2017-11-30 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'BB SEGUROS AU PARC 02/06 SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (138, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NIKE CATARINA PARC 02/10 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (139, '2017-11-01 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'KENNIA APAREC PARC 03/03 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (140, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NIKE CATARINA PARC 02/10 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (141, '2018-01-13 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (142, '2017-11-21 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'ZINZANE       PARC 02/07 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (143, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NIKE CATARINA PARC 02/10 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (144, '2017-12-27 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (145, '2018-01-10 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'ANUIDADE DIFERENCIADA TIT-PARC 04/06 BR');
INSERT INTO accounting.eve_bus_transactions VALUES (146, '2017-08-30 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MERCPAGO-MERC PARC 05/12 OSASCO');
INSERT INTO accounting.eve_bus_transactions VALUES (147, '2017-11-30 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'BB SEGUROS AU PARC 02/06 SAO PAULO (Sandero)');
INSERT INTO accounting.eve_bus_transactions VALUES (148, '2018-05-13 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (149, '2017-12-27 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (150, '2017-11-21 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'ZINZANE       PARC 02/07 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (151, '2017-12-13 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (152, '2018-08-13 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (153, '2017-11-16 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'COTTON ON DO  PARC 02/03 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (154, '2017-12-27 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (155, '2017-04-20 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'VIVO PARKSHOP PARC 09/12 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (156, '2017-05-16 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'PAGSEGUROUOL* PARC 08/10 OLINDA');
INSERT INTO accounting.eve_bus_transactions VALUES (157, '2017-08-14 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'LOJAS AMERICA PARC 05/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (158, '2017-11-30 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'BB SEGUROS AU PARC 02/06 SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (159, '2017-11-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'EXTRA 1347    PARC 02/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (160, '2017-12-26 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'SHOPTIME.COM  PARC 01/10 RIO DE JANEI');
INSERT INTO accounting.eve_bus_transactions VALUES (161, '2018-04-24 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (162, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NIKE CATARINA PARC 02/10 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (163, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'SHOPTIME.COM  PARC 01/10 RIO DE JANEI');
INSERT INTO accounting.eve_bus_transactions VALUES (164, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'FOREVER21 CAT PARC 02/05 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (165, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'SHOPTIME.COM  PARC 01/10 RIO DE JANEI');
INSERT INTO accounting.eve_bus_transactions VALUES (166, '2017-08-14 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'LOJAS AMERICA PARC 05/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (167, '2017-08-14 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'LOJAS AMERICA PARC 05/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (168, '2017-11-21 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'ZINZANE       PARC 02/07 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (169, '2018-01-04 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'RECANTO DAS E PARC 01/04 BRASILIA    BR');
INSERT INTO accounting.eve_bus_transactions VALUES (170, '2018-11-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (171, '2017-12-20 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'PETROIL COMBUSTIVEIS   BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (172, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'SHOPTIME.COM  PARC 01/10 RIO DE JANEI');
INSERT INTO accounting.eve_bus_transactions VALUES (173, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'SHOPTIME.COM  PARC 01/10 RIO DE JANEI');
INSERT INTO accounting.eve_bus_transactions VALUES (174, '2017-12-24 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (175, '2017-03-26 00:00:00-03', '2018-01-08 00:00:00-02', 5, 'WALMART COMER PARC 10/10 BARUERI');
INSERT INTO accounting.eve_bus_transactions VALUES (176, '2017-04-20 00:00:00-03', '2018-01-08 00:00:00-02', 5, 'VIVO PARKSHOP PARC 09/12 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (177, '2017-08-14 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'LOJAS AMERICA PARC 05/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (178, '2018-10-24 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (179, '2017-08-14 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'LOJAS AMERICA PARC 05/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (180, '2018-10-13 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (181, '2018-04-13 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (182, '2017-11-16 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'FOREVER21 CAT PARC 02/05 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (183, '2017-11-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'EXTRA 1347    PARC 02/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (184, '2018-12-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (185, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NIKE CATARINA PARC 02/10 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (186, '2017-08-30 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MERCPAGO-MERC PARC 05/12 OSASCO');
INSERT INTO accounting.eve_bus_transactions VALUES (187, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NIKE CATARINA PARC 02/10 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (188, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'SHOPTIME.COM  PARC 01/10 RIO DE JANEI');
INSERT INTO accounting.eve_bus_transactions VALUES (189, '2017-11-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'EXTRA 1347    PARC 02/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (190, '2018-06-24 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (191, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'OUTLET SP CAT PARC 02/05 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (192, '2017-08-30 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MERCPAGO-MERC PARC 05/12 OSASCO');
INSERT INTO accounting.eve_bus_transactions VALUES (193, '2017-08-30 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MERCPAGO-MERC PARC 05/12 OSASCO');
INSERT INTO accounting.eve_bus_transactions VALUES (194, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NIKE CATARINA PARC 02/10 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (195, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (196, '2018-12-13 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (197, '2017-11-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'EXTRA 1347    PARC 02/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (198, '2017-12-26 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (199, '2017-07-12 00:00:00-03', '2018-01-08 00:00:00-02', 5, 'CASAS BAHIACO PARC 06/06 SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (200, '2018-07-24 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (201, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'NIKE CATARINA PARC 02/10 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (202, '2018-06-13 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (203, '2017-03-09 00:00:00-03', '2018-01-08 00:00:00-02', 5, 'MALHARIA IPAN PARC 10/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (204, '2017-11-30 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'BB SEGUROS AU PARC 02/06 SAO PAULO (Sandero)');
INSERT INTO accounting.eve_bus_transactions VALUES (205, '2018-08-24 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (206, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (207, '2017-12-27 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (208, '2017-12-27 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'RAFAELLA SAMPAIO CARVA BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (209, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (210, '2017-08-30 00:00:00-03', '2018-01-08 00:00:00-02', 5, 'MERCPAGO-MERC PARC 05/12 OSASCO');
INSERT INTO accounting.eve_bus_transactions VALUES (211, '2017-11-30 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'BB SEGUROS AU PARC 02/06 SAO PAULOBB SEGUROS AU PARC 02/06 SAO PAULO (Sandero)');
INSERT INTO accounting.eve_bus_transactions VALUES (212, '2017-11-30 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'BB SEGUROS AU PARC 02/06 SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (213, '2018-09-13 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (214, '2017-11-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'EXTRA 1347    PARC 02/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (215, '2017-11-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'EXTRA 1347    PARC 02/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (216, '2018-02-13 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (217, '2018-03-24 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'NETFLIX.COM            SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (218, '2017-11-24 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'EXTRA 1347    PARC 02/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (219, '2018-11-13 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'MICROSOFT              SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (220, '2017-04-20 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'VIVO PARKSHOP PARC 09/12 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (221, '2017-11-24 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'EXTRA 1347    PARC 02/10 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (222, '2017-08-30 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'MERCPAGO-MERC PARC 05/12 OSASCO');
INSERT INTO accounting.eve_bus_transactions VALUES (223, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'SHOPTIME.COM  PARC 01/10 RIO DE JANEI');
INSERT INTO accounting.eve_bus_transactions VALUES (224, '2017-11-16 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'OUTLET SP CAT PARC 02/05 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (225, '2017-11-16 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'NIKE CATARINA PARC 02/10 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (226, '2017-11-16 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'OUTLET SP CAT PARC 02/05 SAO ROQUE');
INSERT INTO accounting.eve_bus_transactions VALUES (227, '2017-11-30 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'BB SEGUROS AU PARC 02/06 SAO PAULO');
INSERT INTO accounting.eve_bus_transactions VALUES (228, '2017-12-26 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (229, '2017-12-27 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'GERAR BANHO E PARC 01/06 BRASILIA');
INSERT INTO accounting.eve_bus_transactions VALUES (536, '2018-01-24 00:00:00-02', '2018-01-18 00:00:00-02', 5, 'Almoço da Vargem');
INSERT INTO accounting.eve_bus_transactions VALUES (540, '2018-01-24 00:00:00-02', '2018-01-18 00:00:00-02', 5, 'Lanche');
INSERT INTO accounting.eve_bus_transactions VALUES (544, '2018-01-24 00:00:00-02', '2018-01-19 00:00:00-02', 5, 'Manicure');
INSERT INTO accounting.eve_bus_transactions VALUES (548, '2018-01-24 00:00:00-02', '2018-01-23 00:00:00-02', 5, 'Gorjeta guardador de carro');
INSERT INTO accounting.eve_bus_transactions VALUES (552, '2018-01-24 00:00:00-02', '2018-01-23 00:00:00-02', 5, 'estacionamento TJDFT');
INSERT INTO accounting.eve_bus_transactions VALUES (558, '2018-01-24 00:00:00-02', '2018-01-23 00:00:00-02', 5, 'lanche');
INSERT INTO accounting.eve_bus_transactions VALUES (561, '2018-01-24 00:00:00-02', '2018-01-23 00:00:00-02', 5, 'estacionamento RPG');
INSERT INTO accounting.eve_bus_transactions VALUES (107, '2018-01-09 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Depósito May ajuda aluguel da Érica');
INSERT INTO accounting.eve_bus_transactions VALUES (82, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Credit Card Purchase - 11/01 11:36 MINI KALZONE');
INSERT INTO accounting.eve_bus_transactions VALUES (84, '2018-01-10 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Credit Card Purchase - 10/01 15:21 LOJAS AMERICANAS');
INSERT INTO accounting.eve_bus_transactions VALUES (88, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Credit Card Purchase - 08/01 16:01 DROGASIL 433');
INSERT INTO accounting.eve_bus_transactions VALUES (92, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Credit Card Purchase - 11/01 16:48 DROGAFUJI CSB 2');
INSERT INTO accounting.eve_bus_transactions VALUES (97, '2018-01-16 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Credit Card Purchase - 16/01 10:06 MAXXI');
INSERT INTO accounting.eve_bus_transactions VALUES (100, '2018-01-02 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Credit Card Purchase - 02/01 17:16 FCIA PAGUE MENOS');
INSERT INTO accounting.eve_bus_transactions VALUES (334, '2018-01-22 00:00:00-02', '2018-01-01 00:00:00-02', 5, 'Saldo inicial wallet Fredd');
INSERT INTO accounting.eve_bus_transactions VALUES (339, '2018-01-22 00:00:00-02', '2018-01-01 00:00:00-02', 5, 'Saldo Inicial wallet Clarissa');
INSERT INTO accounting.eve_bus_transactions VALUES (409, '2018-01-23 00:00:00-02', '2018-01-10 00:00:00-02', 5, 'Saque banco >> clarissa wallet');
INSERT INTO accounting.eve_bus_transactions VALUES (50, '2018-01-02 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Ferilizer');
INSERT INTO accounting.eve_bus_transactions VALUES (53, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Lost');
INSERT INTO accounting.eve_bus_transactions VALUES (77, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Medicine');
INSERT INTO accounting.eve_bus_transactions VALUES (345, '2018-01-22 00:00:00-02', '2018-01-01 00:00:00-02', 5, 'Saldo Inicial da drawer');
INSERT INTO accounting.eve_bus_transactions VALUES (26, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Bus and Subway');
INSERT INTO accounting.eve_bus_transactions VALUES (89, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Transfer');
INSERT INTO accounting.eve_bus_transactions VALUES (39, '2018-08-02 00:00:00-03', '2018-01-09 00:00:00-02', 5, 'Donation');
INSERT INTO accounting.eve_bus_transactions VALUES (403, '2018-01-23 00:00:00-02', '2018-01-11 00:00:00-02', 5, 'Tranf Gaveta wallet Clarissa');
INSERT INTO accounting.eve_bus_transactions VALUES (30, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'House repair');
INSERT INTO accounting.eve_bus_transactions VALUES (317, '2018-01-22 00:00:00-02', '2018-01-01 00:00:00-02', 5, 'Initial Savings Balance');
INSERT INTO accounting.eve_bus_transactions VALUES (326, '2018-01-22 00:00:00-02', '2018-01-01 00:00:00-02', 5, 'Saldo Inicial Clarissa Checking Account');
INSERT INTO accounting.eve_bus_transactions VALUES (389, '2018-01-23 00:00:00-02', '2018-01-01 00:00:00-02', 5, 'Unknown Balance. Booked as initial balance. Consertar depois');
INSERT INTO accounting.eve_bus_transactions VALUES (40, '2018-01-10 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Supermarket');
INSERT INTO accounting.eve_bus_transactions VALUES (41, '2018-02-02 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'Donation');
INSERT INTO accounting.eve_bus_transactions VALUES (45, '2018-12-02 00:00:00-02', '2018-01-09 00:00:00-02', 5, 'Donation');
INSERT INTO accounting.eve_bus_transactions VALUES (46, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Pipes to repair bathroom');
INSERT INTO accounting.eve_bus_transactions VALUES (48, '2018-01-03 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Restaurant');
INSERT INTO accounting.eve_bus_transactions VALUES (54, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Clothes');
INSERT INTO accounting.eve_bus_transactions VALUES (62, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Supermarket');
INSERT INTO accounting.eve_bus_transactions VALUES (65, '2018-01-16 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Clothes');
INSERT INTO accounting.eve_bus_transactions VALUES (66, '2018-01-15 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Clothes');
INSERT INTO accounting.eve_bus_transactions VALUES (67, '2018-01-02 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Transfer');
INSERT INTO accounting.eve_bus_transactions VALUES (68, '2018-01-08 00:00:00-02', '2018-01-08 00:00:00-02', 5, 'Packaging');
INSERT INTO accounting.eve_bus_transactions VALUES (69, '2018-01-10 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Gasoline');
INSERT INTO accounting.eve_bus_transactions VALUES (73, '2018-01-15 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Bread');
INSERT INTO accounting.eve_bus_transactions VALUES (78, '2018-01-11 00:00:00-02', '2018-01-17 00:00:00-02', 5, 'Pipes');


--
-- TOC entry 3697 (class 0 OID 38790)
-- Dependencies: 226
-- Data for Name: bas_permissions; Type: TABLE DATA; Schema: auth; Owner: derole
--



--
-- TOC entry 3699 (class 0 OID 38795)
-- Dependencies: 228
-- Data for Name: bas_roles; Type: TABLE DATA; Schema: auth; Owner: derole
--



--
-- TOC entry 3701 (class 0 OID 38801)
-- Dependencies: 230
-- Data for Name: bas_table_permissions; Type: TABLE DATA; Schema: auth; Owner: derole
--



--
-- TOC entry 3703 (class 0 OID 38805)
-- Dependencies: 232
-- Data for Name: bas_tables; Type: TABLE DATA; Schema: auth; Owner: derole
--



--
-- TOC entry 3705 (class 0 OID 38811)
-- Dependencies: 234
-- Data for Name: bas_users; Type: TABLE DATA; Schema: auth; Owner: derole
--

INSERT INTO auth.bas_users VALUES (1, 'Frederico Sarmento', 'sdfhsdfg', 'sdfgsdfg', '2023-07-08 14:47:03.503518');


--
-- TOC entry 3707 (class 0 OID 38818)
-- Dependencies: 236
-- Data for Name: eve_access_tokens; Type: TABLE DATA; Schema: auth; Owner: derole
--



--
-- TOC entry 3709 (class 0 OID 38825)
-- Dependencies: 238
-- Data for Name: eve_audit_log; Type: TABLE DATA; Schema: auth; Owner: derole
--



--
-- TOC entry 3711 (class 0 OID 38832)
-- Dependencies: 240
-- Data for Name: eve_refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: derole
--



--
-- TOC entry 3696 (class 0 OID 38779)
-- Dependencies: 225
-- Data for Name: bas_entities; Type: TABLE DATA; Schema: entities; Owner: derole
--

INSERT INTO entities.bas_entities VALUES (5, 'Microsoft', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (6, 'Google', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (7, 'Amazon', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (8, 'Apple', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (9, 'Facebook', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (10, 'Intel', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (11, 'IBM', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (12, 'Adobe', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (13, 'Oracle', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (14, 'Uber', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (15, 'Netflix', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (16, 'Tesla', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (17, 'Spotify', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (18, 'Twitter', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (19, 'Walmart', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (20, 'Procter & Gamble', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (21, 'Johnson & Johnson', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (22, 'Unilever', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (23, 'Pfizer', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (24, 'General Motors', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (25, 'Ford', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (26, 'Boeing', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (27, 'Coca-Cola', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (28, 'PepsiCo', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (29, 'Starbucks', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (30, 'McDonald''s', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (31, 'Adidas', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (32, 'Nike', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (33, 'HSBC', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');
INSERT INTO entities.bas_entities VALUES (34, 'JP Morgan Chase', NULL, NULL, NULL, '2023-08-04 15:34:10.273656');


--
-- TOC entry 3714 (class 0 OID 38840)
-- Dependencies: 243
-- Data for Name: todos; Type: TABLE DATA; Schema: public; Owner: derole
--

INSERT INTO public.todos VALUES (17, 'maluco', false);
INSERT INTO public.todos VALUES (18, 'beleza', false);
INSERT INTO public.todos VALUES (19, 'tá foda', false);
INSERT INTO public.todos VALUES (20, 'conseguir', false);


--
-- TOC entry 3716 (class 0 OID 38847)
-- Dependencies: 245
-- Data for Name: bas_all_columns; Type: TABLE DATA; Schema: syslogic; Owner: derole
--

INSERT INTO syslogic.bas_all_columns VALUES ('accounting.bas_acc_chart.acc_id', 'accounting', 'bas_acc_chart', 'acc_id', true, 'smallint');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.bas_acc_chart.init_balance', 'accounting', 'bas_acc_chart', 'init_balance', true, 'numeric');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.bas_acc_chart.acc_name', 'accounting', 'bas_acc_chart', 'acc_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.bas_acc_chart.inactive', 'accounting', 'bas_acc_chart', 'inactive', true, 'boolean');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.bas_acc_chart.balance', 'accounting', 'bas_acc_chart', 'balance', true, 'numeric');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_permissions.permission_id', 'auth', 'bas_permissions', 'permission_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_permissions.role_id', 'auth', 'bas_permissions', 'role_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_permissions.user_id', 'auth', 'bas_permissions', 'user_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_roles.description', 'auth', 'bas_roles', 'description', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_roles.name', 'auth', 'bas_roles', 'name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_roles.role_id', 'auth', 'bas_roles', 'role_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_table_permissions.tpermission_id', 'auth', 'bas_table_permissions', 'tpermission_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_table_permissions.can_delete', 'auth', 'bas_table_permissions', 'can_delete', true, 'boolean');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_table_permissions.can_read', 'auth', 'bas_table_permissions', 'can_read', true, 'boolean');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_table_permissions.role_id', 'auth', 'bas_table_permissions', 'role_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_table_permissions.table_id', 'auth', 'bas_table_permissions', 'table_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_table_permissions.can_write', 'auth', 'bas_table_permissions', 'can_write', true, 'boolean');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_tables.table_id', 'auth', 'bas_tables', 'table_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_users.user_name', 'auth', 'bas_users', 'user_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_users.user_id', 'auth', 'bas_users', 'user_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_users.created_at', 'auth', 'bas_users', 'created_at', true, 'timestamp with time zone');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_access_tokens.token_id', 'auth', 'eve_access_tokens', 'token_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_access_tokens.user_id', 'auth', 'eve_access_tokens', 'user_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_audit_log.log_id', 'auth', 'eve_audit_log', 'log_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_audit_log.user_id', 'auth', 'eve_audit_log', 'user_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_audit_log.activity', 'auth', 'eve_audit_log', 'activity', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_refresh_tokens.user_id', 'auth', 'eve_refresh_tokens', 'user_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_refresh_tokens.rtoken_id', 'auth', 'eve_refresh_tokens', 'rtoken_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('entities.bas_entities.entity_parent', 'entities', 'bas_entities', 'entity_parent', true, 'bigint');
INSERT INTO syslogic.bas_all_columns VALUES ('entities.bas_entities.entity_id', 'entities', 'bas_entities', 'entity_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('entities.bas_entities.created_at', 'entities', 'bas_entities', 'created_at', true, 'timestamp with time zone');
INSERT INTO syslogic.bas_all_columns VALUES ('entities.bas_entities.entity_name', 'entities', 'bas_entities', 'entity_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_all_columns.data_type', 'syslogic', 'bas_all_columns', 'data_type', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_all_columns.sch_name', 'syslogic', 'bas_all_columns', 'sch_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_all_columns.show_front_end', 'syslogic', 'bas_all_columns', 'show_front_end', true, 'boolean');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_all_columns.text_id', 'syslogic', 'bas_all_columns', 'text_id', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_all_columns.tab_name', 'syslogic', 'bas_all_columns', 'tab_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_all_columns.col_name', 'syslogic', 'bas_all_columns', 'col_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_data_dic.def_class', 'syslogic', 'bas_data_dic', 'def_class', true, 'numeric');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_data_dic.def_id', 'syslogic', 'bas_data_dic', 'def_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_access_tokens.created_at', 'auth', 'eve_access_tokens', 'created_at', true, 'timestamp with time zone');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_audit_log.created_at', 'auth', 'eve_audit_log', 'created_at', true, 'timestamp with time zone');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_permissions.created_at', 'auth', 'bas_permissions', 'created_at', true, 'timestamp with time zone');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_refresh_tokens.created_at', 'auth', 'eve_refresh_tokens', 'created_at', true, 'timestamp with time zone');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_data_dic.def_name', 'syslogic', 'bas_data_dic', 'def_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_data_dic.col_id', 'syslogic', 'bas_data_dic', 'col_id', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_data_dic.en_us', 'syslogic', 'bas_data_dic', 'en_us', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_data_dic.pt_br', 'syslogic', 'bas_data_dic', 'pt_br', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_data_dic_class.class_name', 'syslogic', 'bas_data_dic_class', 'class_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_data_dic_class.class_id', 'syslogic', 'bas_data_dic_class', 'class_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_tables.table_name', 'auth', 'bas_tables', 'table_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_users.email', 'auth', 'bas_users', 'email', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.bas_users.user_password', 'auth', 'bas_users', 'user_password', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_access_tokens.token', 'auth', 'eve_access_tokens', 'token', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('auth.eve_refresh_tokens.token', 'auth', 'eve_refresh_tokens', 'token', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('entities.bas_entities.email', 'entities', 'bas_entities', 'email', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('entities.bas_entities.entity_password', 'entities', 'bas_entities', 'entity_password', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_data_dic_class.Description', 'syslogic', 'bas_data_dic_class', 'Description', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('syslogic.bas_data_dic.on_allowed_language_list', 'syslogic', 'bas_data_dic', 'on_allowed_language_list', true, 'boolean');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.eve_acc_entries.debit', 'accounting', 'eve_acc_entries', 'debit', true, 'numeric');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.eve_acc_entries.credit', 'accounting', 'eve_acc_entries', 'credit', true, 'numeric');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.eve_acc_entries.entry_id', 'accounting', 'eve_acc_entries', 'entry_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.eve_bus_transactions.trans_date', 'accounting', 'eve_bus_transactions', 'trans_date', true, 'date');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.eve_bus_transactions.memo', 'accounting', 'eve_bus_transactions', 'memo', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.eve_bus_transactions.entity_id', 'accounting', 'eve_bus_transactions', 'entity_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.eve_bus_transactions.trans_id', 'accounting', 'eve_bus_transactions', 'trans_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.eve_bus_transactions.occur_date', 'accounting', 'eve_bus_transactions', 'occur_date', true, 'date');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.eve_acc_entries.acc_id', 'accounting', 'eve_acc_entries', 'acc_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.eve_acc_entries.bus_trans_id', 'accounting', 'eve_acc_entries', 'bus_trans_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.bas_acc_chart.tree_id', 'accounting', 'bas_acc_chart', 'tree_id', true, 'USER-DEFINED');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.parent_id', 'accounting', 'vw_eve_acc_entries', 'parent_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.entry_id', 'accounting', 'vw_eve_acc_entries', 'entry_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.trans_date', 'accounting', 'vw_eve_acc_entries', 'trans_date', true, 'timestamp with time zone');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.occur_date', 'accounting', 'vw_eve_acc_entries', 'occur_date', true, 'timestamp with time zone');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.credit', 'accounting', 'vw_eve_acc_entries', 'credit', true, 'numeric');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.acc_id', 'accounting', 'vw_eve_acc_entries', 'acc_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.entity_id', 'accounting', 'vw_eve_acc_entries', 'entity_id', true, 'integer');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.debit', 'accounting', 'vw_eve_acc_entries', 'debit', true, 'numeric');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.memo', 'accounting', 'vw_eve_acc_entries', 'memo', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.acc_name', 'accounting', 'vw_eve_acc_entries', 'acc_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.entity_name', 'accounting', 'vw_eve_acc_entries', 'entity_name', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.bas_acc_chart.path', 'accounting', 'bas_acc_chart', 'path', true, 'text');
INSERT INTO syslogic.bas_all_columns VALUES ('accounting.vw_eve_acc_entries.path', 'accounting', 'vw_eve_acc_entries', 'path', true, 'text');


--
-- TOC entry 3717 (class 0 OID 38853)
-- Dependencies: 246
-- Data for Name: bas_data_dic; Type: TABLE DATA; Schema: syslogic; Owner: derole
--

INSERT INTO syslogic.bas_data_dic VALUES (264, 'Column accounting.bas_acc_chart.acc_id', 1, 'accounting.bas_acc_chart.acc_id', 'acc_id', 'acc_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (265, 'Column accounting.bas_acc_chart.init_balance', 1, 'accounting.bas_acc_chart.init_balance', 'init_balance', 'init_balance', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (266, 'Column accounting.bas_acc_chart.acc_name', 1, 'accounting.bas_acc_chart.acc_name', 'acc_name', 'acc_name', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (268, 'Column accounting.bas_acc_chart.inactive', 1, 'accounting.bas_acc_chart.inactive', 'inactive', 'inactive', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (270, 'Column accounting.bas_acc_chart.balance', 1, 'accounting.bas_acc_chart.balance', 'balance', 'balance', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (294, 'Column auth.bas_permissions.created_at', 1, 'auth.bas_permissions.created_at', 'created_at', 'created_at', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (295, 'Column auth.bas_permissions.permission_id', 1, 'auth.bas_permissions.permission_id', 'permission_id', 'permission_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (296, 'Column auth.bas_permissions.role_id', 1, 'auth.bas_permissions.role_id', 'role_id', 'role_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (297, 'Column auth.bas_permissions.user_id', 1, 'auth.bas_permissions.user_id', 'user_id', 'user_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (298, 'Column auth.bas_roles.description', 1, 'auth.bas_roles.description', 'description', 'description', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (299, 'Column auth.bas_roles.name', 1, 'auth.bas_roles.name', 'name', 'name', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (300, 'Column auth.bas_roles.role_id', 1, 'auth.bas_roles.role_id', 'role_id', 'role_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (301, 'Column auth.bas_table_permissions.tpermission_id', 1, 'auth.bas_table_permissions.tpermission_id', 'tpermission_id', 'tpermission_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (302, 'Column auth.bas_table_permissions.can_delete', 1, 'auth.bas_table_permissions.can_delete', 'can_delete', 'can_delete', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (303, 'Column auth.bas_table_permissions.can_read', 1, 'auth.bas_table_permissions.can_read', 'can_read', 'can_read', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (304, 'Column auth.bas_table_permissions.role_id', 1, 'auth.bas_table_permissions.role_id', 'role_id', 'role_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (305, 'Column auth.bas_table_permissions.table_id', 1, 'auth.bas_table_permissions.table_id', 'table_id', 'table_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (306, 'Column auth.bas_table_permissions.can_write', 1, 'auth.bas_table_permissions.can_write', 'can_write', 'can_write', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (307, 'Column auth.bas_tables.table_name', 1, 'auth.bas_tables.table_name', 'table_name', 'table_name', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (308, 'Column auth.bas_tables.table_id', 1, 'auth.bas_tables.table_id', 'table_id', 'table_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (309, 'Column auth.bas_users.user_name', 1, 'auth.bas_users.user_name', 'user_name', 'user_name', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (310, 'Column auth.bas_users.user_id', 1, 'auth.bas_users.user_id', 'user_id', 'user_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (311, 'Column auth.bas_users.email', 1, 'auth.bas_users.email', 'email', 'email', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (312, 'Column auth.bas_users.created_at', 1, 'auth.bas_users.created_at', 'created_at', 'created_at', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (313, 'Column auth.bas_users.user_password', 1, 'auth.bas_users.user_password', 'user_password', 'user_password', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (314, 'Column auth.eve_access_tokens.token_id', 1, 'auth.eve_access_tokens.token_id', 'token_id', 'token_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (315, 'Column auth.eve_access_tokens.user_id', 1, 'auth.eve_access_tokens.user_id', 'user_id', 'user_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (316, 'Column auth.eve_access_tokens.token', 1, 'auth.eve_access_tokens.token', 'token', 'token', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (317, 'Column auth.eve_access_tokens.created_at', 1, 'auth.eve_access_tokens.created_at', 'created_at', 'created_at', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (318, 'Column auth.eve_audit_log.created_at', 1, 'auth.eve_audit_log.created_at', 'created_at', 'created_at', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (319, 'Column auth.eve_audit_log.log_id', 1, 'auth.eve_audit_log.log_id', 'log_id', 'log_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (320, 'Column auth.eve_audit_log.user_id', 1, 'auth.eve_audit_log.user_id', 'user_id', 'user_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (321, 'Column auth.eve_audit_log.activity', 1, 'auth.eve_audit_log.activity', 'activity', 'activity', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (322, 'Column auth.eve_refresh_tokens.created_at', 1, 'auth.eve_refresh_tokens.created_at', 'created_at', 'created_at', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (323, 'Column auth.eve_refresh_tokens.user_id', 1, 'auth.eve_refresh_tokens.user_id', 'user_id', 'user_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (324, 'Column auth.eve_refresh_tokens.rtoken_id', 1, 'auth.eve_refresh_tokens.rtoken_id', 'rtoken_id', 'rtoken_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (325, 'Column auth.eve_refresh_tokens.token', 1, 'auth.eve_refresh_tokens.token', 'token', 'token', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (326, 'Column entities.bas_entities.email', 1, 'entities.bas_entities.email', 'email', 'email', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (327, 'Column entities.bas_entities.entity_password', 1, 'entities.bas_entities.entity_password', 'entity_password', 'entity_password', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (328, 'Column entities.bas_entities.entity_parent', 1, 'entities.bas_entities.entity_parent', 'entity_parent', 'entity_parent', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (329, 'Column entities.bas_entities.entity_id', 1, 'entities.bas_entities.entity_id', 'entity_id', 'entity_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (330, 'Column entities.bas_entities.created_at', 1, 'entities.bas_entities.created_at', 'created_at', 'created_at', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (331, 'Column entities.bas_entities.entity_name', 1, 'entities.bas_entities.entity_name', 'entity_name', 'entity_name', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (332, 'Column syslogic.bas_all_columns.data_type', 1, 'syslogic.bas_all_columns.data_type', 'data_type', 'data_type', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (333, 'Column syslogic.bas_all_columns.sch_name', 1, 'syslogic.bas_all_columns.sch_name', 'sch_name', 'sch_name', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (334, 'Column syslogic.bas_all_columns.show_front_end', 1, 'syslogic.bas_all_columns.show_front_end', 'show_front_end', 'show_front_end', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (335, 'Column syslogic.bas_all_columns.text_id', 1, 'syslogic.bas_all_columns.text_id', 'text_id', 'text_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (336, 'Column syslogic.bas_all_columns.tab_name', 1, 'syslogic.bas_all_columns.tab_name', 'tab_name', 'tab_name', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (337, 'Column syslogic.bas_all_columns.col_name', 1, 'syslogic.bas_all_columns.col_name', 'col_name', 'col_name', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (338, 'Column syslogic.bas_data_dic.def_class', 1, 'syslogic.bas_data_dic.def_class', 'def_class', 'def_class', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (339, 'Column syslogic.bas_data_dic.def_id', 1, 'syslogic.bas_data_dic.def_id', 'def_id', 'def_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (340, 'Column syslogic.bas_data_dic.def_name', 1, 'syslogic.bas_data_dic.def_name', 'def_name', 'def_name', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (341, 'Column syslogic.bas_data_dic.col_id', 1, 'syslogic.bas_data_dic.col_id', 'col_id', 'col_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (345, 'Column syslogic.bas_data_dic_class.class_name', 1, 'syslogic.bas_data_dic_class.class_name', 'class_name', 'class_name', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (346, 'Column syslogic.bas_data_dic_class.class_id', 1, 'syslogic.bas_data_dic_class.class_id', 'class_id', 'class_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (342, 'Column syslogic.bas_data_dic.en_us', 1, 'syslogic.bas_data_dic.en_us', 'en_us', 'en_us', true);
INSERT INTO syslogic.bas_data_dic VALUES (344, 'Column syslogic.bas_data_dic.pt_br', 1, 'syslogic.bas_data_dic.pt_br', 'pt_br', 'pt_br', true);
INSERT INTO syslogic.bas_data_dic VALUES (397, 'Column syslogic.bas_data_dic.on_allowed_language_list', 1, 'syslogic.bas_data_dic.on_allowed_language_list', 'on_allowed_language_list', 'on_allowed_language_list', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (383, 'Column syslogic.bas_data_dic_class.Description', 1, 'syslogic.bas_data_dic_class.Description', 'Description', 'Description', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (421, 'Column accounting.eve_acc_entries.debit', 1, 'accounting.eve_acc_entries.debit', 'Debit', 'debit', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (422, 'Column accounting.eve_acc_entries.credit', 1, 'accounting.eve_acc_entries.credit', 'Credit', 'credit', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (423, 'Column accounting.eve_acc_entries.entry_id', 1, 'accounting.eve_acc_entries.entry_id', 'Entry ID', 'entry_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (424, 'Column accounting.eve_bus_transactions.trans_date', 1, 'accounting.eve_bus_transactions.trans_date', 'Transaction Date', 'trans_date', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (426, 'Column accounting.eve_bus_transactions.memo', 1, 'accounting.eve_bus_transactions.memo', 'Memo', 'memo', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (427, 'Column accounting.eve_bus_transactions.entity_id', 1, 'accounting.eve_bus_transactions.entity_id', 'Entity', 'entity_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (428, 'Column accounting.eve_bus_transactions.trans_id', 1, 'accounting.eve_bus_transactions.trans_id', 'Transaction ID', 'trans_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (429, 'Column accounting.eve_bus_transactions.occur_date', 1, 'accounting.eve_bus_transactions.occur_date', 'Occur Date', 'occur_date', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (431, 'Column accounting.eve_acc_entries.acc_id', 1, 'accounting.eve_acc_entries.acc_id', 'Account', 'acc_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (432, 'Column accounting.eve_acc_entries.bus_trans_id', 1, 'accounting.eve_acc_entries.bus_trans_id', 'Transaction ID', 'bus_trans_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (481, 'Column accounting.bas_acc_chart.tree_id', 1, 'accounting.bas_acc_chart.tree_id', 'tree_id', 'tree_id', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (493, 'Column accounting.vw_eve_acc_entries.parent_id', 1, 'accounting.vw_eve_acc_entries.parent_id', 'Transaction', 'Transação', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (494, 'Column accounting.vw_eve_acc_entries.entry_id', 1, 'accounting.vw_eve_acc_entries.entry_id', 'Entry Id', 'Nº do Registro', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (495, 'Column accounting.vw_eve_acc_entries.trans_date', 1, 'accounting.vw_eve_acc_entries.trans_date', 'Transaction Date', 'Data da Transação', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (496, 'Column accounting.vw_eve_acc_entries.occur_date', 1, 'accounting.vw_eve_acc_entries.occur_date', 'Occurrence Date', 'Data da Ocorrência', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (497, 'Column accounting.vw_eve_acc_entries.credit', 1, 'accounting.vw_eve_acc_entries.credit', 'Source', 'Origem', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (498, 'Column accounting.vw_eve_acc_entries.acc_id', 1, 'accounting.vw_eve_acc_entries.acc_id', 'Account ID', 'ID da Conta', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (499, 'Column accounting.vw_eve_acc_entries.entity_id', 1, 'accounting.vw_eve_acc_entries.entity_id', 'Entity ID', 'ID da Entidade', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (501, 'Column accounting.vw_eve_acc_entries.memo', 1, 'accounting.vw_eve_acc_entries.memo', 'Memo', 'Descrição', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (502, 'Column accounting.vw_eve_acc_entries.acc_name', 1, 'accounting.vw_eve_acc_entries.acc_name', 'Account', 'Conta', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (503, 'Column accounting.vw_eve_acc_entries.entity_name', 1, 'accounting.vw_eve_acc_entries.entity_name', 'Entity', 'Entidade', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (500, 'Column accounting.vw_eve_acc_entries.debit', 1, 'accounting.vw_eve_acc_entries.debit', 'Destination', 'Destino', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (504, 'Column accounting.bas_acc_chart.path', 1, 'accounting.bas_acc_chart.path', 'Path', 'Path', NULL);
INSERT INTO syslogic.bas_data_dic VALUES (505, 'Column accounting.vw_eve_acc_entries.path', 1, 'accounting.vw_eve_acc_entries.path', 'Acc Position', 'Posição da Conta', NULL);


--
-- TOC entry 3718 (class 0 OID 38858)
-- Dependencies: 247
-- Data for Name: bas_data_dic_class; Type: TABLE DATA; Schema: syslogic; Owner: derole
--

INSERT INTO syslogic.bas_data_dic_class VALUES (1, 'Column Name', 'Columns'' names in the database tables. It doesn''t include tables created on frontend.');
INSERT INTO syslogic.bas_data_dic_class VALUES (2, 'Basic Interface Object', 'Buttons, labels, titles etc.');


--
-- TOC entry 3754 (class 0 OID 0)
-- Dependencies: 220
-- Name: bas_acc_chart_acc_id_seq; Type: SEQUENCE SET; Schema: accounting; Owner: derole
--

SELECT pg_catalog.setval('accounting.bas_acc_chart_acc_id_seq', 227, true);


--
-- TOC entry 3755 (class 0 OID 0)
-- Dependencies: 222
-- Name: eve_acc_entries_entry_id_seq; Type: SEQUENCE SET; Schema: accounting; Owner: derole
--

SELECT pg_catalog.setval('accounting.eve_acc_entries_entry_id_seq', 0, true);


--
-- TOC entry 3756 (class 0 OID 0)
-- Dependencies: 224
-- Name: eve_bus_transactions_trans_id_seq; Type: SEQUENCE SET; Schema: accounting; Owner: derole
--

SELECT pg_catalog.setval('accounting.eve_bus_transactions_trans_id_seq', 0, true);


--
-- TOC entry 3757 (class 0 OID 0)
-- Dependencies: 227
-- Name: bas_permissions_permission_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.bas_permissions_permission_id_seq', 1, false);


--
-- TOC entry 3758 (class 0 OID 0)
-- Dependencies: 229
-- Name: bas_roles_role_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.bas_roles_role_id_seq', 1, false);


--
-- TOC entry 3759 (class 0 OID 0)
-- Dependencies: 231
-- Name: bas_table_permissions_tpermission_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.bas_table_permissions_tpermission_id_seq', 1, false);


--
-- TOC entry 3760 (class 0 OID 0)
-- Dependencies: 233
-- Name: bas_tables_table_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.bas_tables_table_id_seq', 1, false);


--
-- TOC entry 3761 (class 0 OID 0)
-- Dependencies: 235
-- Name: bas_users_user_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.bas_users_user_id_seq', 1, true);


--
-- TOC entry 3762 (class 0 OID 0)
-- Dependencies: 237
-- Name: eve_access_tokens_token_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.eve_access_tokens_token_id_seq', 1, false);


--
-- TOC entry 3763 (class 0 OID 0)
-- Dependencies: 239
-- Name: eve_audit_log_log_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.eve_audit_log_log_id_seq', 1, false);


--
-- TOC entry 3764 (class 0 OID 0)
-- Dependencies: 241
-- Name: eve_refresh_tokens_rtoken_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: derole
--

SELECT pg_catalog.setval('auth.eve_refresh_tokens_rtoken_id_seq', 1, false);


--
-- TOC entry 3765 (class 0 OID 0)
-- Dependencies: 242
-- Name: bas_entities_entity_id_seq; Type: SEQUENCE SET; Schema: entities; Owner: derole
--

SELECT pg_catalog.setval('entities.bas_entities_entity_id_seq', 34, true);


--
-- TOC entry 3766 (class 0 OID 0)
-- Dependencies: 244
-- Name: todos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: derole
--

SELECT pg_catalog.setval('public.todos_id_seq', 20, true);


--
-- TOC entry 3767 (class 0 OID 0)
-- Dependencies: 248
-- Name: bas_data_dic_class_class_id_seq; Type: SEQUENCE SET; Schema: syslogic; Owner: derole
--

SELECT pg_catalog.setval('syslogic.bas_data_dic_class_class_id_seq', 2, true);


--
-- TOC entry 3768 (class 0 OID 0)
-- Dependencies: 249
-- Name: bas_data_dic_def_id_seq; Type: SEQUENCE SET; Schema: syslogic; Owner: derole
--

SELECT pg_catalog.setval('syslogic.bas_data_dic_def_id_seq', 505, true);


--
-- TOC entry 3502 (class 2606 OID 38881)
-- Name: bas_acc_chart bas_acc_chart_pkey; Type: CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.bas_acc_chart
    ADD CONSTRAINT bas_acc_chart_pkey PRIMARY KEY (acc_id);


--
-- TOC entry 3504 (class 2606 OID 38883)
-- Name: eve_acc_entries eve_acc_entries_pkey; Type: CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_acc_entries
    ADD CONSTRAINT eve_acc_entries_pkey PRIMARY KEY (entry_id);


--
-- TOC entry 3506 (class 2606 OID 38885)
-- Name: eve_bus_transactions eve_bus_transactions_pkey; Type: CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_bus_transactions
    ADD CONSTRAINT eve_bus_transactions_pkey PRIMARY KEY (trans_id);


--
-- TOC entry 3510 (class 2606 OID 38887)
-- Name: bas_permissions bas_permissions_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_permissions
    ADD CONSTRAINT bas_permissions_pkey PRIMARY KEY (permission_id);


--
-- TOC entry 3512 (class 2606 OID 38889)
-- Name: bas_roles bas_roles_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_roles
    ADD CONSTRAINT bas_roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 3514 (class 2606 OID 38891)
-- Name: bas_table_permissions bas_table_permissions_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_pkey PRIMARY KEY (tpermission_id);


--
-- TOC entry 3516 (class 2606 OID 38893)
-- Name: bas_tables bas_tables_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_tables
    ADD CONSTRAINT bas_tables_pkey PRIMARY KEY (table_id);


--
-- TOC entry 3518 (class 2606 OID 38895)
-- Name: bas_users bas_users_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_users
    ADD CONSTRAINT bas_users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3520 (class 2606 OID 38897)
-- Name: eve_access_tokens eve_access_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_access_tokens
    ADD CONSTRAINT eve_access_tokens_pkey PRIMARY KEY (token_id);


--
-- TOC entry 3522 (class 2606 OID 38899)
-- Name: eve_audit_log eve_audit_log_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_audit_log
    ADD CONSTRAINT eve_audit_log_pkey PRIMARY KEY (log_id);


--
-- TOC entry 3524 (class 2606 OID 38901)
-- Name: eve_refresh_tokens eve_refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_refresh_tokens
    ADD CONSTRAINT eve_refresh_tokens_pkey PRIMARY KEY (rtoken_id);


--
-- TOC entry 3508 (class 2606 OID 38903)
-- Name: bas_entities bas_entities_pkey; Type: CONSTRAINT; Schema: entities; Owner: derole
--

ALTER TABLE ONLY entities.bas_entities
    ADD CONSTRAINT bas_entities_pkey PRIMARY KEY (entity_id);


--
-- TOC entry 3526 (class 2606 OID 38905)
-- Name: todos todos_pkey; Type: CONSTRAINT; Schema: public; Owner: derole
--

ALTER TABLE ONLY public.todos
    ADD CONSTRAINT todos_pkey PRIMARY KEY (id);


--
-- TOC entry 3528 (class 2606 OID 38907)
-- Name: bas_all_columns bas_all_columns_pkey; Type: CONSTRAINT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_all_columns
    ADD CONSTRAINT bas_all_columns_pkey PRIMARY KEY (text_id);


--
-- TOC entry 3532 (class 2606 OID 38909)
-- Name: bas_data_dic_class bas_data_dic_class_pkey; Type: CONSTRAINT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_data_dic_class
    ADD CONSTRAINT bas_data_dic_class_pkey PRIMARY KEY (class_id);


--
-- TOC entry 3530 (class 2606 OID 38911)
-- Name: bas_data_dic bas_data_dic_pkey; Type: CONSTRAINT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_data_dic
    ADD CONSTRAINT bas_data_dic_pkey PRIMARY KEY (def_id);


--
-- TOC entry 3542 (class 2620 OID 39078)
-- Name: bas_acc_chart bas_acc_chart_delete_cascade_after_delete_trigger; Type: TRIGGER; Schema: accounting; Owner: derole
--

CREATE TRIGGER bas_acc_chart_delete_cascade_after_delete_trigger AFTER DELETE ON accounting.bas_acc_chart FOR EACH ROW EXECUTE FUNCTION accounting.bas_acc_chart_delete_cascade_after_delete();


--
-- TOC entry 3543 (class 2620 OID 39083)
-- Name: bas_acc_chart bas_acc_chart_update_children_after_update_parent_trigger; Type: TRIGGER; Schema: accounting; Owner: derole
--

CREATE TRIGGER bas_acc_chart_update_children_after_update_parent_trigger AFTER UPDATE ON accounting.bas_acc_chart FOR EACH ROW WHEN ((old.path <> new.path)) EXECUTE FUNCTION accounting.bas_acc_chart_update_children_after_update_parent();


--
-- TOC entry 3544 (class 2620 OID 39081)
-- Name: bas_acc_chart bas_acc_chart_update_path_before_insert_or_update_trigger; Type: TRIGGER; Schema: accounting; Owner: derole
--

CREATE TRIGGER bas_acc_chart_update_path_before_insert_or_update_trigger BEFORE INSERT OR UPDATE ON accounting.bas_acc_chart FOR EACH ROW EXECUTE FUNCTION accounting.bas_acc_chart_update_path_before_insert_or_update();


--
-- TOC entry 3545 (class 2620 OID 38912)
-- Name: bas_all_columns delete_bas_data_dic_trigger; Type: TRIGGER; Schema: syslogic; Owner: derole
--

CREATE TRIGGER delete_bas_data_dic_trigger AFTER DELETE ON syslogic.bas_all_columns FOR EACH ROW EXECUTE FUNCTION syslogic.delete_bas_data_dic();


--
-- TOC entry 3546 (class 2620 OID 38913)
-- Name: bas_all_columns insert_bas_data_dic_trigger; Type: TRIGGER; Schema: syslogic; Owner: derole
--

CREATE TRIGGER insert_bas_data_dic_trigger AFTER INSERT ON syslogic.bas_all_columns FOR EACH ROW EXECUTE FUNCTION syslogic.insert_bas_data_dic();


--
-- TOC entry 3533 (class 2606 OID 38914)
-- Name: eve_acc_entries eve_acc_entries_bus_trans_id_fkey; Type: FK CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_acc_entries
    ADD CONSTRAINT eve_acc_entries_bus_trans_id_fkey FOREIGN KEY (bus_trans_id) REFERENCES accounting.eve_bus_transactions(trans_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3534 (class 2606 OID 38919)
-- Name: eve_bus_transactions eve_bus_transactions_entity_id_fkey; Type: FK CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_bus_transactions
    ADD CONSTRAINT eve_bus_transactions_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entities.bas_entities(entity_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3535 (class 2606 OID 38924)
-- Name: bas_permissions bas_permissions_entity_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_permissions
    ADD CONSTRAINT bas_permissions_entity_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) NOT VALID;


--
-- TOC entry 3536 (class 2606 OID 38929)
-- Name: bas_table_permissions bas_table_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES auth.bas_roles(role_id) ON DELETE CASCADE;


--
-- TOC entry 3537 (class 2606 OID 38934)
-- Name: bas_table_permissions bas_table_permissions_table_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_table_id_fkey FOREIGN KEY (table_id) REFERENCES auth.bas_tables(table_id) ON DELETE CASCADE;


--
-- TOC entry 3538 (class 2606 OID 38939)
-- Name: eve_access_tokens eve_access_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_access_tokens
    ADD CONSTRAINT eve_access_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3539 (class 2606 OID 38944)
-- Name: eve_audit_log eve_audit_log_entity_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_audit_log
    ADD CONSTRAINT eve_audit_log_entity_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) NOT VALID;


--
-- TOC entry 3540 (class 2606 OID 38949)
-- Name: eve_refresh_tokens eve_refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_refresh_tokens
    ADD CONSTRAINT eve_refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3541 (class 2606 OID 38954)
-- Name: bas_data_dic bas_data_dic_col_id_fkey; Type: FK CONSTRAINT; Schema: syslogic; Owner: derole
--

ALTER TABLE ONLY syslogic.bas_data_dic
    ADD CONSTRAINT bas_data_dic_col_id_fkey FOREIGN KEY (col_id) REFERENCES syslogic.bas_all_columns(text_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3728 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 3471 (class 3466 OID 38975)
-- Name: sync_bas_all_columns_event; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER sync_bas_all_columns_event ON ddl_command_end
         WHEN TAG IN ('ALTER TABLE', 'CREATE TABLE', 'DROP TABLE')
   EXECUTE FUNCTION public.sync_bas_all_columns_trigger();


ALTER EVENT TRIGGER sync_bas_all_columns_event OWNER TO postgres;

-- Completed on 2023-08-22 15:58:59 -03

--
-- PostgreSQL database dump complete
--

