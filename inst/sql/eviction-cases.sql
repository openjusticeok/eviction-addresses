select c.id, district, case_type, case_number, date_filed, c.created_at, c.updated_at
from "case" c
left join(
	select *
	from "issue" i
) s on c.id = s.case_id
where district = 'TULSA'
	and case_type = 'SC'
	and s.description like 'FORC%'
	and date_filed >= transaction_timestamp() - interval '1 month'