module StudentLoans
  class PermittedParameters
    EMPLOYMENT_PARAMETERS = [
      :id,
      :school_id,
      :taught_eligible_subjects,
      :student_loan_repayment_amount,
      StudentLoans::Employment::SUBJECT_ATTRIBUTES,
    ].flatten.freeze

    ELIGIBILITY_PARAMETERS = [
      :id,
      :qts_award_year,
      :employment_status,
      :current_school_id,
      :had_leadership_position,
      :mostly_performed_leadership_duties,
      employments_attributes: EMPLOYMENT_PARAMETERS,
    ].freeze

    PARAMETERS = [
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4,
      :postcode,
      :payroll_gender,
      :teacher_reference_number,
      :national_insurance_number,
      :has_student_loan,
      :student_loan_country,
      :student_loan_courses,
      :student_loan_start_date,
      :email_address,
      :bank_sort_code,
      :bank_account_number,
      eligibility_attributes: ELIGIBILITY_PARAMETERS,
    ].freeze

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def keys
      PARAMETERS.dup - claim.verified_fields.map(&:to_sym)
    end
  end
end
