--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3 (Ubuntu 15.3-1.pgdg23.04+1)
-- Dumped by pg_dump version 15.3 (Ubuntu 15.3-1.pgdg23.04+1)

-- Started on 2023-06-26 07:09:52 -03

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
-- TOC entry 2 (class 3079 OID 25504)
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- TOC entry 3558 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 25732)
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
-- TOC entry 219 (class 1259 OID 25730)
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
-- TOC entry 3559 (class 0 OID 0)
-- Dependencies: 219
-- Name: entries_id_seq; Type: SEQUENCE OWNED BY; Schema: bookkeeping; Owner: frederico
--

ALTER SEQUENCE bookkeeping.entries_id_seq OWNED BY bookkeeping.entries.id;


--
-- TOC entry 222 (class 1259 OID 25743)
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
-- TOC entry 3560 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE tbl_acc_chart; Type: COMMENT; Schema: bookkeeping; Owner: frederico
--

COMMENT ON TABLE bookkeeping.tbl_acc_chart IS 'Rules:

    It is prohibited to change the first level of the account. An account belonging to an asset must remain as it is and cannot be altered with the code of the first level, such as using the number 1, for example. The same applies to other accounts: the first level of the code cannot be changed.
    It is prohibited to delete the level 1 of any account.
    It is prohibited to create any account with only the first level (creating new trees is forbidden).
    It is prohibited to update an account in a way that it becomes a descendant of itself.';


--
-- TOC entry 220 (class 1259 OID 25731)
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
-- TOC entry 3561 (class 0 OID 0)
-- Dependencies: 220
-- Name: tbl_acc_chart_id_seq; Type: SEQUENCE OWNED BY; Schema: bookkeeping; Owner: frederico
--

ALTER SEQUENCE bookkeeping.tbl_acc_chart_id_seq OWNED BY bookkeeping.tbl_acc_chart.id;


--
-- TOC entry 218 (class 1259 OID 25486)
-- Name: tbl_entities; Type: TABLE; Schema: entities; Owner: frederico
--

CREATE TABLE entities.tbl_entities (
    id integer NOT NULL,
    name text NOT NULL,
    parent bigint
);


ALTER TABLE entities.tbl_entities OWNER TO frederico;

--
-- TOC entry 217 (class 1259 OID 25485)
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
-- TOC entry 3562 (class 0 OID 0)
-- Dependencies: 217
-- Name: tbl_entities_id_seq; Type: SEQUENCE OWNED BY; Schema: entities; Owner: frederico
--

ALTER SEQUENCE entities.tbl_entities_id_seq OWNED BY entities.tbl_entities.id;


--
-- TOC entry 3396 (class 2604 OID 25735)
-- Name: entries id; Type: DEFAULT; Schema: bookkeeping; Owner: frederico
--

ALTER TABLE ONLY bookkeeping.entries ALTER COLUMN id SET DEFAULT nextval('bookkeeping.entries_id_seq'::regclass);


--
-- TOC entry 3402 (class 2604 OID 25746)
-- Name: tbl_acc_chart id; Type: DEFAULT; Schema: bookkeeping; Owner: frederico
--

ALTER TABLE ONLY bookkeeping.tbl_acc_chart ALTER COLUMN id SET DEFAULT nextval('bookkeeping.tbl_acc_chart_id_seq'::regclass);


--
-- TOC entry 3395 (class 2604 OID 25494)
-- Name: tbl_entities id; Type: DEFAULT; Schema: entities; Owner: frederico
--

ALTER TABLE ONLY entities.tbl_entities ALTER COLUMN id SET DEFAULT nextval('entities.tbl_entities_id_seq'::regclass);


--
-- TOC entry 3409 (class 2606 OID 25758)
-- Name: entries entries_pkey; Type: CONSTRAINT; Schema: bookkeeping; Owner: frederico
--

ALTER TABLE ONLY bookkeeping.entries
    ADD CONSTRAINT entries_pkey PRIMARY KEY (id);


--
-- TOC entry 3407 (class 2606 OID 25496)
-- Name: tbl_entities tbl_entities_pkey; Type: CONSTRAINT; Schema: entities; Owner: frederico
--

ALTER TABLE ONLY entities.tbl_entities
    ADD CONSTRAINT tbl_entities_pkey PRIMARY KEY (id);


--
-- TOC entry 3410 (class 2606 OID 25752)
-- Name: entries fk_entries_account_id; Type: FK CONSTRAINT; Schema: bookkeeping; Owner: frederico
--

ALTER TABLE ONLY bookkeeping.entries
    ADD CONSTRAINT fk_entries_account_id FOREIGN KEY (account_id) REFERENCES entities.tbl_entities(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2023-06-26 07:09:52 -03

--
-- PostgreSQL database dump complete
--

