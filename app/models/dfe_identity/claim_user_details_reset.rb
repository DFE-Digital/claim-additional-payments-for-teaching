module DfeIdentity
  class ClaimUserDetailsReset
    def self.call(claim)
      new(claim).reset_teacher_id_user_info
    end

    def initialize(claim)
      @claim = claim
    end

    def reset_teacher_id_user_info
      @claim.update(
        first_name: "",
        surname: "",
        teacher_reference_number: "",
        date_of_birth: nil,
        national_insurance_number: "",
        logged_in_with_tid: false
      )
    end
  end
end
