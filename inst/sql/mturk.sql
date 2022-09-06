CREATE TABLE eviction_addresses.hit (
	id serial4 NOT NULL,
	hit_id text NOT NULL,
	created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	approved bool NULL,
	CONSTRAINT hit_pk PRIMARY KEY (id)
);

CREATE TABLE eviction_addresses.worker (
	id serial4 NOT NULL,
	worker_id text NOT NULL,
	created_at timestamp NULL,
	updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT worker_pk PRIMARY KEY (id)
);

CREATE TABLE eviction_addresses."assignment" (
	id serial4 NOT NULL,
	assignment_id text NOT NULL,
	hit int4 NOT NULL,
	approved bool NULL,
	created_at timestamp NULL,
	updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
	worker int4 NOT NULL,
	CONSTRAINT assignment_pk PRIMARY KEY (id),
	CONSTRAINT assignment_fk FOREIGN KEY (worker) REFERENCES eviction_addresses.worker(id) ON DELETE SET NULL ON UPDATE CASCADE,
	CONSTRAINT assignment_hit_fk FOREIGN KEY (hit) REFERENCES eviction_addresses.hit(id) ON DELETE SET NULL ON UPDATE CASCADE
);

