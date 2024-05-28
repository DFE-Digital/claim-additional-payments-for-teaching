module Journeys
  class SessionAnswers
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Dirty

    attribute :current_school_id, :string # UUID
    attribute :selected_policy, :string
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
    attribute :mobile_verified, :boolean
    attribute :hmrc_bank_validation_succeeded, :boolean
    attribute :hmrc_bank_validation_responses # , :json
    attribute :logged_in_with_tid, :boolean
    attribute :details_check, :boolean
    attribute :teacher_id_user_info, default: {}
    attribute :email_address_check, :boolean
    attribute :mobile_check, :string
    attribute :qualifications_details_check, :boolean
    attribute :dqt_teacher_status, default: {}
    attribute :answered, default: []

    def has_attribute?(name)
      attribute_names.include?(name.to_s)
    end

    def details_check?
      !!details_check
    end

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
