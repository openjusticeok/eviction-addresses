/* Evictions */

DROP MATERIALIZED VIEW "eviction_addresses"."recent_tulsa_evictions" CASCADE;

CREATE MATERIALIZED VIEW "eviction_addresses"."recent_tulsa_evictions" AS (
	SELECT
		oc.id,
		case_number,
		district,
		case_type,
		date_filed,
		date_closed,
		status,
		oc.created_at,
		oi.id AS "issue",
		description,
		disposition
	FROM
		"public"."case" oc
	INNER JOIN "public"."issue" oi ON
		oc.id = oi.case_id
	WHERE
		oc.DISTRICT = 'TULSA'
		AND oc.case_type = 'SC'
		AND DATE_FILED >= '2022-01-01'
		AND oi.description ~* 'EVICTION|(?:ENTRY.*(?:FORCIBLE|DETAINER))|(?:(?:FORCIBLE|DETAINER).*ENTRY)'
);

/* Eviction Documents */;


DROP MATERIALIZED VIEW "eviction_addresses"."recent_tulsa_eviction_minutes";

CREATE MATERIALIZED VIEW "eviction_addresses"."recent_tulsa_eviction_minutes" AS (
	SELECT
		id,
		"case",
		description,
		link,
		NULL AS internal_link,
		created_at,
		updated_at
	FROM
		(
			SELECT
				om.id,
				ote.id AS "case",
				UNNEST(links) AS link,
				om.description,
				om.created_at,
				om.updated_at
			FROM
				"eviction_addresses"."recent_tulsa_evictions" ote
			INNER JOIN "public"."minute" om ON ote.id = om.case_id
			WHERE CARDINALITY(links) != 0
		) a
	WHERE
		a.link ~ 'fmt=pdf$'
);

CREATE TABLE eviction_addresses.queue
(
	id SERIAL PRIMARY KEY,
	created_at TIMESTAMP,
	case_id TEXT,
	started_at TIMESTAMP,
	stopped_at TIMESTAMP,
	success BOOL,
	errors TEXT,
	attempts INT
);
