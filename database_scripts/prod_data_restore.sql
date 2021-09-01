insert into public.notes
select * 
  from notes_bkp;

insert into public.tasks
select * 
  from tasks_bkp;
  
insert into public.early_career_payments_eligibilities
select * 
  from early_career_payments_eligibilities_bkp;
  
insert into public.claims
select * 
  from claims_bkp;
  
insert into public.student_loans_eligibilities  
select * 
  from student_loans_eligibilities_bkp;
