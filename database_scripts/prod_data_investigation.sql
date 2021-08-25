--View a list of submitted ECP claims' eligibility criteria
select * 
  from public.early_career_payments_eligibilities
 where created_at BETWEEN '2021-06-08T00:00:01' and '2021-10-29T14:33:14' -- e.g. Datetime format 2021-04-29T14:33:14
 order by created_at

--View a list of submitted ECP claims
select * 
  from public.claims
 where eligibility_type = 'EarlyCareerPayments::Eligibility'
 order by created_at;

--Get total number of submitted ECP claims
select count(*) 
  from public.claims 
 where eligibility_type = 'EarlyCareerPayments::Eligibility';

select eligibility_type
       , max(created_at) "maxcreated"
	   , min(created_at) "mincreated"
	   , max(updated_at) "maxupdated"
	   , min(updated_at) "minupdated"
	   , count(*) 
  from public.claims 
 group by eligibility_type;
-- where eligibility_type = 'EarlyCareerPayments::Eligibility';

--View a list of submitted ECP claims' eligibility criteria
select c.first_name, 
	   c.surname, 
	   a.id "ecp-id", 
	   c.id "claim-id"
  from public.early_career_payments_eligibilities a,
  	   public.claims c
where a.id = c.eligibility_id
  and a.created_at BETWEEN '2021-06-08T00:00:01' and '2021-10-29T14:33:14'; -- e.g. Datetime format 2021-04-29T14:33:14

--View a list of submitted ECP claims
select * from 
where eligibility_type = 'EarlyCareerPayments::Eligibility'
order by created_at;

rollback;


--View a list of submitted ECP claims' eligibility criteria
select c.first_name, 
	   c.surname, 
	   ecpe.id "ecp-id", 
	   c.id "claim-id"
  from public.early_career_payments_eligibilities ecpe,
  	   public.claims c,
-- 	   public.support_tickets st
--	   public.notes n
--	   public.amendments a
--	   public.decisions d
public.tasks t
 where ecpe.id = c.eligibility_id
--   and st.claim_id = c.id
--   and n.claim_id = c.id
--   and a.claim_id = c.id
--   and d.claim_id = c.id
   and t.claim_id = c.id
   and ecpe.created_at BETWEEN '2021-06-08T00:00:01' and '2021-10-29T14:33:14'; -- e.g. Datetime format 2021-04-29T14:33:14
   





