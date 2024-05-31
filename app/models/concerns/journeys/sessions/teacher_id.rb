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

      def all_personal_details_same_as_tid?
        name_same_as_tid? && dob_same_as_tid? && nino_same_as_tid?
      end

      def name_same_as_tid?
        teacher_id_user_info["given_name"] == first_name &&
          teacher_id_user_info["family_name"] == surname
      end

      def dob_same_as_tid?
        teacher_id_user_info["birthdate"] == date_of_birth.to_s
      end

      def nino_same_as_tid?
        teacher_id_user_info["ni_number"] == national_insurance_number
      end

      def trn_same_as_tid?(claim)
        teacher_id_user_info["trn"] == claim.teacher_reference_number
      end

      def using_mobile_number_from_tid?
        logged_in_with_tid? && mobile_check == "use" && provide_mobile_number && mobile_number.present?
      end
    end
  end
end
