--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3 (Ubuntu 15.3-1.pgdg23.04+1)
-- Dumped by pg_dump version 15.3 (Ubuntu 15.3-1.pgdg23.04+1)

-- Started on 2023-07-06 19:11:21 -03

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
-- TOC entry 8 (class 2615 OID 25503)
-- Name: bookkeeping; Type: SCHEMA; Schema: -; Owner: frederico
--

CREATE SCHEMA bookkeeping;


ALTER SCHEMA bookkeeping OWNER TO frederico;

--
-- TOC entry 7 (class 2615 OID 25484)
-- Name: entities; Type: SCHEMA; Schema: -; Owner: frederico
--

CREATE SCHEMA entities;


ALTER SCHEMA entities OWNER TO frederico;

--
-- TOC entry 9 (class 2615 OID 25856)
-- Name: security; Type: SCHEMA; Schema: -; Owner: frederico
--

CREATE SCHEMA security;


ALTER SCHEMA security OWNER TO frederico;

--
-- TOC entry 2 (class 3079 OID 25504)
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- TOC entry 3633 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 222 (class 1259 OID 25732)
-- Name: entries; Type: TABLE; Schema: bookkeeping; Owner: frederico
--

CREATE TABLE bookkeeping.entries (
    id integer NOT NULL,
    entry_date timestamp(0) without time zone DEFAULT (CURRENT_TIMESTAMP)::timestamp without time zone NOT NULL,
    occur_date date,
    account_id integer DEFAULT 1 NOT NULL,
    parent_entry integer,
    entity_id integer NOT NULL,
    user_id integer NOT NULL,
    memo text,
    debit numeric(20,2) DEFAULT 0 NOT NULL,
    credit numeric(20,2) DEFAULT 0 NOT NULL,
    balance numeric(20,2) DEFAULT 0 NOT NULL
);


ALTER TABLE bookkeeping.entries OWNER TO frederico;

--
-- TOC entry 220 (class 1259 OID 25730)
-- Name: entries_id_seq; Type: SEQUENCE; Schema: bookkeeping; Owner: frederico
--

CREATE SEQUENCE bookkeeping.entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE bookkeeping.entries_id_seq OWNER TO frederico;

--
-- TOC entry 3634 (class 0 OID 0)
-- Dependencies: 220
-- Name: entries_id_seq; Type: SEQUENCE OWNED BY; Schema: bookkeeping; Owner: frederico
--

ALTER SEQUENCE bookkeeping.entries_id_seq OWNED BY bookkeeping.entries.id;


--
-- TOC entry 223 (class 1259 OID 25743)
-- Name: tbl_acc_chart; Type: TABLE; Schema: bookkeeping; Owner: frederico
--

CREATE TABLE bookkeeping.tbl_acc_chart (
    name text,
    id smallint NOT NULL,
    parent smallint NOT NULL,
    acc_path public.ltree,
    acc_order smallint NOT NULL,
    acc_name text,
    init_balance numeric(12,2) DEFAULT 0 NOT NULL,
    balance numeric(12,2) DEFAULT 0 NOT NULL,
    inactive boolean DEFAULT false NOT NULL
);


ALTER TABLE bookkeeping.tbl_acc_chart OWNER TO frederico;

--
-- TOC entry 3635 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE tbl_acc_chart; Type: COMMENT; Schema: bookkeeping; Owner: frederico
--

COMMENT ON TABLE bookkeeping.tbl_acc_chart IS 'Rules:

    It is prohibited to change the first level of the account. An account belonging to an asset must remain as it is and cannot be altered with the code of the first level, such as using the number 1, for example. The same applies to other accounts: the first level of the code cannot be changed.
    It is prohibited to delete the level 1 of any account.
    It is prohibited to create any account with only the first level (creating new trees is forbidden).
    It is prohibited to update an account in a way that it becomes a descendant of itself.';


--
-- TOC entry 221 (class 1259 OID 25731)
-- Name: tbl_acc_chart_id_seq; Type: SEQUENCE; Schema: bookkeeping; Owner: frederico
--

