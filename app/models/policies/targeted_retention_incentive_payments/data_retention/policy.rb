module Policies
  module TargetedRetentionIncentivePayments
    module DataRetention
      class Policy < Policies::DataRetention::BasePolicy
        self.claim_attributes = {
          id: :retained,
          created_at: :retained,
          updated_at: :retained,
          first_name: :inactive_claim_submitted_in_previous_academic_term?,
          middle_name: :inactive_claim_submitted_in_previous_academic_term?,
          surname: :inactive_claim_submitted_in_previous_academic_term?,
          date_of_birth: :inactive_claim_submitted_in_previous_academic_term?,
          address_line_1: :inactive_claim_submitted_in_previous_academic_term?,
          address_line_2: :inactive_claim_submitted_in_previous_academic_term?,
          address_line_3: :inactive_claim_submitted_in_previous_academic_term?,
          address_line_4: :inactive_claim_submitted_in_previous_academic_term?,
          postcode: :inactive_claim_submitted_in_previous_academic_term?,
          payroll_gender: :inactive_claim_submitted_in_previous_academic_term?,
          national_insurance_number: :inactive_claim_submitted_in_previous_academic_term?,
          bank_sort_code: :inactive_claim_submitted_in_previous_academic_term?,
          bank_account_number: :inactive_claim_submitted_in_previous_academic_term?,
          building_society_roll_number: :inactive_claim_submitted_in_previous_academic_term?,
          banking_name: :inactive_claim_submitted_in_previous_academic_term?,
          hmrc_bank_validation_responses: :inactive_claim_submitted_in_previous_academic_term?,
          mobile_number: :inactive_claim_submitted_in_previous_academic_term?,
          teacher_id_user_info: :inactive_claim_submitted_in_previous_academic_term?,
          dqt_teacher_status: :inactive_claim_submitted_in_previous_academic_term?,
        }

        self.eligibility_attributes = {
          id: :retained,
          created_at: :retained,
          updated_at: :retained,
          teacher_reference_number: :retained,
          award_amount: :retained,
          current_school_id: :retained,
          eligible_itt_subject: :retained,
          qualification: :retained,
          itt_academic_year: :retained,
          nqt_in_academic_year_after_itt: :retained,
          teaching_subject_now: :retained,
          employed_as_supply_teacher: :retained,
          subject_to_disciplinary_action: :retained,
          subject_to_formal_performance_action: :retained,
          eligible_degree_subject: :retained,
          employed_directly: :retained,
          has_entire_term_contract: :retained,
          induction_completed: :retained,
          school_somewhere_else: :retained
        }
      end
    end
  end
end
