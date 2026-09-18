CREATE TABLE topics (
    id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE
);

CREATE TABLE products (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         TEXT NOT NULL,
    tagline      TEXT NOT NULL,
    description  TEXT NOT NULL,
    logo_url     TEXT,
    website_url  TEXT NOT NULL,
    launch_date  DATE NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_products_launch_date ON products (launch_date DESC);

CREATE TABLE product_topics (
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    topic_id   BIGINT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, topic_id)
);

CREATE TABLE product_screenshots (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id    BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    url           TEXT NOT NULL,
    display_order INT NOT NULL DEFAULT 0
);
