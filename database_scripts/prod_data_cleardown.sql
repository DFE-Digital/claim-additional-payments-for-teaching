delete from public.notes 
 where claim_id in (select claim_id
					  from public.manual_claim_clear_down);
	    
delete from public.tasks 
 where claim_id in (select claim_id
					  from public.manual_claim_clear_down);

delete from public.claims
 where id in (select claim_id
					  from public.manual_claim_clear_down);
					  
delete from public.early_career_payments_eligibilities
 where id in (select eligibility_id
					  from public.manual_claim_clear_down);		 
				  
delete from public.student_loans_eligibilities					  
 where id in (select eligibility_id
					  from public.manual_claim_clear_down);		 					  
			  