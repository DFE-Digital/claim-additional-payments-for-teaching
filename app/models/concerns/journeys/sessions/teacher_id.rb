module Journeys
  module Sessions
    module TeacherId
      extend ActiveSupport::Concern

      def logged_in_with_tid?
        !!logged_in_with_tid
      end

      def passed_details_check_with_teacher_id?
        logged_in_with_tid? && details_check?
      end

      def trn_from_tid?
        logged_in_with_tid? && teacher_reference_number.present?
      end

      # This is used to ensure we still show the forms if the personal-details
      # are valid but are valid because they were susequently provided/changed
      # from what was in TID
      # FIXME RL: Once personal details forms have been migrated over to
      # writing to the seession remove the claim argument
      def all_personal_details_same_as_tid?(claim)
        name_same_as_tid?(claim) &&
          dob_same_as_tid?(claim) &&
          nino_same_as_tid?(claim)
      end

      def name_same_as_tid?(claim)
        teacher_id_user_info["given_name"] == claim.first_name &&
          teacher_id_user_info["family_name"] == claim.surname
      end

      def dob_same_as_tid?(claim)
        teacher_id_user_info["birthdate"] == claim.date_of_birth.to_s
      end

      def nino_same_as_tid?(claim)
        teacher_id_user_info["ni_number"] == claim.national_insurance_number
      end

      def trn_same_as_tid?(claim)
        teacher_id_user_info["trn"] == claim.teacher_reference_number
      end
    end
  end
end
