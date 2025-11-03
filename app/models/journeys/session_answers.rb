module Journeys
  class SessionAnswers
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Dirty
    include Sessions::TeacherId
    include Sessions::PiiAttributes
    include BooleanAttributes

    attr_accessor :session

    attribute :service_access_code, :string, pii: false

    attribute :previously_claimed, :boolean, pii: false
    attribute :have_one_login_account, :string, pii: false # trinary option
    attribute :start_new_claim, :boolean, pii: false

    attribute :current_school_id, :string, pii: false # UUID
    attribute :address_line_1, :string, pii: true
    attribute :address_line_2, :string, pii: true
    attribute :address_line_3, :string, pii: true
    attribute :address_line_4, :string, pii: true
    attribute :postcode, :string, pii: true
    attribute :skip_postcode_search, :boolean, pii: false

    attribute :date_of_birth, :date, pii: true
    attribute :teacher_reference_number, :string, pii: true
    attribute :national_insurance_number, :string, pii: true
    attribute :email_address, :string, pii: true
    attribute :bank_sort_code, :string, pii: true
    attribute :bank_account_number, :string, pii: true
    attribute :payroll_gender, :string, pii: false
    attribute :first_name, :string, pii: true
    attribute :middle_name, :string, pii: true
    attribute :surname, :string, pii: true
    attribute :banking_name, :string, pii: true
    attribute :building_society_roll_number, :string, pii: true
    attribute :academic_year, AcademicYear::Type.new, pii: false
    attribute :bank_or_building_society, :string, pii: false
    attribute :provide_mobile_number, :boolean, pii: false
    attribute :mobile_number, :string, pii: true
    attribute :email_verified, :boolean, pii: false
    attribute :email_verification_secret, :string, pii: true
    attribute :mobile_verified, :boolean, pii: false
    attribute :mobile_verification_secret, :string, pii: true
    attribute :hmrc_bank_validation_succeeded, :boolean, pii: false
    attribute :hmrc_bank_validation_responses, default: [], pii: false
    attribute :logged_in_with_tid, :boolean, pii: false
    attribute :logged_in_with_onelogin, :boolean, pii: false
    attribute :identity_confirmed_with_onelogin, :boolean, pii: false
    attribute :details_check, :boolean, pii: false
    attribute :teacher_id_user_info, default: {}, pii: true
    attribute :ordnance_survey_error, :boolean, pii: false

    attribute :onelogin_user_info, default: {}, pii: true
    attribute :onelogin_credentials, default: {}, pii: true
    attribute :onelogin_uid, :string, pii: false

    attribute :onelogin_idv_first_name, :string, pii: true
    attribute :onelogin_idv_last_name, :string, pii: true
    attribute :onelogin_idv_full_name, :string, pii: true
    attribute :onelogin_idv_date_of_birth, :date, pii: false
    attribute :onelogin_idv_return_codes, default: [], pii: true

    attribute :onelogin_auth_at, :datetime, pii: false
    attribute :onelogin_idv_at, :datetime, pii: false

    attribute :email_address_check, :boolean, pii: false
    attribute :mobile_check, :string, pii: false
    attribute :qualifications_details_check, :boolean, pii: false
    attribute :dqt_teacher_status, default: {}, pii: false
    attribute :has_student_loan, :boolean, pii: false
    attribute :student_loan_plan, :string, pii: false
    attribute :submitted_using_slc_data, :boolean, pii: false
    attribute :sent_one_time_password_at, :datetime, pii: false
    attribute :hmrc_validation_attempt_count, :integer, default: 0, pii: false

    attribute :reminder_id, :string, pii: false
    attribute :reminder_full_name, :string, pii: true
    attribute :reminder_email_address, :string, pii: true
    attribute :reminder_otp_secret, :string, pii: true
    attribute :reminder_otp_confirmed, :boolean, default: false, pii: false # whether or not they have confirmed email via otp

    attribute :submitted_claim_id, :string, pii: false

    attribute :information_provided_completed, :boolean, pii: false

    attribute :possible_school_id, :string, pii: false
    attribute :provision_search, :string, pii: false

    def increment_hmrc_validation_attempt_count
      self.hmrc_validation_attempt_count = attributes["hmrc_validation_attempt_count"] + 1
    end

    def has_attribute?(name)
      attribute_names.include?(name.to_s)
    end

    def current_school
      @current_school ||= School.find_by(id: current_school_id)
    end

    def full_name
      [first_name, middle_name, surname].reject(&:blank?).join(" ")
    end

    def address(separator = ", ")
      [
        address_line_1,
        address_line_2,
        address_line_3,
        address_line_4,
        postcode
      ].reject(&:blank?).join(separator)
    end

    def logged_in_with_tid_and_has_recent_tps_school?
      trn_from_tid? && recent_tps_school.present?
    end

    # NOTE getting the trn from answers.teacher_id_user_info was the previous
    # implementation, TODO switch to `answers.teacher_reference_number` as it's
    # set in the sign in or continue form at the same time.
    def recent_tps_school
      @recent_tps_school ||= TeachersPensionsService.recent_tps_school(
        claim_date: session.created_at,
        teacher_reference_number: teacher_id_user_info["trn"]
      )
    end
  end
end
