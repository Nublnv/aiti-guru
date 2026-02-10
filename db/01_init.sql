--
-- PostgreSQL database dump
--

-- Dumped from database version 18.1 (Debian 18.1-1.pgdg13+2)
-- Dumped by pg_dump version 18.1 (Debian 18.1-1.pgdg13+2)


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


--
-- Name: prevent_cycles_parent(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_cycles_parent() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.parent_id IS NULL THEN
        RETURN NEW;
    END IF;
	IF index(
		    (SELECT path FROM public.categories WHERE id = NEW.parent_id FOR SHARE),
		    text2ltree(NEW.id::text)
		) >= 0
    THEN
        RAISE EXCEPTION 'Cycle detected: node % cannot be child of %',
            NEW.id, NEW.parent_id;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.prevent_cycles_parent() OWNER TO postgres;

--
-- Name: update_children_paths(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_children_paths() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.parent_id = NEW.parent_id THEN
        RETURN NULL;
    END IF;

    UPDATE public.categories
    SET path = NEW.path || subpath(
        path,
        nlevel(OLD.path)
    )
    WHERE path <@ OLD.path
      AND id <> NEW.id;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_children_paths() OWNER TO postgres;

--
-- Name: update_ltree_path(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_ltree_path() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.parent_id IS NULL THEN
        NEW.path := text2ltree(NEW.id::text);
    ELSE
        NEW.path := (
            SELECT path || text2ltree(NEW.id::text)
            FROM public.categories
            WHERE id = NEW.parent_id
        );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_ltree_path() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    label character varying NOT NULL,
    path public.ltree NOT NULL,
    parent_id bigint,
    CONSTRAINT path_ends_with_id CHECK (((public.subpath(path, (public.nlevel(path) - 1), 1))::text = (id)::text)),
    CONSTRAINT path_no_cycle CHECK (((public.nlevel(path) = 1) OR (public.subpath(path, 0, (public.nlevel(path) - 1)) OPERATOR(public.<>) path)))
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: customes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customes (
    id bigint NOT NULL,
    name character varying NOT NULL,
    address character varying NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL
);


ALTER TABLE public.customes OWNER TO postgres;

--
-- Name: customes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.customes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.customes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.items (
    id bigint NOT NULL,
    label character varying NOT NULL,
    category bigint,
    quantity bigint DEFAULT 0 NOT NULL,
    price real DEFAULT 0 NOT NULL,
    CONSTRAINT items_price_check CHECK ((price > (0.0)::double precision)),
    CONSTRAINT items_quantity_check CHECK ((quantity >= 0))
);


ALTER TABLE public.items OWNER TO postgres;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    is_complete boolean DEFAULT false NOT NULL,
    date timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.orders ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: orders_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders_items (
    order_id bigint NOT NULL,
    item_id bigint NOT NULL,
    quantity bigint NOT NULL,
    CONSTRAINT orders_items_check CHECK ((quantity > 0))
);


ALTER TABLE public.orders_items OWNER TO postgres;

--
-- Name: categories categories_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pk PRIMARY KEY (id);


--
-- Name: customes customes_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customes
    ADD CONSTRAINT customes_pk PRIMARY KEY (id);


--
-- Name: items items_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pk PRIMARY KEY (id);


--
-- Name: orders_items orders_items_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders_items
    ADD CONSTRAINT orders_items_pk PRIMARY KEY (order_id, item_id);


--
-- Name: orders orders_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pk PRIMARY KEY (id);


--
-- Name: idx_categories_path_gist; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_path_gist ON public.categories USING gist (path);


--
-- Name: uq_categories_path; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_categories_path ON public.categories USING btree (path);


--
-- Name: categories trg_prevent_cycles_parent; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_prevent_cycles_parent BEFORE INSERT OR UPDATE OF parent_id ON public.categories FOR EACH ROW EXECUTE FUNCTION public.prevent_cycles_parent();


--
-- Name: categories trg_update_children_paths; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_children_paths AFTER UPDATE OF parent_id ON public.categories FOR EACH ROW EXECUTE FUNCTION public.update_children_paths();


--
-- Name: categories trg_update_ltree_path; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_ltree_path BEFORE INSERT OR UPDATE OF parent_id ON public.categories FOR EACH ROW EXECUTE FUNCTION public.update_ltree_path();


--
-- Name: items items_categories_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_categories_fk FOREIGN KEY (category) REFERENCES public.categories(id) ON UPDATE SET NULL ON DELETE SET NULL;


--
-- Name: orders orders_customes_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_customes_fk FOREIGN KEY (customer_id) REFERENCES public.customes(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: orders_items orders_items_items_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders_items
    ADD CONSTRAINT orders_items_items_fk FOREIGN KEY (item_id) REFERENCES public.items(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: orders_items orders_items_orders_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders_items
    ADD CONSTRAINT orders_items_orders_fk FOREIGN KEY (order_id) REFERENCES public.orders(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--
