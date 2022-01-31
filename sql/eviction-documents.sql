select *
from (
select t.id, c.id as "case", t.description, unnest(t.links) as link, t.created_at, t.updated_at
from "case" c
left join(
	select *
	from "issue" i
) s on c.id = s.case_id
left join (
	select *
	from "minute" m
	where cardinality(links) != 0
) t on c.id = t.case_id
where district = 'TULSA'
	and case_type = 'SC'
	and s.description like 'FORC%'
	and date_filed >= transaction_timestamp() - interval '1 month'
) v
where v.link like '%fmt=pdf'