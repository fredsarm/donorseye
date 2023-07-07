--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3 (Ubuntu 15.3-1.pgdg23.04+1)
-- Dumped by pg_dump version 15.3 (Ubuntu 15.3-1.pgdg23.04+1)

-- Started on 2023-07-07 18:11:18 -03

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
-- TOC entry 3635 (class 1262 OID 27601)
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
-- TOC entry 7 (class 2615 OID 27602)
-- Name: accounting; Type: SCHEMA; Schema: -; Owner: derole
--

CREATE SCHEMA accounting;


ALTER SCHEMA accounting OWNER TO derole;

--
-- TOC entry 9 (class 2615 OID 27604)
-- Name: auth; Type: SCHEMA; Schema: -; Owner: derole
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO derole;

--
-- TOC entry 8 (class 2615 OID 27603)
-- Name: entities; Type: SCHEMA; Schema: -; Owner: derole
--

CREATE SCHEMA entities;


ALTER SCHEMA entities OWNER TO derole;

--
-- TOC entry 2 (class 3079 OID 27605)
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- TOC entry 3636 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 27801)
-- Name: bas_acc_chart; Type: TABLE; Schema: accounting; Owner: derole
--

CREATE TABLE accounting.bas_acc_chart (
    name text,
    acc_id smallint NOT NULL,
    acc_parent smallint NOT NULL,
    acc_path public.ltree,
    acc_order smallint NOT NULL,
    acc_name text,
    init_balance numeric(12,2) DEFAULT 0 NOT NULL,
    balance numeric(12,2) DEFAULT 0 NOT NULL,
    inactive boolean DEFAULT false NOT NULL
);


ALTER TABLE accounting.bas_acc_chart OWNER TO derole;

--
-- TOC entry 3637 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE bas_acc_chart; Type: COMMENT; Schema: accounting; Owner: derole
--

COMMENT ON TABLE accounting.bas_acc_chart IS 'Rules:

    It is prohibited to change the first level of the account. An account belonging to an asset must remain as it is and cannot be altered with the code of the first level, such as using the number 1, for example. The same applies to other accounts: the first level of the code cannot be changed.
    It is prohibited to delete the level 1 of any account.
    It is prohibited to create any account with only the first level (creating new trees is forbidden).
    It is prohibited to update an account in a way that it becomes a descendant of itself.';


--
-- TOC entry 221 (class 1259 OID 27809)
-- Name: bas_acc_chart_acc_id_seq; Type: SEQUENCE; Schema: accounting; Owner: derole
--

CREATE SEQUENCE accounting.bas_acc_chart_acc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE accounting.bas_acc_chart_acc_id_seq OWNER TO derole;

--
-- TOC entry 3638 (class 0 OID 0)
-- Dependencies: 221
-- Name: bas_acc_chart_acc_id_seq; Type: SEQUENCE OWNED BY; Schema: accounting; Owner: derole
--

ALTER SEQUENCE accounting.bas_acc_chart_acc_id_seq OWNED BY accounting.bas_acc_chart.acc_id;


--
-- TOC entry 218 (class 1259 OID 27790)
-- Name: eve_entries; Type: TABLE; Schema: accounting; Owner: derole
--

CREATE TABLE accounting.eve_entries (
    entry_id integer NOT NULL,
    entry_date timestamp(0) without time zone DEFAULT (CURRENT_TIMESTAMP)::timestamp without time zone NOT NULL,
    occur_date date,
    acc_id integer DEFAULT 1 NOT NULL,
    entry_parent integer,
    entity_id integer NOT NULL,
    user_id integer NOT NULL,
    memo text,
    debit numeric(20,2) DEFAULT 0 NOT NULL,
    credit numeric(20,2) DEFAULT 0 NOT NULL,
    balance numeric(20,2) DEFAULT 0 NOT NULL
);


ALTER TABLE accounting.eve_entries OWNER TO derole;

--
-- TOC entry 219 (class 1259 OID 27800)
-- Name: eve_entries_entry_id_seq; Type: SEQUENCE; Schema: accounting; Owner: derole
--