CREATE SEQUENCE bookkeeping.tbl_acc_chart_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE bookkeeping.tbl_acc_chart_id_seq OWNER TO frederico;

--
-- TOC entry 3636 (class 0 OID 0)
-- Dependencies: 221
-- Name: tbl_acc_chart_id_seq; Type: SEQUENCE OWNED BY; Schema: bookkeeping; Owner: frederico
--

ALTER SEQUENCE bookkeeping.tbl_acc_chart_id_seq OWNED BY bookkeeping.tbl_acc_chart.id;


--
-- TOC entry 219 (class 1259 OID 25486)
-- Name: tbl_entities; Type: TABLE; Schema: entities; Owner: frederico
--

CREATE TABLE entities.tbl_entities (
    id integer NOT NULL,
    name text NOT NULL,
    parent bigint,
    password character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE entities.tbl_entities OWNER TO frederico;

--
-- TOC entry 3637 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE tbl_entities; Type: COMMENT; Schema: entities; Owner: frederico
--

COMMENT ON TABLE entities.tbl_entities IS 'Descrição: Essa tabela armazena as informações básicas das entidades (usuários) registradas no sistema, como nome, email, senha e data de criação.

Integração: A tabela é a principal tabela de entidades do sistema e é referenciada por outras tabelas, como entities.access_tokens e entities.tbl_permissions, por meio da chave primária id.

Exemplos de uso: A tabela é utilizada para armazenar e gerenciar as informações básicas de cada entidade (usuário) registrada no sistema. Ela serve como base para a autenticação, autorização e outras funcionalidades relacionadas aos usuários.';


--
-- TOC entry 218 (class 1259 OID 25485)
-- Name: tbl_entities_id_seq; Type: SEQUENCE; Schema: entities; Owner: frederico
--

CREATE SEQUENCE entities.tbl_entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE entities.tbl_entities_id_seq OWNER TO frederico;

--
-- TOC entry 3638 (class 0 OID 0)
-- Dependencies: 218
-- Name: tbl_entities_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: frederico
--

ALTER SEQUENCE entities.tbl_entities_id_seq OWNED BY entities.tbl_entities.id;


--
-- TOC entry 224 (class 1259 OID 25862)
-- Name: access_tokens; Type: TABLE; Schema: security; Owner: frederico
--

CREATE TABLE security.access_tokens (
    id integer NOT NULL,
    token character varying(255) NOT NULL,
    user_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE security.access_tokens OWNER TO frederico;

--
-- TOC entry 3639 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE access_tokens; Type: COMMENT; Schema: security; Owner: frederico
--

COMMENT ON TABLE security.access_tokens IS 'Descrição: Esta tabela armazena os tokens de acesso gerados para autenticar e autorizar as entidades (usuários) no sistema.

Integração: A tabela possui uma chave estrangeira user_id que referencia a tabela entities.tbl_entities, estabelecendo uma relação entre o token de acesso e o usuário associado.

Exemplos de uso: A tabela é utilizada para armazenar e validar os tokens de acesso durante o processo de autenticação. É possível consultar essa tabela para verificar se um token de acesso é válido e obter o ID do usuário correspondente.';


--
-- TOC entry 225 (class 1259 OID 25873)
-- Name: access_tokens_id_seq; Type: SEQUENCE; Schema: security; Owner: frederico
--

CREATE SEQUENCE security.access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE security.access_tokens_id_seq OWNER TO frederico;

--
-- TOC entry 3640 (class 0 OID 0)
-- Dependencies: 225
-- Name: access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: security; Owner: frederico
--

ALTER SEQUENCE security.access_tokens_id_seq OWNED BY security.access_tokens.id;


--
-- TOC entry 226 (class 1259 OID 25891)
-- Name: refresh_tokens; Type: TABLE; Schema: security; Owner: frederico
--

CREATE TABLE security.refresh_tokens (
    id integer NOT NULL,
    token character varying(255) NOT NULL,
    user_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE security.refresh_tokens OWNER TO frederico;

--
-- TOC entry 3641 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: security; Owner: frederico
--

COMMENT ON TABLE security.refresh_tokens IS 'Descrição: Essa tabela armazena os tokens de atualização usados para renovar os tokens de acesso expirados sem a necessidade de fazer login novamente.

Integração: A tabela possui uma chave estrangeira user_id que referencia a tabela entities.tbl_entities, estabelecendo uma relação entre o token de atualização e o usuário associado.

Exemplos de uso: Durante o processo de renovação do token de acesso, a tabela é consultada para verificar se um token de atualização é válido e obter o ID do usuário correspondente. Com base nessas informações, um novo token de acesso pode ser emitido.';


--
-- TOC entry 227 (class 1259 OID 25902)
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: security; Owner: frederico
--

CREATE SEQUENCE security.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE security.refresh_tokens_id_seq OWNER TO frederico;

--
-- TOC entry 3642 (class 0 OID 0)
-- Dependencies: 227
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: security; Owner: frederico
--

ALTER SEQUENCE security.refresh_tokens_id_seq OWNED BY security.refresh_tokens.id;


--
-- TOC entry 228 (class 1259 OID 25918)
-- Name: tbl_audit_log; Type: TABLE; Schema: security; Owner: frederico
--

CREATE TABLE security.tbl_audit_log (
    id integer NOT NULL,
    user_id integer NOT NULL,
    activity text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE security.tbl_audit_log OWNER TO frederico;

--
-- TOC entry 3643 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE tbl_audit_log; Type: COMMENT; Schema: security; Owner: frederico
--

COMMENT ON TABLE security.tbl_audit_log IS 'Descrição: Esta tabela registra as atividades e ações realizadas no sistema, permitindo rastrear e auditar as operações.
Integração: A tabela possui uma chave estrangeira entity_id que referencia a tabela entities.tbl_entities, permitindo relacionar uma atividade registrada com a entidade (usuário) associada à ação.
Exemplos de uso: A tabela é utilizada para registrar informações relevantes sobre atividades específicas, como criação, atualização ou exclusão de registros. Isso permite acompanhar as alterações feitas no sistema e, se necessário, identificar as entidades (usuários) envolvidas nas ações.';


--
-- TOC entry 229 (class 1259 OID 25931)
-- Name: tbl_audit_log_id_seq; Type: SEQUENCE; Schema: security; Owner: frederico
--

CREATE SEQUENCE security.tbl_audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE security.tbl_audit_log_id_seq OWNER TO frederico;

--
-- TOC entry 3644 (class 0 OID 0)
-- Dependencies: 229
-- Name: tbl_audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: security; Owner: frederico
--

ALTER SEQUENCE security.tbl_audit_log_id_seq OWNED BY security.tbl_audit_log.id;


--
-- TOC entry 230 (class 1259 OID 25950)
-- Name: tbl_permissions; Type: TABLE; Schema: security; Owner: frederico
--

CREATE TABLE security.tbl_permissions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE security.tbl_permissions OWNER TO frederico;

--
-- TOC entry 3645 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE tbl_permissions; Type: COMMENT; Schema: security; Owner: frederico
--

COMMENT ON TABLE security.tbl_permissions IS 'Descrição: Essa tabela representa as permissões atribuídas a uma entidade (usuário) específica em relação a determinados recursos ou funcionalidades do sistema.

Integração: A tabela possui duas chaves estrangeiras: entity_id, que referencia a tabela entities.tbl_entities, e role_id, que referencia a tabela entities.tbl_roles. Isso permite relacionar uma entidade a um papel específico e, assim, determinar suas permissões.

Exemplos de uso: A tabela é utilizada para gerenciar as permissões de cada entidade (usuário) em relação a recursos ou funcionalidades específicas do sistema. Com base nas permissões atribuídas, é possível controlar o acesso dos usuários a determinadas partes do sistema.';


--
-- TOC entry 231 (class 1259 OID 25966)
-- Name: tbl_permissions_id_seq; Type: SEQUENCE; Schema: security; Owner: frederico
--

CREATE SEQUENCE security.tbl_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE security.tbl_permissions_id_seq OWNER TO frederico;

--
-- TOC entry 3646 (class 0 OID 0)
-- Dependencies: 231
-- Name: tbl_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: security; Owner: frederico
--

ALTER SEQUENCE security.tbl_permissions_id_seq OWNED BY security.tbl_permissions.id;


--
-- TOC entry 232 (class 1259 OID 25968)
-- Name: tbl_roles; Type: TABLE; Schema: security; Owner: frederico
--

CREATE TABLE security.tbl_roles (
    id integer NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE security.tbl_roles OWNER TO frederico;

--
-- TOC entry 3647 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE tbl_roles; Type: COMMENT; Schema: security; Owner: frederico
--

COMMENT ON TABLE security.tbl_roles IS 'Descrição: Essa tabela armazena os diferentes papéis ou funções atribuídos aos usuários do sistema.

Integração: A tabela é referenciada pela tabela entities.tbl_permissions por meio da chave primária id, permitindo que cada permissão seja associada a um papel específico.

Exemplos de uso: A tabela é utilizada para definir e gerenciar os papéis disponíveis no sistema. Os papéis podem ter diferentes níveis de autoridade e acesso, permitindo controlar quais recursos e funcionalidades os usuários podem acessar com base no papel atribuído a eles.';


--
-- TOC entry 233 (class 1259 OID 25975)
-- Name: tbl_roles_id_seq; Type: SEQUENCE; Schema: security; Owner: frederico
--

CREATE SEQUENCE security.tbl_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE security.tbl_roles_id_seq OWNER TO frederico;

--
-- TOC entry 3648 (class 0 OID 0)
-- Dependencies: 233
-- Name: tbl_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: security; Owner: frederico
--

ALTER SEQUENCE security.tbl_roles_id_seq OWNED BY security.tbl_roles.id;


--
-- TOC entry 237 (class 1259 OID 25999)
-- Name: tbl_table_permissions; Type: TABLE; Schema: security; Owner: frederico
--

CREATE TABLE security.tbl_table_permissions (
    id integer NOT NULL,
    table_id integer NOT NULL,
    role_id integer NOT NULL,
    can_read boolean NOT NULL,
    can_write boolean NOT NULL,
    can_delete boolean NOT NULL
);


ALTER TABLE security.tbl_table_permissions OWNER TO frederico;

--
-- TOC entry 236 (class 1259 OID 25998)
-- Name: tbl_table_permissions_id_seq; Type: SEQUENCE; Schema: security; Owner: frederico
--

CREATE SEQUENCE security.tbl_table_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE security.tbl_table_permissions_id_seq OWNER TO frederico;

--
-- TOC entry 3649 (class 0 OID 0)
-- Dependencies: 236
-- Name: tbl_table_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: security; Owner: frederico
--

ALTER SEQUENCE security.tbl_table_permissions_id_seq OWNED BY security.tbl_table_permissions.id;


--
-- TOC entry 235 (class 1259 OID 25992)
-- Name: tbl_tables; Type: TABLE; Schema: security; Owner: frederico
--

CREATE TABLE security.tbl_tables (
    id integer NOT NULL,
    table_name character varying(255) NOT NULL
);


ALTER TABLE security.tbl_tables OWNER TO frederico;

--
-- TOC entry 234 (class 1259 OID 25991)
-- Name: tbl_tables_id_seq; Type: SEQUENCE; Schema: security; Owner: frederico
--

CREATE SEQUENCE security.tbl_tables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE security.tbl_tables_id_seq OWNER TO frederico;

--
-- TOC entry 3650 (class 0 OID 0)
-- Dependencies: 234
-- Name: tbl_tables_id_seq; Type: SEQUENCE OWNED BY; Schema: security; Owner: frederico
--

ALTER SEQUENCE security.tbl_tables_id_seq OWNED BY security.tbl_tables.id;


--
-- TOC entry 238 (class 1259 OID 26015)
-- Name: tbl_users; Type: TABLE; Schema: security; Owner: frederico
--

CREATE TABLE security.tbl_users (
    id integer NOT NULL,
    name text NOT NULL,
    password character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE security.tbl_users OWNER TO frederico;

--
-- TOC entry 3651 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE tbl_users; Type: COMMENT; Schema: security; Owner: frederico
--

COMMENT ON TABLE security.tbl_users IS 'Descrição: Essa tabela armazena as informações básicas das entidades (usuários) registradas no sistema, como nome, email, senha e data de criação.
Integração: A tabela é a principal tabela de entidades do sistema e é referenciada por outras tabelas, como entities.access_tokens e entities.tbl_permissions, por meio da chave primária id.
Exemplos de uso: A tabela é utilizada para armazenar e gerenciar as informações básicas de cada entidade (usuário) registrada no sistema. Ela serve como base para a autenticação, autorização e outras funcionalidades relacionadas aos usuários.';


--
-- TOC entry 3437 (class 2604 OID 25735)
-- Name: entries id; Type: DEFAULT; Schema: bookkeeping; Owner: frederico
--

ALTER TABLE ONLY bookkeeping.entries ALTER COLUMN id SET DEFAULT nextval('bookkeeping.entries_id_seq'::regclass);


--
-- TOC entry 3443 (class 2604 OID 25746)
-- Name: tbl_acc_chart id; Type: DEFAULT; Schema: bookkeeping; Owner: frederico
--

ALTER TABLE ONLY bookkeeping.tbl_acc_chart ALTER COLUMN id SET DEFAULT nextval('bookkeeping.tbl_acc_chart_id_seq'::regclass);


--
-- TOC entry 3435 (class 2604 OID 25494)
-- Name: tbl_entities id; Type: DEFAULT; Schema: entities; Owner: frederico
--

ALTER TABLE ONLY entities.tbl_entities ALTER COLUMN id SET DEFAULT nextval('entities.tbl_entities_id_seq'::regclass);


--
-- TOC entry 3447 (class 2604 OID 25874)
-- Name: access_tokens id; Type: DEFAULT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.access_tokens ALTER COLUMN id SET DEFAULT nextval('security.access_tokens_id_seq'::regclass);


--
-- TOC entry 3449 (class 2604 OID 25903)
-- Name: refresh_tokens id; Type: DEFAULT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('security.refresh_tokens_id_seq'::regclass);


--
-- TOC entry 3451 (class 2604 OID 25932)
-- Name: tbl_audit_log id; Type: DEFAULT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_audit_log ALTER COLUMN id SET DEFAULT nextval('security.tbl_audit_log_id_seq'::regclass);


--
-- TOC entry 3453 (class 2604 OID 25967)
-- Name: tbl_permissions id; Type: DEFAULT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_permissions ALTER COLUMN id SET DEFAULT nextval('security.tbl_permissions_id_seq'::regclass);


--
-- TOC entry 3455 (class 2604 OID 25976)
-- Name: tbl_roles id; Type: DEFAULT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_roles ALTER COLUMN id SET DEFAULT nextval('security.tbl_roles_id_seq'::regclass);


--
-- TOC entry 3457 (class 2604 OID 26002)
-- Name: tbl_table_permissions id; Type: DEFAULT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_table_permissions ALTER COLUMN id SET DEFAULT nextval('security.tbl_table_permissions_id_seq'::regclass);


--
-- TOC entry 3456 (class 2604 OID 25995)
-- Name: tbl_tables id; Type: DEFAULT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_tables ALTER COLUMN id SET DEFAULT nextval('security.tbl_tables_id_seq'::regclass);


--
-- TOC entry 3462 (class 2606 OID 25758)
-- Name: entries entries_pkey; Type: CONSTRAINT; Schema: bookkeeping; Owner: frederico
--

ALTER TABLE ONLY bookkeeping.entries
    ADD CONSTRAINT entries_pkey PRIMARY KEY (id);


--
-- TOC entry 3460 (class 2606 OID 25496)
-- Name: tbl_entities tbl_entities_pkey; Type: CONSTRAINT; Schema: entities; Owner: frederico
--

ALTER TABLE ONLY entities.tbl_entities
    ADD CONSTRAINT tbl_entities_pkey PRIMARY KEY (id);


--
-- TOC entry 3464 (class 2606 OID 25867)
-- Name: access_tokens access_tokens_pkey; Type: CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.access_tokens
    ADD CONSTRAINT access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 3466 (class 2606 OID 25896)
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 3468 (class 2606 OID 25925)
-- Name: tbl_audit_log tbl_audit_log_pkey; Type: CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_audit_log
    ADD CONSTRAINT tbl_audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3470 (class 2606 OID 25955)
-- Name: tbl_permissions tbl_permissions_pkey; Type: CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_permissions
    ADD CONSTRAINT tbl_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 3472 (class 2606 OID 25974)
-- Name: tbl_roles tbl_roles_pkey; Type: CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_roles
    ADD CONSTRAINT tbl_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 3476 (class 2606 OID 26004)
-- Name: tbl_table_permissions tbl_table_permissions_pkey; Type: CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_table_permissions
    ADD CONSTRAINT tbl_table_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 3474 (class 2606 OID 25997)
-- Name: tbl_tables tbl_tables_pkey; Type: CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_tables
    ADD CONSTRAINT tbl_tables_pkey PRIMARY KEY (id);


--
-- TOC entry 3478 (class 2606 OID 26022)
-- Name: tbl_users tbl_users_pkey; Type: CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_users
    ADD CONSTRAINT tbl_users_pkey PRIMARY KEY (id);


--
-- TOC entry 3479 (class 2606 OID 25752)
-- Name: entries fk_entries_account_id; Type: FK CONSTRAINT; Schema: bookkeeping; Owner: frederico
--

ALTER TABLE ONLY bookkeeping.entries
    ADD CONSTRAINT fk_entries_account_id FOREIGN KEY (account_id) REFERENCES entities.tbl_entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3480 (class 2606 OID 26023)
-- Name: access_tokens access_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.access_tokens
    ADD CONSTRAINT access_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES security.tbl_users(id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3481 (class 2606 OID 26028)
-- Name: refresh_tokens refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES security.tbl_users(id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 3482 (class 2606 OID 26033)
-- Name: tbl_audit_log tbl_audit_log_entity_id_fkey; Type: FK CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_audit_log
    ADD CONSTRAINT tbl_audit_log_entity_id_fkey FOREIGN KEY (user_id) REFERENCES security.tbl_users(id) NOT VALID;


--
-- TOC entry 3483 (class 2606 OID 26038)
-- Name: tbl_permissions tbl_permissions_entity_id_fkey; Type: FK CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_permissions
    ADD CONSTRAINT tbl_permissions_entity_id_fkey FOREIGN KEY (user_id) REFERENCES security.tbl_users(id) NOT VALID;


--
-- TOC entry 3484 (class 2606 OID 26010)
-- Name: tbl_table_permissions tbl_table_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_table_permissions
    ADD CONSTRAINT tbl_table_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES security.tbl_roles(id) ON DELETE CASCADE;


--
-- TOC entry 3485 (class 2606 OID 26005)
-- Name: tbl_table_permissions tbl_table_permissions_table_id_fkey; Type: FK CONSTRAINT; Schema: security; Owner: frederico
--

ALTER TABLE ONLY security.tbl_table_permissions
    ADD CONSTRAINT tbl_table_permissions_table_id_fkey FOREIGN KEY (table_id) REFERENCES security.tbl_tables(id) ON DELETE CASCADE;


-- Completed on 2023-07-06 19:11:21 -03

--
-- PostgreSQL database dump complete
--

