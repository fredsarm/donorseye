PGDMP     (    '                {            de     15.3 (Ubuntu 15.3-1.pgdg23.04+1)     15.3 (Ubuntu 15.3-1.pgdg23.04+1) �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    38562    de    DATABASE     n   CREATE DATABASE de WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';
    DROP DATABASE de;
                derole    false            �           0    0    de    DATABASE PROPERTIES     �   ALTER DATABASE de SET lc_time TO 'pt_BR.utf8';
ALTER DATABASE de SET lc_monetary TO 'pt_BR.utf8';
ALTER DATABASE de SET lc_numeric TO 'pt_BR.utf8';
ALTER DATABASE de SET lc_messages TO 'pt_BR.utf8';
                     derole    false                        2615    38563 
   accounting    SCHEMA        CREATE SCHEMA accounting;
    DROP SCHEMA accounting;
                derole    false                        2615    38564    auth    SCHEMA        CREATE SCHEMA auth;
    DROP SCHEMA auth;
                derole    false                        2615    38565    entities    SCHEMA        CREATE SCHEMA entities;
    DROP SCHEMA entities;
                derole    false            
            2615    2200    public    SCHEMA     2   -- *not* creating schema, since initdb creates it
 2   -- *not* dropping schema, since initdb creates it
                postgres    false            �           0    0    SCHEMA public    ACL     Q   REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
                   postgres    false    10            	            2615    38566    syslogic    SCHEMA        CREATE SCHEMA syslogic;
    DROP SCHEMA syslogic;
                derole    false                        3079    38567    ltree 	   EXTENSION     9   CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;
    DROP EXTENSION ltree;
                   false    10            �           0    0    EXTENSION ltree    COMMENT     Q   COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';
                        false    2            T           1255    38752    sync_bas_all_columns_trigger()    FUNCTION     �  CREATE FUNCTION public.sync_bas_all_columns_trigger() RETURNS event_trigger
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
 5   DROP FUNCTION public.sync_bas_all_columns_trigger();
       public          postgres    false    10            U           1255    38753    delete_bas_data_dic()    FUNCTION     �   CREATE FUNCTION syslogic.delete_bas_data_dic() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM syslogic.bas_data_dic
    WHERE col_id = OLD.text_id;
    RETURN OLD;
END;
$$;
 .   DROP FUNCTION syslogic.delete_bas_data_dic();
       syslogic          postgres    false    9            V           1255    38754    insert_bas_data_dic()    FUNCTION       CREATE FUNCTION syslogic.insert_bas_data_dic() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO syslogic.bas_data_dic(col_id, en_us, pt_br,def_class,def_name)
    VALUES (NEW.text_id, NEW.col_name, NEW.col_name,'1','Column ' || NEW.text_id);
    RETURN NEW;
END;
$$;
 .   DROP FUNCTION syslogic.insert_bas_data_dic();
       syslogic          postgres    false    9            �            1259    38755    bas_acc_chart    TABLE       CREATE TABLE accounting.bas_acc_chart (
    acc_id integer NOT NULL,
    acc_name text NOT NULL,
    init_balance numeric(20,2) DEFAULT 0 NOT NULL,
    balance numeric(20,2) DEFAULT 0 NOT NULL,
    inactive boolean DEFAULT false NOT NULL,
    tree_id public.ltree
);
 %   DROP TABLE accounting.bas_acc_chart;
    
   accounting         heap    derole    false    2    10    2    10    2    10    2    10    2    10    6            �           0    0    TABLE bas_acc_chart    COMMENT     _  COMMENT ON TABLE accounting.bas_acc_chart IS 'Rules:

    It is prohibited to change the first level of the account. An account belonging to an asset must remain as it is and cannot be altered with the code of the first level, such as using the number 1, for example. The same applies to other accounts: the first level of the code cannot be changed.
    It is prohibited to delete the level 1 of any account.
    It is prohibited to create any account with only the first level (creating new trees is forbidden).
    It is prohibited to update an account in a way that it becomes a descendant of itself.';
       
   accounting          derole    false    219            �            1259    38763    bas_acc_chart_acc_id_seq    SEQUENCE     �   CREATE SEQUENCE accounting.bas_acc_chart_acc_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE accounting.bas_acc_chart_acc_id_seq;
    
   accounting          derole    false    219    6            �           0    0    bas_acc_chart_acc_id_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE accounting.bas_acc_chart_acc_id_seq OWNED BY accounting.bas_acc_chart.acc_id;
       
   accounting          derole    false    220            �            1259    38764    eve_acc_entries    TABLE     �   CREATE TABLE accounting.eve_acc_entries (
    entry_id integer NOT NULL,
    debit numeric(20,2) DEFAULT 0 NOT NULL,
    credit numeric(20,2) NOT NULL,
    bus_trans_id integer NOT NULL,
    acc_id integer NOT NULL
);
 '   DROP TABLE accounting.eve_acc_entries;
    
   accounting         heap    derole    false    6            �            1259    38768    eve_acc_entries_entry_id_seq    SEQUENCE     �   CREATE SEQUENCE accounting.eve_acc_entries_entry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;
 7   DROP SEQUENCE accounting.eve_acc_entries_entry_id_seq;
    
   accounting          derole    false    221    6            �           0    0    eve_acc_entries_entry_id_seq    SEQUENCE OWNED BY     e   ALTER SEQUENCE accounting.eve_acc_entries_entry_id_seq OWNED BY accounting.eve_acc_entries.entry_id;
       
   accounting          derole    false    222            �            1259    38769    eve_bus_transactions    TABLE     i  CREATE TABLE accounting.eve_bus_transactions (
    trans_id integer NOT NULL,
    trans_date date DEFAULT (CURRENT_TIMESTAMP)::timestamp without time zone NOT NULL,
    occur_date date DEFAULT (CURRENT_TIMESTAMP)::timestamp without time zone NOT NULL,
    entity_id integer DEFAULT 0 NOT NULL,
    trans_value numeric(20,2) DEFAULT 0 NOT NULL,
    memo text
);
 ,   DROP TABLE accounting.eve_bus_transactions;
    
   accounting         heap    derole    false    6            �            1259    38778 !   eve_bus_transactions_trans_id_seq    SEQUENCE     �   CREATE SEQUENCE accounting.eve_bus_transactions_trans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE accounting.eve_bus_transactions_trans_id_seq;
    
   accounting          derole    false    223    6            �           0    0 !   eve_bus_transactions_trans_id_seq    SEQUENCE OWNED BY     o   ALTER SEQUENCE accounting.eve_bus_transactions_trans_id_seq OWNED BY accounting.eve_bus_transactions.trans_id;
       
   accounting          derole    false    224            �            1259    38779    bas_entities    TABLE     �   CREATE TABLE entities.bas_entities (
    entity_id integer NOT NULL,
    entity_name text NOT NULL,
    entity_parent integer,
    entity_password text,
    email text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
 "   DROP TABLE entities.bas_entities;
       entities         heap    derole    false    8            �           0    0    TABLE bas_entities    COMMENT     �  COMMENT ON TABLE entities.bas_entities IS 'Descrição: Essa tabela armazena as informações básicas das entidades (usuários) registradas no sistema, como nome, email, senha e data de criação.

Integração: A tabela é a principal tabela de entidades do sistema e é referenciada por outras tabelas, como auth.eve_access_tokens e auth.bas_permissions, por meio da chave primária id.

Exemplos de uso: A tabela é utilizada para armazenar e gerenciar as informações básicas de cada entidade (usuário) registrada no sistema. Ela serve como base para a autenticação, autorização e outras funcionalidades relacionadas aos usuários.';
          entities          derole    false    225            �            1259    38785    vw_eve_acc_entries    VIEW     >  CREATE VIEW accounting.vw_eve_acc_entries AS
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
 )   DROP VIEW accounting.vw_eve_acc_entries;
    
   accounting          derole    false    223    223    223    223    225    225    221    219    221    221    221    221    223    219    6            �            1259    38790    bas_permissions    TABLE     �   CREATE TABLE auth.bas_permissions (
    permission_id integer NOT NULL,
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 !   DROP TABLE auth.bas_permissions;
       auth         heap    derole    false    7            �           0    0    TABLE bas_permissions    COMMENT     �  COMMENT ON TABLE auth.bas_permissions IS 'Descrição: Essa tabela representa as permissões atribuídas a uma entidade (usuário) específica em relação a determinados recursos ou funcionalidades do sistema.

Integração: A tabela possui duas chaves estrangeiras: entity_id, que referencia a tabela entities.bas_entities, e role_id, que referencia a tabela entities.bas_roles. Isso permite relacionar uma entidade a um papel específico e, assim, determinar suas permissões.

Exemplos de uso: A tabela é utilizada para gerenciar as permissões de cada entidade (usuário) em relação a recursos ou funcionalidades específicas do sistema. Com base nas permissões atribuídas, é possível controlar o acesso dos usuários a determinadas partes do sistema.';
          auth          derole    false    227            �            1259    38794 !   bas_permissions_permission_id_seq    SEQUENCE     �   CREATE SEQUENCE auth.bas_permissions_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
 6   DROP SEQUENCE auth.bas_permissions_permission_id_seq;
       auth          derole    false    7    227            �           0    0 !   bas_permissions_permission_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE auth.bas_permissions_permission_id_seq OWNED BY auth.bas_permissions.permission_id;
          auth          derole    false    228            �            1259    38795 	   bas_roles    TABLE     l   CREATE TABLE auth.bas_roles (
    role_id integer NOT NULL,
    name text NOT NULL,
    description text
);
    DROP TABLE auth.bas_roles;
       auth         heap    derole    false    7            �           0    0    TABLE bas_roles    COMMENT     [  COMMENT ON TABLE auth.bas_roles IS 'Descrição: Essa tabela armazena os diferentes papéis ou funções atribuídos aos usuários do sistema.

Integração: A tabela é referenciada pela tabela auth.bas_permissions por meio da chave primária id, permitindo que cada permissão seja associada a um papel específico.

Exemplos de uso: A tabela é utilizada para definir e gerenciar os papéis disponíveis no sistema. Os papéis podem ter diferentes níveis de autoridade e acesso, permitindo controlar quais recursos e funcionalidades os usuários podem acessar com base no papel atribuído a eles.';
          auth          derole    false    229            �            1259    38800    bas_roles_role_id_seq    SEQUENCE     �   CREATE SEQUENCE auth.bas_roles_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
 *   DROP SEQUENCE auth.bas_roles_role_id_seq;
       auth          derole    false    229    7            �           0    0    bas_roles_role_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE auth.bas_roles_role_id_seq OWNED BY auth.bas_roles.role_id;
          auth          derole    false    230            �            1259    38801    bas_table_permissions    TABLE     �   CREATE TABLE auth.bas_table_permissions (
    tpermission_id integer NOT NULL,
    table_id integer NOT NULL,
    role_id integer NOT NULL,
    can_read boolean NOT NULL,
    can_write boolean NOT NULL,
    can_delete boolean NOT NULL
);
 '   DROP TABLE auth.bas_table_permissions;
       auth         heap    derole    false    7            �            1259    38804 (   bas_table_permissions_tpermission_id_seq    SEQUENCE     �   CREATE SEQUENCE auth.bas_table_permissions_tpermission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 =   DROP SEQUENCE auth.bas_table_permissions_tpermission_id_seq;
       auth          derole    false    231    7            �           0    0 (   bas_table_permissions_tpermission_id_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE auth.bas_table_permissions_tpermission_id_seq OWNED BY auth.bas_table_permissions.tpermission_id;
          auth          derole    false    232            �            1259    38805 
   bas_tables    TABLE     ^   CREATE TABLE auth.bas_tables (
    table_id integer NOT NULL,
    table_name text NOT NULL
);
    DROP TABLE auth.bas_tables;
       auth         heap    derole    false    7            �            1259    38810    bas_tables_table_id_seq    SEQUENCE     �   CREATE SEQUENCE auth.bas_tables_table_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE auth.bas_tables_table_id_seq;
       auth          derole    false    233    7            �           0    0    bas_tables_table_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE auth.bas_tables_table_id_seq OWNED BY auth.bas_tables.table_id;
          auth          derole    false    234            �            1259    38811 	   bas_users    TABLE     �   CREATE TABLE auth.bas_users (
    user_id integer NOT NULL,
    user_name text NOT NULL,
    user_password text NOT NULL,
    email text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
    DROP TABLE auth.bas_users;
       auth         heap    derole    false    7            �           0    0    TABLE bas_users    COMMENT     }  COMMENT ON TABLE auth.bas_users IS 'Descrição: Essa tabela armazena as informações básicas das entidades (usuários) registradas no sistema, como nome, email, senha e data de criação.
Integração: A tabela é a principal tabela de entidades do sistema e é referenciada por outras tabelas, como auth.eve_access_tokens e auth.bas_permissions, por meio da chave primária id.
Exemplos de uso: A tabela é utilizada para armazenar e gerenciar as informações básicas de cada entidade (usuário) registrada no sistema. Ela serve como base para a autenticação, autorização e outras funcionalidades relacionadas aos usuários.';
          auth          derole    false    235            �            1259    38817    bas_users_user_id_seq    SEQUENCE     �   CREATE SEQUENCE auth.bas_users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE auth.bas_users_user_id_seq;
       auth          derole    false    235    7            �           0    0    bas_users_user_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE auth.bas_users_user_id_seq OWNED BY auth.bas_users.user_id;
          auth          derole    false    236            �            1259    38818    eve_access_tokens    TABLE     �   CREATE TABLE auth.eve_access_tokens (
    token_id integer NOT NULL,
    token text NOT NULL,
    user_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
 #   DROP TABLE auth.eve_access_tokens;
       auth         heap    derole    false    7            �           0    0    TABLE eve_access_tokens    COMMENT     \  COMMENT ON TABLE auth.eve_access_tokens IS 'Descrição: Esta tabela armazena os tokens de acesso gerados para autenticar e autorizar as entidades (usuários) no sistema.

Integração: A tabela possui uma chave estrangeira user_id que referencia a tabela entities.bas_entities, estabelecendo uma relação entre o token de acesso e o usuário associado.

Exemplos de uso: A tabela é utilizada para armazenar e validar os tokens de acesso durante o processo de autenticação. É possível consultar essa tabela para verificar se um token de acesso é válido e obter o ID do usuário correspondente.';
          auth          derole    false    237            �            1259    38824    eve_access_tokens_token_id_seq    SEQUENCE     �   CREATE SEQUENCE auth.eve_access_tokens_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
 3   DROP SEQUENCE auth.eve_access_tokens_token_id_seq;
       auth          derole    false    7    237            �           0    0    eve_access_tokens_token_id_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE auth.eve_access_tokens_token_id_seq OWNED BY auth.eve_access_tokens.token_id;
          auth          derole    false    238            �            1259    38825    eve_audit_log    TABLE     �   CREATE TABLE auth.eve_audit_log (
    log_id integer NOT NULL,
    user_id integer NOT NULL,
    activity text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE auth.eve_audit_log;
       auth         heap    derole    false    7            �           0    0    TABLE eve_audit_log    COMMENT     �  COMMENT ON TABLE auth.eve_audit_log IS 'Descrição: Esta tabela registra as atividades e ações realizadas no sistema, permitindo rastrear e auditar as operações.
Integração: A tabela possui uma chave estrangeira entity_id que referencia a tabela entities.bas_entities, permitindo relacionar uma atividade registrada com a entidade (usuário) associada à ação.
Exemplos de uso: A tabela é utilizada para registrar informações relevantes sobre atividades específicas, como criação, atualização ou exclusão de registros. Isso permite acompanhar as alterações feitas no sistema e, se necessário, identificar as entidades (usuários) envolvidas nas ações.';
          auth          derole    false    239            �            1259    38831    eve_audit_log_log_id_seq    SEQUENCE     �   CREATE SEQUENCE auth.eve_audit_log_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
 -   DROP SEQUENCE auth.eve_audit_log_log_id_seq;
       auth          derole    false    7    239            �           0    0    eve_audit_log_log_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE auth.eve_audit_log_log_id_seq OWNED BY auth.eve_audit_log.log_id;
          auth          derole    false    240            �            1259    38832    eve_refresh_tokens    TABLE     �   CREATE TABLE auth.eve_refresh_tokens (
    rtoken_id integer NOT NULL,
    token text NOT NULL,
    user_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
 $   DROP TABLE auth.eve_refresh_tokens;
       auth         heap    derole    false    7            �           0    0    TABLE eve_refresh_tokens    COMMENT     �  COMMENT ON TABLE auth.eve_refresh_tokens IS 'Descrição: Essa tabela armazena os tokens de atualização usados para renovar os tokens de acesso expirados sem a necessidade de fazer login novamente.

Integração: A tabela possui uma chave estrangeira user_id que referencia a tabela entities.bas_entities, estabelecendo uma relação entre o token de atualização e o usuário associado.

Exemplos de uso: Durante o processo de renovação do token de acesso, a tabela é consultada para verificar se um token de atualização é válido e obter o ID do usuário correspondente. Com base nessas informações, um novo token de acesso pode ser emitido.';
          auth          derole    false    241            �            1259    38838     eve_refresh_tokens_rtoken_id_seq    SEQUENCE     �   CREATE SEQUENCE auth.eve_refresh_tokens_rtoken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;
 5   DROP SEQUENCE auth.eve_refresh_tokens_rtoken_id_seq;
       auth          derole    false    7    241            �           0    0     eve_refresh_tokens_rtoken_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE auth.eve_refresh_tokens_rtoken_id_seq OWNED BY auth.eve_refresh_tokens.rtoken_id;
          auth          derole    false    242            �            1259    38839    bas_entities_entity_id_seq    SEQUENCE     �   CREATE SEQUENCE entities.bas_entities_entity_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE entities.bas_entities_entity_id_seq;
       entities          derole    false    225    8            �           0    0    bas_entities_entity_id_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE entities.bas_entities_entity_id_seq OWNED BY entities.bas_entities.entity_id;
          entities          derole    false    243            �            1259    38840    todos    TABLE     x   CREATE TABLE public.todos (
    id integer NOT NULL,
    text text NOT NULL,
    done boolean DEFAULT false NOT NULL
);
    DROP TABLE public.todos;
       public         heap    derole    false    10            �            1259    38846    todos_id_seq    SEQUENCE     �   CREATE SEQUENCE public.todos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.todos_id_seq;
       public          derole    false    244    10            �           0    0    todos_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.todos_id_seq OWNED BY public.todos.id;
          public          derole    false    245            �            1259    38847    bas_all_columns    TABLE     �   CREATE TABLE syslogic.bas_all_columns (
    text_id text NOT NULL,
    sch_name text NOT NULL,
    tab_name text NOT NULL,
    col_name text NOT NULL,
    show_front_end boolean DEFAULT true NOT NULL,
    data_type text
);
 %   DROP TABLE syslogic.bas_all_columns;
       syslogic         heap    derole    false    9            �            1259    38853    bas_data_dic    TABLE     �   CREATE TABLE syslogic.bas_data_dic (
    def_id integer NOT NULL,
    def_name text,
    def_class integer,
    col_id text,
    en_us text,
    pt_br text,
    on_allowed_language_list boolean
);
 "   DROP TABLE syslogic.bas_data_dic;
       syslogic         heap    derole    false    9            �           0    0    TABLE bas_data_dic    COMMENT     =   COMMENT ON TABLE syslogic.bas_data_dic IS 'Data Dictionary';
          syslogic          derole    false    247            �            1259    38858    bas_data_dic_class    TABLE     �   CREATE TABLE syslogic.bas_data_dic_class (
    class_id integer NOT NULL,
    class_name text NOT NULL,
    "Description" text
);
 (   DROP TABLE syslogic.bas_data_dic_class;
       syslogic         heap    derole    false    9            �            1259    38863    bas_data_dic_class_class_id_seq    SEQUENCE     �   CREATE SEQUENCE syslogic.bas_data_dic_class_class_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE syslogic.bas_data_dic_class_class_id_seq;
       syslogic          derole    false    9    248            �           0    0    bas_data_dic_class_class_id_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE syslogic.bas_data_dic_class_class_id_seq OWNED BY syslogic.bas_data_dic_class.class_id;
          syslogic          derole    false    249            �            1259    38864    bas_data_dic_def_id_seq    SEQUENCE     �   CREATE SEQUENCE syslogic.bas_data_dic_def_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE syslogic.bas_data_dic_def_id_seq;
       syslogic          derole    false    247    9            �           0    0    bas_data_dic_def_id_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE syslogic.bas_data_dic_def_id_seq OWNED BY syslogic.bas_data_dic.def_id;
          syslogic          derole    false    250            �           2604    38960    bas_acc_chart acc_id    DEFAULT     �   ALTER TABLE ONLY accounting.bas_acc_chart ALTER COLUMN acc_id SET DEFAULT nextval('accounting.bas_acc_chart_acc_id_seq'::regclass);
 G   ALTER TABLE accounting.bas_acc_chart ALTER COLUMN acc_id DROP DEFAULT;
    
   accounting          derole    false    220    219            �           2604    38961    eve_acc_entries entry_id    DEFAULT     �   ALTER TABLE ONLY accounting.eve_acc_entries ALTER COLUMN entry_id SET DEFAULT nextval('accounting.eve_acc_entries_entry_id_seq'::regclass);
 K   ALTER TABLE accounting.eve_acc_entries ALTER COLUMN entry_id DROP DEFAULT;
    
   accounting          derole    false    222    221            �           2604    38962    eve_bus_transactions trans_id    DEFAULT     �   ALTER TABLE ONLY accounting.eve_bus_transactions ALTER COLUMN trans_id SET DEFAULT nextval('accounting.eve_bus_transactions_trans_id_seq'::regclass);
 P   ALTER TABLE accounting.eve_bus_transactions ALTER COLUMN trans_id DROP DEFAULT;
    
   accounting          derole    false    224    223            �           2604    38963    bas_permissions permission_id    DEFAULT     �   ALTER TABLE ONLY auth.bas_permissions ALTER COLUMN permission_id SET DEFAULT nextval('auth.bas_permissions_permission_id_seq'::regclass);
 J   ALTER TABLE auth.bas_permissions ALTER COLUMN permission_id DROP DEFAULT;
       auth          derole    false    228    227            �           2604    38964    bas_roles role_id    DEFAULT     r   ALTER TABLE ONLY auth.bas_roles ALTER COLUMN role_id SET DEFAULT nextval('auth.bas_roles_role_id_seq'::regclass);
 >   ALTER TABLE auth.bas_roles ALTER COLUMN role_id DROP DEFAULT;
       auth          derole    false    230    229            �           2604    38965 $   bas_table_permissions tpermission_id    DEFAULT     �   ALTER TABLE ONLY auth.bas_table_permissions ALTER COLUMN tpermission_id SET DEFAULT nextval('auth.bas_table_permissions_tpermission_id_seq'::regclass);
 Q   ALTER TABLE auth.bas_table_permissions ALTER COLUMN tpermission_id DROP DEFAULT;
       auth          derole    false    232    231            �           2604    38966    bas_tables table_id    DEFAULT     v   ALTER TABLE ONLY auth.bas_tables ALTER COLUMN table_id SET DEFAULT nextval('auth.bas_tables_table_id_seq'::regclass);
 @   ALTER TABLE auth.bas_tables ALTER COLUMN table_id DROP DEFAULT;
       auth          derole    false    234    233            �           2604    38967    bas_users user_id    DEFAULT     r   ALTER TABLE ONLY auth.bas_users ALTER COLUMN user_id SET DEFAULT nextval('auth.bas_users_user_id_seq'::regclass);
 >   ALTER TABLE auth.bas_users ALTER COLUMN user_id DROP DEFAULT;
       auth          derole    false    236    235            �           2604    38968    eve_access_tokens token_id    DEFAULT     �   ALTER TABLE ONLY auth.eve_access_tokens ALTER COLUMN token_id SET DEFAULT nextval('auth.eve_access_tokens_token_id_seq'::regclass);
 G   ALTER TABLE auth.eve_access_tokens ALTER COLUMN token_id DROP DEFAULT;
       auth          derole    false    238    237            �           2604    38969    eve_audit_log log_id    DEFAULT     x   ALTER TABLE ONLY auth.eve_audit_log ALTER COLUMN log_id SET DEFAULT nextval('auth.eve_audit_log_log_id_seq'::regclass);
 A   ALTER TABLE auth.eve_audit_log ALTER COLUMN log_id DROP DEFAULT;
       auth          derole    false    240    239            �           2604    38970    eve_refresh_tokens rtoken_id    DEFAULT     �   ALTER TABLE ONLY auth.eve_refresh_tokens ALTER COLUMN rtoken_id SET DEFAULT nextval('auth.eve_refresh_tokens_rtoken_id_seq'::regclass);
 I   ALTER TABLE auth.eve_refresh_tokens ALTER COLUMN rtoken_id DROP DEFAULT;
       auth          derole    false    242    241            �           2604    38971    bas_entities entity_id    DEFAULT     �   ALTER TABLE ONLY entities.bas_entities ALTER COLUMN entity_id SET DEFAULT nextval('entities.bas_entities_entity_id_seq'::regclass);
 G   ALTER TABLE entities.bas_entities ALTER COLUMN entity_id DROP DEFAULT;
       entities          derole    false    243    225            �           2604    38972    todos id    DEFAULT     d   ALTER TABLE ONLY public.todos ALTER COLUMN id SET DEFAULT nextval('public.todos_id_seq'::regclass);
 7   ALTER TABLE public.todos ALTER COLUMN id DROP DEFAULT;
       public          derole    false    245    244            �           2604    38973    bas_data_dic def_id    DEFAULT     ~   ALTER TABLE ONLY syslogic.bas_data_dic ALTER COLUMN def_id SET DEFAULT nextval('syslogic.bas_data_dic_def_id_seq'::regclass);
 D   ALTER TABLE syslogic.bas_data_dic ALTER COLUMN def_id DROP DEFAULT;
       syslogic          derole    false    250    247            �           2604    38974    bas_data_dic_class class_id    DEFAULT     �   ALTER TABLE ONLY syslogic.bas_data_dic_class ALTER COLUMN class_id SET DEFAULT nextval('syslogic.bas_data_dic_class_class_id_seq'::regclass);
 L   ALTER TABLE syslogic.bas_data_dic_class ALTER COLUMN class_id DROP DEFAULT;
       syslogic          derole    false    249    248            f          0    38755    bas_acc_chart 
   TABLE DATA           g   COPY accounting.bas_acc_chart (acc_id, acc_name, init_balance, balance, inactive, tree_id) FROM stdin;
 
   accounting          derole    false    219   f�       h          0    38764    eve_acc_entries 
   TABLE DATA           \   COPY accounting.eve_acc_entries (entry_id, debit, credit, bus_trans_id, acc_id) FROM stdin;
 
   accounting          derole    false    221   ��       j          0    38769    eve_bus_transactions 
   TABLE DATA           r   COPY accounting.eve_bus_transactions (trans_id, trans_date, occur_date, entity_id, trans_value, memo) FROM stdin;
 
   accounting          derole    false    223   ^�       m          0    38790    bas_permissions 
   TABLE DATA           T   COPY auth.bas_permissions (permission_id, user_id, role_id, created_at) FROM stdin;
    auth          derole    false    227   	�       o          0    38795 	   bas_roles 
   TABLE DATA           =   COPY auth.bas_roles (role_id, name, description) FROM stdin;
    auth          derole    false    229   &�       q          0    38801    bas_table_permissions 
   TABLE DATA           q   COPY auth.bas_table_permissions (tpermission_id, table_id, role_id, can_read, can_write, can_delete) FROM stdin;
    auth          derole    false    231   C�       s          0    38805 
   bas_tables 
   TABLE DATA           8   COPY auth.bas_tables (table_id, table_name) FROM stdin;
    auth          derole    false    233   `�       u          0    38811 	   bas_users 
   TABLE DATA           W   COPY auth.bas_users (user_id, user_name, user_password, email, created_at) FROM stdin;
    auth          derole    false    235   }�       w          0    38818    eve_access_tokens 
   TABLE DATA           O   COPY auth.eve_access_tokens (token_id, token, user_id, created_at) FROM stdin;
    auth          derole    false    237   ��       y          0    38825    eve_audit_log 
   TABLE DATA           L   COPY auth.eve_audit_log (log_id, user_id, activity, created_at) FROM stdin;
    auth          derole    false    239   ��       {          0    38832    eve_refresh_tokens 
   TABLE DATA           Q   COPY auth.eve_refresh_tokens (rtoken_id, token, user_id, created_at) FROM stdin;
    auth          derole    false    241   �       l          0    38779    bas_entities 
   TABLE DATA           s   COPY entities.bas_entities (entity_id, entity_name, entity_parent, entity_password, email, created_at) FROM stdin;
    entities          derole    false    225   ,�       ~          0    38840    todos 
   TABLE DATA           /   COPY public.todos (id, text, done) FROM stdin;
    public          derole    false    244   �       �          0    38847    bas_all_columns 
   TABLE DATA           m   COPY syslogic.bas_all_columns (text_id, sch_name, tab_name, col_name, show_front_end, data_type) FROM stdin;
    syslogic          derole    false    246   ��       �          0    38853    bas_data_dic 
   TABLE DATA           u   COPY syslogic.bas_data_dic (def_id, def_name, def_class, col_id, en_us, pt_br, on_allowed_language_list) FROM stdin;
    syslogic          derole    false    247   ��       �          0    38858    bas_data_dic_class 
   TABLE DATA           S   COPY syslogic.bas_data_dic_class (class_id, class_name, "Description") FROM stdin;
    syslogic          derole    false    248   U�       �           0    0    bas_acc_chart_acc_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('accounting.bas_acc_chart_acc_id_seq', 55, true);
       
   accounting          derole    false    220            �           0    0    eve_acc_entries_entry_id_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('accounting.eve_acc_entries_entry_id_seq', 83, true);
       
   accounting          derole    false    222            �           0    0 !   eve_bus_transactions_trans_id_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('accounting.eve_bus_transactions_trans_id_seq', 31, true);
       
   accounting          derole    false    224            �           0    0 !   bas_permissions_permission_id_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('auth.bas_permissions_permission_id_seq', 1, false);
          auth          derole    false    228            �           0    0    bas_roles_role_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('auth.bas_roles_role_id_seq', 1, false);
          auth          derole    false    230            �           0    0 (   bas_table_permissions_tpermission_id_seq    SEQUENCE SET     U   SELECT pg_catalog.setval('auth.bas_table_permissions_tpermission_id_seq', 1, false);
          auth          derole    false    232            �           0    0    bas_tables_table_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('auth.bas_tables_table_id_seq', 1, false);
          auth          derole    false    234            �           0    0    bas_users_user_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('auth.bas_users_user_id_seq', 1, true);
          auth          derole    false    236            �           0    0    eve_access_tokens_token_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('auth.eve_access_tokens_token_id_seq', 1, false);
          auth          derole    false    238            �           0    0    eve_audit_log_log_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('auth.eve_audit_log_log_id_seq', 1, false);
          auth          derole    false    240            �           0    0     eve_refresh_tokens_rtoken_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('auth.eve_refresh_tokens_rtoken_id_seq', 1, false);
          auth          derole    false    242            �           0    0    bas_entities_entity_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('entities.bas_entities_entity_id_seq', 34, true);
          entities          derole    false    243            �           0    0    todos_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.todos_id_seq', 20, true);
          public          derole    false    245            �           0    0    bas_data_dic_class_class_id_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('syslogic.bas_data_dic_class_class_id_seq', 2, true);
          syslogic          derole    false    249            �           0    0    bas_data_dic_def_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('syslogic.bas_data_dic_def_id_seq', 481, true);
          syslogic          derole    false    250            �           2606    38881     bas_acc_chart bas_acc_chart_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY accounting.bas_acc_chart
    ADD CONSTRAINT bas_acc_chart_pkey PRIMARY KEY (acc_id);
 N   ALTER TABLE ONLY accounting.bas_acc_chart DROP CONSTRAINT bas_acc_chart_pkey;
    
   accounting            derole    false    219            �           2606    38883 $   eve_acc_entries eve_acc_entries_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY accounting.eve_acc_entries
    ADD CONSTRAINT eve_acc_entries_pkey PRIMARY KEY (entry_id);
 R   ALTER TABLE ONLY accounting.eve_acc_entries DROP CONSTRAINT eve_acc_entries_pkey;
    
   accounting            derole    false    221            �           2606    38885 .   eve_bus_transactions eve_bus_transactions_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY accounting.eve_bus_transactions
    ADD CONSTRAINT eve_bus_transactions_pkey PRIMARY KEY (trans_id);
 \   ALTER TABLE ONLY accounting.eve_bus_transactions DROP CONSTRAINT eve_bus_transactions_pkey;
    
   accounting            derole    false    223            �           2606    38887 $   bas_permissions bas_permissions_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY auth.bas_permissions
    ADD CONSTRAINT bas_permissions_pkey PRIMARY KEY (permission_id);
 L   ALTER TABLE ONLY auth.bas_permissions DROP CONSTRAINT bas_permissions_pkey;
       auth            derole    false    227            �           2606    38889    bas_roles bas_roles_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY auth.bas_roles
    ADD CONSTRAINT bas_roles_pkey PRIMARY KEY (role_id);
 @   ALTER TABLE ONLY auth.bas_roles DROP CONSTRAINT bas_roles_pkey;
       auth            derole    false    229            �           2606    38891 0   bas_table_permissions bas_table_permissions_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_pkey PRIMARY KEY (tpermission_id);
 X   ALTER TABLE ONLY auth.bas_table_permissions DROP CONSTRAINT bas_table_permissions_pkey;
       auth            derole    false    231            �           2606    38893    bas_tables bas_tables_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY auth.bas_tables
    ADD CONSTRAINT bas_tables_pkey PRIMARY KEY (table_id);
 B   ALTER TABLE ONLY auth.bas_tables DROP CONSTRAINT bas_tables_pkey;
       auth            derole    false    233            �           2606    38895    bas_users bas_users_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY auth.bas_users
    ADD CONSTRAINT bas_users_pkey PRIMARY KEY (user_id);
 @   ALTER TABLE ONLY auth.bas_users DROP CONSTRAINT bas_users_pkey;
       auth            derole    false    235            �           2606    38897 (   eve_access_tokens eve_access_tokens_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY auth.eve_access_tokens
    ADD CONSTRAINT eve_access_tokens_pkey PRIMARY KEY (token_id);
 P   ALTER TABLE ONLY auth.eve_access_tokens DROP CONSTRAINT eve_access_tokens_pkey;
       auth            derole    false    237            �           2606    38899     eve_audit_log eve_audit_log_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY auth.eve_audit_log
    ADD CONSTRAINT eve_audit_log_pkey PRIMARY KEY (log_id);
 H   ALTER TABLE ONLY auth.eve_audit_log DROP CONSTRAINT eve_audit_log_pkey;
       auth            derole    false    239            �           2606    38901 *   eve_refresh_tokens eve_refresh_tokens_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY auth.eve_refresh_tokens
    ADD CONSTRAINT eve_refresh_tokens_pkey PRIMARY KEY (rtoken_id);
 R   ALTER TABLE ONLY auth.eve_refresh_tokens DROP CONSTRAINT eve_refresh_tokens_pkey;
       auth            derole    false    241            �           2606    38903    bas_entities bas_entities_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY entities.bas_entities
    ADD CONSTRAINT bas_entities_pkey PRIMARY KEY (entity_id);
 J   ALTER TABLE ONLY entities.bas_entities DROP CONSTRAINT bas_entities_pkey;
       entities            derole    false    225            �           2606    38905    todos todos_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.todos
    ADD CONSTRAINT todos_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.todos DROP CONSTRAINT todos_pkey;
       public            derole    false    244            �           2606    38907 $   bas_all_columns bas_all_columns_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY syslogic.bas_all_columns
    ADD CONSTRAINT bas_all_columns_pkey PRIMARY KEY (text_id);
 P   ALTER TABLE ONLY syslogic.bas_all_columns DROP CONSTRAINT bas_all_columns_pkey;
       syslogic            derole    false    246            �           2606    38909 *   bas_data_dic_class bas_data_dic_class_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY syslogic.bas_data_dic_class
    ADD CONSTRAINT bas_data_dic_class_pkey PRIMARY KEY (class_id);
 V   ALTER TABLE ONLY syslogic.bas_data_dic_class DROP CONSTRAINT bas_data_dic_class_pkey;
       syslogic            derole    false    248            �           2606    38911    bas_data_dic bas_data_dic_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY syslogic.bas_data_dic
    ADD CONSTRAINT bas_data_dic_pkey PRIMARY KEY (def_id);
 J   ALTER TABLE ONLY syslogic.bas_data_dic DROP CONSTRAINT bas_data_dic_pkey;
       syslogic            derole    false    247            �           2620    38912 +   bas_all_columns delete_bas_data_dic_trigger    TRIGGER     �   CREATE TRIGGER delete_bas_data_dic_trigger AFTER DELETE ON syslogic.bas_all_columns FOR EACH ROW EXECUTE FUNCTION syslogic.delete_bas_data_dic();
 F   DROP TRIGGER delete_bas_data_dic_trigger ON syslogic.bas_all_columns;
       syslogic          derole    false    341    246            �           2620    38913 +   bas_all_columns insert_bas_data_dic_trigger    TRIGGER     �   CREATE TRIGGER insert_bas_data_dic_trigger AFTER INSERT ON syslogic.bas_all_columns FOR EACH ROW EXECUTE FUNCTION syslogic.insert_bas_data_dic();
 F   DROP TRIGGER insert_bas_data_dic_trigger ON syslogic.bas_all_columns;
       syslogic          derole    false    342    246            �           2606    38914 1   eve_acc_entries eve_acc_entries_bus_trans_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY accounting.eve_acc_entries
    ADD CONSTRAINT eve_acc_entries_bus_trans_id_fkey FOREIGN KEY (bus_trans_id) REFERENCES accounting.eve_bus_transactions(trans_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 _   ALTER TABLE ONLY accounting.eve_acc_entries DROP CONSTRAINT eve_acc_entries_bus_trans_id_fkey;
    
   accounting          derole    false    3505    221    223            �           2606    38919 8   eve_bus_transactions eve_bus_transactions_entity_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY accounting.eve_bus_transactions
    ADD CONSTRAINT eve_bus_transactions_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entities.bas_entities(entity_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 f   ALTER TABLE ONLY accounting.eve_bus_transactions DROP CONSTRAINT eve_bus_transactions_entity_id_fkey;
    
   accounting          derole    false    223    225    3507            �           2606    38924 .   bas_permissions bas_permissions_entity_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY auth.bas_permissions
    ADD CONSTRAINT bas_permissions_entity_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) NOT VALID;
 V   ALTER TABLE ONLY auth.bas_permissions DROP CONSTRAINT bas_permissions_entity_id_fkey;
       auth          derole    false    235    3517    227            �           2606    38929 8   bas_table_permissions bas_table_permissions_role_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES auth.bas_roles(role_id) ON DELETE CASCADE;
 `   ALTER TABLE ONLY auth.bas_table_permissions DROP CONSTRAINT bas_table_permissions_role_id_fkey;
       auth          derole    false    231    3511    229            �           2606    38934 9   bas_table_permissions bas_table_permissions_table_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY auth.bas_table_permissions
    ADD CONSTRAINT bas_table_permissions_table_id_fkey FOREIGN KEY (table_id) REFERENCES auth.bas_tables(table_id) ON DELETE CASCADE;
 a   ALTER TABLE ONLY auth.bas_table_permissions DROP CONSTRAINT bas_table_permissions_table_id_fkey;
       auth          derole    false    233    231    3515            �           2606    38939 0   eve_access_tokens eve_access_tokens_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY auth.eve_access_tokens
    ADD CONSTRAINT eve_access_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 X   ALTER TABLE ONLY auth.eve_access_tokens DROP CONSTRAINT eve_access_tokens_user_id_fkey;
       auth          derole    false    3517    235    237            �           2606    38944 *   eve_audit_log eve_audit_log_entity_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY auth.eve_audit_log
    ADD CONSTRAINT eve_audit_log_entity_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) NOT VALID;
 R   ALTER TABLE ONLY auth.eve_audit_log DROP CONSTRAINT eve_audit_log_entity_id_fkey;
       auth          derole    false    235    239    3517            �           2606    38949 2   eve_refresh_tokens eve_refresh_tokens_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY auth.eve_refresh_tokens
    ADD CONSTRAINT eve_refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.bas_users(user_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 Z   ALTER TABLE ONLY auth.eve_refresh_tokens DROP CONSTRAINT eve_refresh_tokens_user_id_fkey;
       auth          derole    false    241    3517    235            �           2606    38954 %   bas_data_dic bas_data_dic_col_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY syslogic.bas_data_dic
    ADD CONSTRAINT bas_data_dic_col_id_fkey FOREIGN KEY (col_id) REFERENCES syslogic.bas_all_columns(text_id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 Q   ALTER TABLE ONLY syslogic.bas_data_dic DROP CONSTRAINT bas_data_dic_col_id_fkey;
       syslogic          derole    false    246    247    3527            �           3466    38975    sync_bas_all_columns_event    EVENT TRIGGER     �   CREATE EVENT TRIGGER sync_bas_all_columns_event ON ddl_command_end
         WHEN TAG IN ('ALTER TABLE', 'CREATE TABLE', 'DROP TABLE')
   EXECUTE FUNCTION public.sync_bas_all_columns_trigger();
 /   DROP EVENT TRIGGER sync_bas_all_columns_event;
                postgres    false    340            f     x��U�n�0�ɯ�%�1:�H� 	2ua$�% �
EA�~J�!�Щ��U?�+і=���a�{t��=�>���"�����W�a�VV����|�[���'��NDBZ����O"�D>x��Y#�򏒚\�������v�Z��H�������b�\�<��xyP2�5��5�㼴����r�	�#��W7m�5��
�3��CG��S���gh�3�'!�:�<���A۹0;���*"��|��́O���rTt�U�s���rr�w2�Fo_�K�����+rr!i�u�	0�PM�N*ß������h�[�\��|�]��I&�����Ft�v"�N�X{nfh�.�Q�X����hce�'�#u��oy_m|�3h2� ����M�����(~�l��풏J���%z*�՜�Cp���|�%˷I4�A������qS�.���C'�z,�����N�"���=���I�*N���5��dM��v?�U�1}�����������"��5�{ C��8�K���}�&��{��M6�V�Ry��9T�d i�I�#x},�hr�a!������tͭ0��*�6yd�-C��Τ��
��6d�jƩZ�2��k߆n	��ur,ȍ��9�nH�K0)�E�>���@��@%�V±$�;\��S��p�D��mq4�̃e&*a����`�*�P�����p3>��UK�(d 3J]6�=��(�V��<�N���5�-�1у��X�k�� �e:���3���}N�      h   �   x�U�I� E�p��Lw����AIJ6�<?�j�i��������G�&֏V7�Ե- �o	r.�kpI�ܱ3M����bW�V</`gi0�+�	S�Q��!�vB-�C��r(=e/C9P�N@���K�����K�Q]5�����~hlHէOHѸZڣ��9��w��U��u�^DW��(H�%��D�#SX      j   �  x����n�0���S�[ɩ���@��E�C.�06��DW�S,��Cߡ׼ؔ8���n�m�E��(���L_��|��H�k=��%�Ң#*�y|�@�`���'x���)h0  �kkR���!~����t<	�o>R��̋����*Q}2��D(�lŁ��p�f��E��Lqrj�OK�)�����
EM��I?�ә��bm׸y��N�b+���o0�(���1x��M��a��a��5���W�H�«�<�wu����pS�z[v���4��8C!��;�3=DsљnH��������ǌ�2��]�#ۡٯ��c��xi8��/x
�l�N��8ď������UY��\CkLR.#���fu�MzI�	Ϳ|K����;a�᎗>�5y��~�+�� �+�      m      x������ � �      o      x������ � �      q      x������ � �      s      x������ � �      u   H   x�3�t+JMI-�L�WN,�M�+��,NI� �t#�0202�50�5�P04�21�20�35065������� 3��      w      x������ � �      y      x������ � �      {      x������ � �      l   C  x��ӽn�0 �����	���RAA
�P'q���"���雁8Ƀ���w�9�R�G�=���#.fQ>��%K/Y4�H�4Ha�x1��3X��-	�b�ld����v�+C�v�F9�:lh53N��Y�F9�M�|o�/��pT��4�A=�����p���S+_��4w�h��#��S��%��{C�L�`�W;���;Z ���F}���^?�:����I��э��6�:�Ma�J�MgP`+g���P�a���j/]���h�����4�+1�M?Rw��9�6CB�{�.h6�}5���HW9Ҏ8σ �}�<�      ~   <   x�34��M�)M��L�2��LJ�I�J�-9K/TH�O�8���S�K3���=... �d�      �     x���ێ� ���S�4O�[�7�hջJ��	��Mӧ/��9�WU'��y`�a�r!�i0r��/\7\�Fܸ2gw%[ƽ�Ev���=�:9�/�� Ms����ʰa�AIQ������+3�t�#?H�V�a�q�eZu��$'s�)wP��Z��>��s ��%K����p��~I��4�"c3"����P�n�z'�&��pŃ�Xǣ����l��b��_�-��)� S2S�DN|hZ�� ETA��T���k��́�[����zn��+�P�����4�k�?.�ם��l`�!M�``x�`uCa#h�m�I��G����/in/��˿q��
h;�����Ofgޞ8������g��ڳ��g�7Fl�Z�ѹ~����5_�'�0�N��]��W!�S�$$��&a)$8`O #mn���_�gs��^��gjX���F^�1O��I�ׂ��Q�қtsގ����Om#.�r�w]#�n�mDZnxc�w`��%�Kj0-n�]�,���n�yW�`�Z���X$��� ����-���zEe?+(��Ps�Z����Ft\����n��2)]�s�|��=����󾮡h_�>�M�C�L����y�@����A9jyEq�'�K�b�W#	��{*e�b#���3�*_l��%����Z�� ����&B}�֣ŝVԥ��\vi���H4gw��cTx��i��UdOUk$B���p���,�z�TZ�u���!^*1^�G?*7^�GD|�g0[�Ǉ��A�:�+4�Ԧ�-�r�Y������3�E��Y?�E���HY�z�4lU���g�'�yM��b�e�i���]�;?��/n� �RH��� ��w�Q��-.Hv�����E�[#�w�5*�[�p/<���ԱHR<�a��Ӵ�/��4�K��P�ǣ����Ho&����z��x��Y��=&��M7�,l5��+�$��e�R�af��$N�B����Zx�]��\乘F/��I��Ь�߭@���&0��Ϸ_^߾~���z�}>�N�{�qL      �   [  x��YK��6]�O����gt�"���,h��"K�j�ϓE�ls��XȢ,S��g�����"���l�]<u�pi��,���u{^�X_�jQ�2!Wڪ��fC̋���c��nkY�X�ڒ�4f8TwI}j�%�8a�*����R��~�lh��:����-��vO���Z�w����'d!�/��[Ɍ�1MK���H���_���b����>��
�y��R�}ݵ���I^Lj��6A�1�r��T��B5P�E��������2=��-�����p��x_��M*�;}6�=�yDܽ_C�^{�h�D���IvR~;\�;5��pZ�%��dmQ�KV�p�	�y��J�Ho'6@	�5� ��"��51.p':z76@	�3���S���(�p�ͭ�n�`'m7����D�������q�q[�(K�np�[���9w�[���n�V7��ܶ���s���
��{T���iu�����>O�PT�y9n׼W#���u��
n �Px�(8�����Ki���
��+� &0��4T�/rӝ}*�?�p(��z�7/4c�0R����Hf� +���I�ɋ`���/���������� ���W�iAe�CY�����@�E���ʦ|�7�J����r[|C^w��N��a-�i�X���BYqe@�j�yLҬ�=��>�,�������B���o��2�e�c|6hM�@�ѫu�.͋w�%�W//L�B~�i�e�RU���[��l��6���]��^�U�������cT]򿤙�Q�[��.��N�(Nl��>��ʨʄ��H�6��T��(�����@�������ݮ�Tx0 ��	��@�=����3�����
���c m�&=gI*�\6@�^Ϧ���|��'㵯RQ�K��Л,N�Ki��UQ����Z�G�U�	k�;�{�U�>����V;C�<;�JE�l}�z�#��6��.}�rs곁�p6A�4��Z�>���ԩ>M$RP�p�EWO��U��[V��7~V�):�>P����K�"~G�!X��5������o�k����\���j9�!�p56�g	���U�1O�k�@}��O��R{��Ru�xg���V��A�ʈ�	�E�Lѳs�JTBڮR<�� ����Y߰|�*?H��t	� ��/`��>UÓ����f��ͨT�h%iNP;�jP���L}�"麲D�Z���4�i݅�.%���<��[_g�yJ�O��
͐NXg>ЦVb��eK�rE]زbKw��?~�� a��l�$~��M�0&��NJn:������-k�Yow/j���~�Q*1Q����PS�  6,/JER�������Қ���s4ii�[*������x      �   �   x�5�1� kx�vn"��	N�&�@��
>$�����T��]���[��A��.�i�"�7#�Q$eLTր͐�,6'�����:�qF콉���on%-	���Sb<㇓�u�5�*E��V�����	9W6     