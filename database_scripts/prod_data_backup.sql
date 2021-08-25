drop table manual_claim_clear_down;

create table manual_claim_clear_down as
(select c.id     "claim_id",
 		ecpe.id  "eligibility_id"
  from public.early_career_payments_eligibilities ecpe,
	   public.claims c
where ecpe.id = c.eligibility_id);

select * 
  from public.notes n
 where claim_id in (select claim_id
					  from public.manual_claim_clear_down);
	    
select * 
  from public.tasks t
 where claim_id in (select claim_id
					  from public.manual_claim_clear_down);
					  
select * 
  from public.early_career_payments_eligibilities ecpe
 where id in (select eligibility_id
					  from public.manual_claim_clear_down);		 

select * 
  from public.claims
 where id in (select claim_id
					  from public.manual_claim_clear_down);
					  
create table notes_bkp as
select * 
  from public.notes n
 where claim_id in (select claim_id
					  from public.manual_claim_clear_down);
	    
create table tasks_bkp as
select * 
  from public.tasks t
 where claim_id in (select claim_id
					  from public.manual_claim_clear_down);
					  
create table early_career_payments_eligibilities_bkp as
select * 
  from public.early_career_payments_eligibilities ecpe
 where id in (select eligibility_id
					  from public.manual_claim_clear_down);		 

create table claims_bkp as
select * 
  from public.claims
 where id in (select claim_id
					  from public.manual_claim_clear_down);					  