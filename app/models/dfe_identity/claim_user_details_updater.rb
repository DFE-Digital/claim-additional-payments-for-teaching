module DfeIdentity
  class ClaimUserDetailsUpdater
    def self.call(claim)
      new(claim).update_with_teacher_id_user_info
    end

    def initialize(claim)
      @claim = claim
    end

    def update_with_teacher_id_user_info
      user_info = @claim.teacher_id_user_info

      if UserInfo.validated?(user_info)
        @claim.update(
          first_name: user_info["given_name"],
          surname: user_info["family_name"],
          teacher_reference_number: user_info["trn"],
          date_of_birth: user_info["birthdate"],
          national_insurance_number: user_info["ni_number"],
          logged_in_with_tid: true,
          dqt_teacher_status: nil
        )
      else
        @claim.update(
          logged_in_with_tid: true,
          details_check: false,
          dqt_teacher_status: nil
        )
      end
    end
  end
end