CREATE SEQUENCE accounting.eve_entries_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE accounting.eve_entries_entry_id_seq OWNER TO derole;

--
-- TOC entry 3639 (class 0 OID 0)
-- Dependencies: 219
-- Name: eve_entries_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: accounting; Owner: derole
--

ALTER SEQUENCE accounting.eve_entries_entry_id_seq OWNED BY accounting.eve_entries.entry_id;


--
-- TOC entry 230 (class 1259 OID 27834)
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
-- TOC entry 3640 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE bas_permissions; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.bas_permissions IS 'Descrição: Essa tabela representa as permissões atribuídas a uma entidade (usuário) específica em relação a determinados recursos ou funcionalidades do sistema.

Integração: A tabela possui duas chaves estrangeiras: entity_id, que referencia a tabela entities.bas_entities, e role_id, que referencia a tabela entities.bas_roles. Isso permite relacionar uma entidade a um papel específico e, assim, determinar suas permissões.

Exemplos de uso: A tabela é utilizada para gerenciar as permissões de cada entidade (usuário) em relação a recursos ou funcionalidades específicas do sistema. Com base nas permissões atribuídas, é possível controlar o acesso dos usuários a determinadas partes do sistema.';


--
-- TOC entry 231 (class 1259 OID 27838)
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
-- TOC entry 3641 (class 0 OID 0)
-- Dependencies: 231
-- Name: bas_permissions_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_permissions_permission_id_seq OWNED BY auth.bas_permissions.permission_id;


