/* Evictions */;

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
		AND oc.date_filed >= '2022-01-01'
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



/* Need to start from recent eevictions, match
 * 
 * 
 */

SELECT id
FROM eviction_addresses.recent_tulsa_evictions rte
LEFT JOIN "public"."case" c ON rte.id = c.id;


REFRESH MATERIALIZED VIEW "eviction_addresses"."tulsa_evictions";

REFRESH MATERIALIZED VIEW "eviction_addresses"."tulsa_eviction_minutes";

ALTER TABLE "eviction_addresses"."recent_tulsa_evictions" OWNER TO "ojo-view-refresher";
ALTER TABLE "eviction_addresses"."recent_tulsa_eviction_minutes" OWNER TO "ojo-view-refresher";



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


/* Cases in mat view that have not been put in case table/work queue */
SELECT
	DISTINCT(rte.id),
	rte.district,
	rte.case_type,
	rte.case_number,
	rte.date_filed,
	current_timestamp AS created_at,
	current_timestamp AS updated_at
FROM eviction_addresses.recent_tulsa_evictions rte
LEFT JOIN eviction_addresses."case" c ON rte.id = c.id
WHERE c.id IS NULL;


/* Insert new case to case table */
/*
INSERT INTO eviction_addresses."case" (id, district, case_type, case_number, date_filed, created_at, updated_at)
VALUES (
	
);
*/



/* Minutes in mat view that have not been put in document table/work queue */
SELECT
	DISTINCT(rtem.id),
	rtem."case",
	rtem.description,
	rtem.link,
	NULL AS internal_link,
	current_timestamp AS created_at,
	current_timestamp AS updated_at
FROM eviction_addresses.recent_tulsa_eviction_minutes rtem
LEFT JOIN eviction_addresses."document" d ON rtem.id = d.id
WHERE d.id IS NULL;



SELECT * FROM eviction_addresses."document" WHERE internal_link IS NULL;



/*
UPDATE eviction_addresses."document" SET internal_link = 'https://storage.googleapis.com/eviction-addresses/%7B%22case%22%3A%20%7B%22district%22%3A%20%22TULSA%22%2C%20%22case_number%22%3A%20%22SC-2022-681%22%7D%2C%20%22rank%22%3A%2011%7D', updated_at = current_timestamp WHERE id = '{"case": {"district": "TULSA", "case_number": "SC-2022-681"}, "rank": 11}'
*/


SELECT
	DISTINCT(d."case"),
	NULL::bool AS success,
	NULL::bool AS working,
	0::int4 AS attempts,
	NULL::timestamp AS started_at,
	NULL::timestamp AS stopped_at,
	current_timestamp AS created_at
FROM eviction_addresses."document" d
LEFT JOIN eviction_addresses.queue q
	ON d."case" = q."case"
WHERE internal_link IS NOT NULL 
	AND q."case" IS NULL;



/* New case ordered by attempts, then date_filed */
SELECT q."case"
FROM eviction_addresses.queue q
LEFT JOIN eviction_addresses."case" c ON q."case" = c."id"
LEFT JOIN public."case" pc ON q."case" = pc.id
WHERE "success" IS NOT TRUE AND "working" IS NOT TRUE
ORDER BY attempts ASC, pc.status DESC, c.date_filed DESC LIMIT 1;


/* Date filed of next cases */
SELECT *
FROM eviction_addresses.queue q
LEFT JOIN eviction_addresses."case" c ON q."case" = c."id"
LEFT JOIN public."case" pc ON q."case" = pc."id"
WHERE "success" IS NOT TRUE
ORDER BY attempts ASC, pc.STATUS DESC, c.date_filed DESC;


/* Number of open cases without address that have a document, by date */

SELECT C.date_filed, count(DISTINCT(C.id))
FROM
	EVICTION_ADDRESSES."case" C
LEFT JOIN EVICTION_ADDRESSES.ADDRESS A ON C.id = A."case"
LEFT JOIN public."case" pc ON c.id = pc.id
INNER JOIN EVICTION_ADDRESSES."document" D ON C.ID = D."case" 
WHERE A."case" IS NULL
	AND pc.STATUS ~ 'Open'
GROUP BY C.date_filed
ORDER BY C.date_filed DESC;



/* CASES BEING WORKED ON */
SELECT *
FROM EVICTION_ADDRESSES."queue" q
WHERE working IS TRUE

/* SET WORKING TO FALSE */

UPDATE EVICTION_ADDRESSES.QUEUE Q
SET WORKING = FALSE
WHERE WORKING IS TRUE;

/* cases with more than one attempt */
SELECT *
FROM EVICTION_ADDRESSES."queue" q
WHERE attempts > 1;


/* set created at from null to now */
UPDATE eviction_addresses.address_migrate Q
SET created_at = current_timestamp, updated_at = current_timestamp
WHERE created_at IS NULL;

/* set accuracy to exact, method to manual */
update eviction_addresses.address_migrate am 
set "method" = 'manual', accuracy = 'mailing'
where "method" is null

/* set geocode service */
update eviction_addresses.address_migrate am 
set "geo_service" = 'postgrid'
where "geo_service" is null


/*

SELECT COUNT(*) FROM eviction_addresses.queue


SELECT * FROM eviction_addresses."document" t WHERE t."case" = '{"district": "TULSA", "case_number": "SC-2022-4025"}'

UPDATE eviction_addresses.queue
SET working = TRUE
WHERE "case" = ''{"district":["TULSA"],"case_number":["SC-2022-4025"]}''

SELECT * FROM eviction_addresses."document" WHERE "case" = '{"district":["TULSA"],"case_number":["SC-2022-4025"]}'

*/


SELECT
	court,
	casenum,
	file_date,
	id
FROM
(
SELECT
	court,
	casenum,
	file_date,
	CONCAT(
		SUBSTRING(casenum, '(\w*-\d*-)'),
		SUBSTRING(casenum, '\w*-\d*-0*(.*)')
	) AS short_casenum
FROM eviction_addresses.old_db_temp
) a
LEFT JOIN public."case" c
	ON (a.casenum = c.case_number OR a.short_casenum = c.case_number)
		AND a.court = c.district;




SELECT count(*)
FROM eviction_addresses.recent_tulsa_evictions rte 
left join eviction_addresses.address a on rte.id = a."case";

select count(*)
from eviction_addresses.recent_tulsa_evictions rte 
left join eviction_addresses."case" c on rte.id = c.id;
	
	
	
select *
from eviction_addresses.address_migrate am 

select
	"id" as "case",
	addr,
	city,
	lon,
	lat,
	addr_method as "method",
	zip,
	current_timestamp as created_at,
	current_timestamp as updated_at
from eviction_addresses.old_db_temp odt 
full join eviction_addresses.id_lookup_temp ilt
	on odt.casenum = ilt.casenum 
		and odt.court = ilt.court 
		and odt.file_date = ilt.file_date;





