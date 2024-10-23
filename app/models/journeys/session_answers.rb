module Journeys
  class SessionAnswers
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Dirty
    include Sessions::TeacherId

    attribute :current_school_id, :string # UUID
    attribute :address_line_1, :string
    attribute :address_line_2, :string
    attribute :address_line_3, :string
    attribute :address_line_4, :string
    attribute :postcode, :string
    attribute :date_of_birth, :date
    attribute :teacher_reference_number, :string
    attribute :national_insurance_number, :string
    attribute :email_address, :string
    attribute :bank_sort_code, :string
    attribute :bank_account_number, :string
    attribute :payroll_gender, :string
    attribute :first_name, :string
    attribute :middle_name, :string
    attribute :surname, :string
    attribute :banking_name, :string
    attribute :building_society_roll_number, :string
    attribute :academic_year, AcademicYear::Type.new
    attribute :bank_or_building_society, :string
    attribute :provide_mobile_number, :boolean
    attribute :mobile_number, :string
    attribute :email_verified, :boolean
    attribute :email_verification_secret, :string
    attribute :mobile_verified, :boolean
    attribute :mobile_verification_secret, :string
    attribute :hmrc_bank_validation_succeeded, :boolean
    attribute :hmrc_bank_validation_responses, default: []
    attribute :logged_in_with_tid, :boolean
    attribute :logged_in_with_onelogin, :boolean
    attribute :identity_confirmed_with_onelogin, :boolean
    attribute :details_check, :boolean
    attribute :teacher_id_user_info, default: {}
    attribute :onelogin_user_info, default: {}
    attribute :onelogin_credentials, default: {}
    attribute :onelogin_uid, :string

    attribute :onelogin_idv_first_name, :string
    attribute :onelogin_idv_last_name, :string
    attribute :onelogin_idv_date_of_birth, :date

    attribute :onelogin_auth_at, :datetime
    attribute :onelogin_idv_at, :datetime
    attribute :email_address_check, :boolean
    attribute :mobile_check, :string
    attribute :qualifications_details_check, :boolean
    attribute :dqt_teacher_status, default: {}
    attribute :has_student_loan, :boolean
    attribute :student_loan_plan, :string
    attribute :submitted_using_slc_data, :boolean
    attribute :sent_one_time_password_at, :datetime
    attribute :hmrc_validation_attempt_count, :integer
    attribute :reminder_id, :string

    def has_attribute?(name)
      attribute_names.include?(name.to_s)
    end

    def current_school
      @current_school ||= School.find_by(id: current_school_id)
    end

    def details_check?
      !!details_check
    end

    def email_address_check?
      !!email_address_check
    end

    def provide_mobile_number?
      !!provide_mobile_number
    end

    def hmrc_bank_validation_succeeded?
      !!hmrc_bank_validation_succeeded
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

    def qualifications_details_check?
      !!qualifications_details_check
    end

    def has_student_loan?
      !!has_student_loan
    end

    def email_verified?
      !!email_verified
    end

    def logged_in_with_onelogin?
      logged_in_with_onelogin
    end

    def identity_confirmed_with_onelogin?
      identity_confirmed_with_onelogin
    end
  end
end