--
-- TOC entry 232 (class 1259 OID 27839)
-- Name: bas_roles; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.bas_roles (
    role_id integer NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE auth.bas_roles OWNER TO derole;

--
-- TOC entry 3642 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE bas_roles; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.bas_roles IS 'Descrição: Essa tabela armazena os diferentes papéis ou funções atribuídos aos usuários do sistema.

Integração: A tabela é referenciada pela tabela auth.bas_permissions por meio da chave primária id, permitindo que cada permissão seja associada a um papel específico.

Exemplos de uso: A tabela é utilizada para definir e gerenciar os papéis disponíveis no sistema. Os papéis podem ter diferentes níveis de autoridade e acesso, permitindo controlar quais recursos e funcionalidades os usuários podem acessar com base no papel atribuído a eles.';


--
-- TOC entry 233 (class 1259 OID 27844)
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
-- TOC entry 3643 (class 0 OID 0)
-- Dependencies: 233
-- Name: bas_roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_roles_role_id_seq OWNED BY auth.bas_roles.role_id;


--
-- TOC entry 234 (class 1259 OID 27845)
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
-- TOC entry 235 (class 1259 OID 27848)
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
-- TOC entry 3644 (class 0 OID 0)
-- Dependencies: 235
-- Name: bas_table_permissions_tpermission_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_table_permissions_tpermission_id_seq OWNED BY auth.bas_table_permissions.tpermission_id;


--
-- TOC entry 236 (class 1259 OID 27849)
-- Name: bas_tables; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.bas_tables (
    table_id integer NOT NULL,
    table_name character varying(255) NOT NULL
);


ALTER TABLE auth.bas_tables OWNER TO derole;

--
-- TOC entry 237 (class 1259 OID 27852)
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
-- TOC entry 3645 (class 0 OID 0)
-- Dependencies: 237
-- Name: bas_tables_table_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_tables_table_id_seq OWNED BY auth.bas_tables.table_id;


--
-- TOC entry 238 (class 1259 OID 27853)
-- Name: bas_users; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.bas_users (
    user_id integer NOT NULL,
    user_name text NOT NULL,
    user_password character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auth.bas_users OWNER TO derole;

--
-- TOC entry 3646 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE bas_users; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.bas_users IS 'Descrição: Essa tabela armazena as informações básicas das entidades (usuários) registradas no sistema, como nome, email, senha e data de criação.
Integração: A tabela é a principal tabela de entidades do sistema e é referenciada por outras tabelas, como auth.eve_access_tokens e auth.bas_permissions, por meio da chave primária id.
Exemplos de uso: A tabela é utilizada para armazenar e gerenciar as informações básicas de cada entidade (usuário) registrada no sistema. Ela serve como base para a autenticação, autorização e outras funcionalidades relacionadas aos usuários.';


--
-- TOC entry 239 (class 1259 OID 27859)
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
-- TOC entry 3647 (class 0 OID 0)
-- Dependencies: 239
-- Name: bas_users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.bas_users_user_id_seq OWNED BY auth.bas_users.user_id;


--
-- TOC entry 224 (class 1259 OID 27817)
-- Name: eve_access_tokens; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.eve_access_tokens (
    token_id integer NOT NULL,
    token character varying(255) NOT NULL,
    user_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auth.eve_access_tokens OWNER TO derole;

--
-- TOC entry 3648 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE eve_access_tokens; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.eve_access_tokens IS 'Descrição: Esta tabela armazena os tokens de acesso gerados para autenticar e autorizar as entidades (usuários) no sistema.

Integração: A tabela possui uma chave estrangeira user_id que referencia a tabela entities.bas_entities, estabelecendo uma relação entre o token de acesso e o usuário associado.

Exemplos de uso: A tabela é utilizada para armazenar e validar os tokens de acesso durante o processo de autenticação. É possível consultar essa tabela para verificar se um token de acesso é válido e obter o ID do usuário correspondente.';


--
-- TOC entry 225 (class 1259 OID 27821)
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
-- TOC entry 3649 (class 0 OID 0)
-- Dependencies: 225
-- Name: eve_access_tokens_token_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.eve_access_tokens_token_id_seq OWNED BY auth.eve_access_tokens.token_id;


--
-- TOC entry 228 (class 1259 OID 27827)
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
-- TOC entry 3650 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE eve_audit_log; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.eve_audit_log IS 'Descrição: Esta tabela registra as atividades e ações realizadas no sistema, permitindo rastrear e auditar as operações.
Integração: A tabela possui uma chave estrangeira entity_id que referencia a tabela entities.bas_entities, permitindo relacionar uma atividade registrada com a entidade (usuário) associada à ação.
Exemplos de uso: A tabela é utilizada para registrar informações relevantes sobre atividades específicas, como criação, atualização ou exclusão de registros. Isso permite acompanhar as alterações feitas no sistema e, se necessário, identificar as entidades (usuários) envolvidas nas ações.';


--
-- TOC entry 229 (class 1259 OID 27833)
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
-- TOC entry 3651 (class 0 OID 0)
-- Dependencies: 229
-- Name: eve_audit_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.eve_audit_log_log_id_seq OWNED BY auth.eve_audit_log.log_id;


--
-- TOC entry 226 (class 1259 OID 27822)
-- Name: eve_refresh_tokens; Type: TABLE; Schema: auth; Owner: derole
--

CREATE TABLE auth.eve_refresh_tokens (
    rtoken_id integer NOT NULL,
    token character varying(255) NOT NULL,
    user_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auth.eve_refresh_tokens OWNER TO derole;

--
-- TOC entry 3652 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE eve_refresh_tokens; Type: COMMENT; Schema: auth; Owner: derole
--

COMMENT ON TABLE auth.eve_refresh_tokens IS 'Descrição: Essa tabela armazena os tokens de atualização usados para renovar os tokens de acesso expirados sem a necessidade de fazer login novamente.

Integração: A tabela possui uma chave estrangeira user_id que referencia a tabela entities.bas_entities, estabelecendo uma relação entre o token de atualização e o usuário associado.

Exemplos de uso: Durante o processo de renovação do token de acesso, a tabela é consultada para verificar se um token de atualização é válido e obter o ID do usuário correspondente. Com base nessas informações, um novo token de acesso pode ser emitido.';


--
-- TOC entry 227 (class 1259 OID 27826)
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
-- TOC entry 3653 (class 0 OID 0)
-- Dependencies: 227
-- Name: eve_refresh_tokens_rtoken_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: derole
--

ALTER SEQUENCE auth.eve_refresh_tokens_rtoken_id_seq OWNED BY auth.eve_refresh_tokens.rtoken_id;


--
-- TOC entry 222 (class 1259 OID 27810)
-- Name: bas_entities; Type: TABLE; Schema: entities; Owner: derole
--

CREATE TABLE entities.bas_entities (
    entity_id integer NOT NULL,
    entity_name text NOT NULL,
    entity_parent bigint,
    entity_password character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE entities.bas_entities OWNER TO derole;

--
-- TOC entry 3654 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE bas_entities; Type: COMMENT; Schema: entities; Owner: derole
--

COMMENT ON TABLE entities.bas_entities IS 'Descrição: Essa tabela armazena as informações básicas das entidades (usuários) registradas no sistema, como nome, email, senha e data de criação.

Integração: A tabela é a principal tabela de entidades do sistema e é referenciada por outras tabelas, como auth.eve_access_tokens e auth.bas_permissions, por meio da chave primária id.

Exemplos de uso: A tabela é utilizada para armazenar e gerenciar as informações básicas de cada entidade (usuário) registrada no sistema. Ela serve como base para a autenticação, autorização e outras funcionalidades relacionadas aos usuários.';


--
-- TOC entry 223 (class 1259 OID 27816)
-- Name: bas_entities_entity_id_seq; Type: SEQUENCE; Schema: entities; Owner: derole
--

CREATE SEQUENCE entities.bas_entities_entity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities.bas_entities_entity_id_seq OWNER TO derole;

--
-- TOC entry 3655 (class 0 OID 0)
-- Dependencies: 223
-- Name: bas_entities_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: derole
--

ALTER SEQUENCE entities.bas_entities_entity_id_seq OWNED BY entities.bas_entities.entity_id;


--
-- TOC entry 3442 (class 2604 OID 27862)
-- Name: bas_acc_chart acc_id; Type: DEFAULT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.bas_acc_chart ALTER COLUMN acc_id SET DEFAULT nextval('accounting.bas_acc_chart_acc_id_seq'::regclass);


--
-- TOC entry 3436 (class 2604 OID 27861)
-- Name: eve_entries entry_id; Type: DEFAULT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_entries ALTER COLUMN entry_id SET DEFAULT nextval('accounting.eve_entries_entry_id_seq'::regclass);


--
-- TOC entry 3454 (class 2604 OID 27867)
-- Name: bas_permissions permission_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_permissions ALTER COLUMN permission_id SET DEFAULT nextval('auth.bas_permissions_permission_id_seq'::regclass);


--
-- TOC entry 3456 (class 2604 OID 27868)
-- Name: bas_roles role_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_roles ALTER COLUMN role_id SET DEFAULT nextval('auth.bas_roles_role_id_seq'::regclass);


--
-- TOC entry 3457 (class 2604 OID 27869)
-- Name: bas_table_permissions tpermission_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions ALTER COLUMN tpermission_id SET DEFAULT nextval('auth.bas_table_permissions_tpermission_id_seq'::regclass);


--
-- TOC entry 3458 (class 2604 OID 27870)
-- Name: bas_tables table_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_tables ALTER COLUMN table_id SET DEFAULT nextval('auth.bas_tables_table_id_seq'::regclass);


--
-- TOC entry 3459 (class 2604 OID 27860)
-- Name: bas_users user_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_users ALTER COLUMN user_id SET DEFAULT nextval('auth.bas_users_user_id_seq'::regclass);


--
-- TOC entry 3448 (class 2604 OID 27864)
-- Name: eve_access_tokens token_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_access_tokens ALTER COLUMN token_id SET DEFAULT nextval('auth.eve_access_tokens_token_id_seq'::regclass);


--
-- TOC entry 3452 (class 2604 OID 27866)
-- Name: eve_audit_log log_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_audit_log ALTER COLUMN log_id SET DEFAULT nextval('auth.eve_audit_log_log_id_seq'::regclass);


--
-- TOC entry 3450 (class 2604 OID 27865)
-- Name: eve_refresh_tokens rtoken_id; Type: DEFAULT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_refresh_tokens ALTER COLUMN rtoken_id SET DEFAULT nextval('auth.eve_refresh_tokens_rtoken_id_seq'::regclass);


--
-- TOC entry 3446 (class 2604 OID 27863)
-- Name: bas_entities entity_id; Type: DEFAULT; Schema: entities; Owner: derole
--

ALTER TABLE ONLY entities.bas_entities ALTER COLUMN entity_id SET DEFAULT nextval('entities.bas_entities_entity_id_seq'::regclass);


--
-- TOC entry 3462 (class 2606 OID 27872)
-- Name: eve_entries eve_entries_pkey; Type: CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_entries
    ADD CONSTRAINT eve_entries_pkey PRIMARY KEY (entry_id);


--
-- TOC entry 3472 (class 2606 OID 27882)
-- Name: bas_permissions bas_permissions_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_permissions
    ADD CONSTRAINT bas_permissions_pkey PRIMARY KEY (permission_id);


--
-- TOC entry 3474 (class 2606 OID 27884)
-- Name: bas_roles bas_roles_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_roles
    ADD CONSTRAINT bas_roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 3476 (class 2606 OID 27886)
-- Name: bas_table_permissions bas_table_permissions_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_pkey PRIMARY KEY (tpermission_id);


--
-- TOC entry 3478 (class 2606 OID 27888)
-- Name: bas_tables bas_tables_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_tables
    ADD CONSTRAINT bas_tables_pkey PRIMARY KEY (table_id);


--
-- TOC entry 3480 (class 2606 OID 27890)
-- Name: bas_users bas_users_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_users
    ADD CONSTRAINT bas_users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3466 (class 2606 OID 27876)
-- Name: eve_access_tokens eve_access_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_access_tokens
    ADD CONSTRAINT eve_access_tokens_pkey PRIMARY KEY (token_id);


--
-- TOC entry 3470 (class 2606 OID 27880)
-- Name: eve_audit_log eve_audit_log_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_audit_log
    ADD CONSTRAINT eve_audit_log_pkey PRIMARY KEY (log_id);


--
-- TOC entry 3468 (class 2606 OID 27878)
-- Name: eve_refresh_tokens eve_refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_refresh_tokens
    ADD CONSTRAINT eve_refresh_tokens_pkey PRIMARY KEY (rtoken_id);


--
-- TOC entry 3464 (class 2606 OID 27874)
-- Name: bas_entities bas_entities_pkey; Type: CONSTRAINT; Schema: entities; Owner: derole
--

ALTER TABLE ONLY entities.bas_entities
    ADD CONSTRAINT bas_entities_pkey PRIMARY KEY (entity_id);


--
-- TOC entry 3481 (class 2606 OID 27891)
-- Name: eve_entries fk_eve_entries_acc_id; Type: FK CONSTRAINT; Schema: accounting; Owner: derole
--

ALTER TABLE ONLY accounting.eve_entries
    ADD CONSTRAINT fk_eve_entries_acc_id FOREIGN KEY (acc_id) REFERENCES entities.bas_entities(entity_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3485 (class 2606 OID 27911)
-- Name: bas_permissions bas_permissions_entity_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_permissions
    ADD CONSTRAINT bas_permissions_entity_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) NOT VALID;


--
-- TOC entry 3486 (class 2606 OID 27916)
-- Name: bas_table_permissions bas_table_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES auth.bas_roles(role_id) ON DELETE CASCADE;


--
-- TOC entry 3487 (class 2606 OID 27921)
-- Name: bas_table_permissions bas_table_permissions_table_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_table_id_fkey FOREIGN KEY (table_id) REFERENCES auth.bas_tables(table_id) ON DELETE CASCADE;


--
-- TOC entry 3482 (class 2606 OID 27896)
-- Name: eve_access_tokens eve_access_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_access_tokens
    ADD CONSTRAINT eve_access_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3484 (class 2606 OID 27906)
-- Name: eve_audit_log eve_audit_log_entity_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_audit_log
    ADD CONSTRAINT eve_audit_log_entity_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) NOT VALID;


--
-- TOC entry 3483 (class 2606 OID 27901)
-- Name: eve_refresh_tokens eve_refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: derole
--

ALTER TABLE ONLY auth.eve_refresh_tokens
    ADD CONSTRAINT eve_refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


-- Completed on 2023-07-07 18:11:18 -03

--
-- PostgreSQL database dump complete
--

