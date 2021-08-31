drop table manual_claim_clear_down;

create table manual_claim_clear_down as
(select c.id     "claim_id",
 		ecpe.id  "eligibility_id"
  from public.early_career_payments_eligibilities ecpe,
	   public.claims c
 where ecpe.id = c.eligibility_id);

 alter table manual_claim_clear_down
   add primary key (claim_id, eligibility_id);

insert into manual_claim_clear_down (claim_id, eligibility_id) 
select c.id "claim_id",
	   a.id "eligibility_id"
  from public.student_loans_eligibilities a,
  	   public.claims c
 where a.id = c.eligibility_id
   and a.created_at BETWEEN '2021-04-01T00:00:01' and '2021-10-29T14:33:14';

-- remove two live records:

delete from public.manual_claim_clear_down 
 where claim_id in ('53bb575d-1cf0-4be4-a37f-b370acb70085', '526c4313-4e97-485d-91e4-e25d3ccf4b01')

select teacher_reference_number, reference  
  from public.claims 
 where id in (select claim_id
                from manual_claim_clear_down);
 
select * 
  from public.student_loans_eligibilities n
 where id in (select eligibility_id
					  from public.manual_claim_clear_down);

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
					  
create table student_loans_eligibilities_bkp as
select * 
  from public.student_loans_eligibilities n
 where id in (select eligibility_id
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
					  
select count(*) from notes_bkp;
select count(*) from early_career_payments_eligibilities_bkp;
select count(*) from student_loans_eligibilities_bkp;
select count(*) from tasks_bkp;
select count(*) from claims_bkp;					  