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
