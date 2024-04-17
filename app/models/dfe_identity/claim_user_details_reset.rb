module DfeIdentity
  class ClaimUserDetailsReset
    def self.call(claim, reset_type)
      new(claim, reset_type).reset_teacher_id_user_info
    end

    def initialize(claim, reset_type)
      @claim = claim
      @reset_type = reset_type
    end

    def reset_teacher_id_user_info
      case @reset_type
      when :details_incorrect
        @claim.update(
          first_name: "",
          surname: "",
          teacher_reference_number: "",
          date_of_birth: nil,
          national_insurance_number: "",
          logged_in_with_tid: false
        )
      when :skipped_tid
        @claim.update(
          first_name: "",
          surname: "",
          teacher_reference_number: "",
          date_of_birth: nil,
          national_insurance_number: "",
          logged_in_with_tid: false,
          details_check: nil,
          teacher_id_user_info: {}
        )
      end
    end
  end
end
