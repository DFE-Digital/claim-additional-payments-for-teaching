SELECT * 
  FROM public.claims
 where lower(reference) in ('tcnfkkzf', 'p8r7h88s')
 ORDER BY id ASC
 
create table claims_06sep21_bkp
as SELECT * 
  FROM public.claims
 where lower(reference) in ('tcnfkkzf', 'p8r7h88s')
 ORDER BY id ASC
 
SELECT * 
  FROM public.early_career_payments_eligibilities
 where id in (select eligibility_id from claims_06sep21_bkp)
ORDER BY id ASC 

create table early_career_pay_elig_06sep21_bkp as
SELECT * 
  FROM public.early_career_payments_eligibilities
 where id in (select eligibility_id from claims_06sep21_bkp)
ORDER BY id ASC 

select * from tasks where claim_id in (select id from claims_06sep21_bkp)

create table tasks_06sep21_bkp as
SELECT * 
  FROM public.tasks
 where claim_id in (select id from claims_06sep21_bkp)
ORDER BY id ASC 

select * from claims_06sep21_bkp
select * from early_career_pay_elig_06sep21_bkp


delete from claims where id in (select id from claims_06sep21_bkp)
delete from tasks where claim_id in (select id from claims_06sep21_bkp)
delete from early_career_payments_eligibilities where id in (select id from early_career_pay_elig_06sep21_bkp)

