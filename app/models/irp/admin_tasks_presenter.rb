module Irp
  # Used to display the information a claim checker needs to check to either
  # approve or reject a claim.
  class AdminTasksPresenter < BaseAdminTasksPresenter
    include Admin::PresenterMethods

    def irp_eligible_school
      [
        # [translate("admin.current_school"), display_school(eligibility.current_school)],
        [translate("irp.admin.tasks.head_teacher"), eligibility.school_headteacher_name],
        [translate("irp.admin.tasks.school"), eligibility.school_name],
        [translate("irp.admin.tasks.address"), eligibility.school_address_line_1],
        [translate("irp.admin.tasks.city"), eligibility.school_city],
        [translate("irp.admin.tasks.postcode"), eligibility.school_postcode]
      ]
    end

    # Name, DOB, Nationality, Passport number
    def irp_id_check
      [
        # [translate("admin.current_school"), display_school(eligibility.current_school)],
        [translate("irp.admin.tasks.full_name"), claim.full_name],
        [translate("irp.admin.tasks.date_of_birth"), claim.date_of_birth],
        [translate("irp.admin.tasks.nationality"), eligibility.nationality],
        [translate("irp.admin.tasks.passport_number"), eligibility.passport_number]
      ]
    end

    def irp_home_office_details
      [
        [translate("irp.admin.tasks.visa_type"), eligibility.visa_type]
      ]
    end

    def irp_date_of_entry
      [
        [translate("irp.admin.tasks.date_of_entry"), eligibility.date_of_entry]
      ]
    end

    def employment
      [
        [translate("admin.current_school"), display_school(eligibility.current_school)]
      ]
    end

    def census_subjects_taught
      [
        ["Subject", eligibility.subject.titleize]
      ]
    end

    def irp_contract_length_check
      [
        [translate("irp.admin.tasks.contract_length"), display_boolean(eligibility.one_year)]
      ]
    end

    def irp_contract_start_date_check
      [
        [translate("irp.admin.tasks.contract_start_date"), eligibility.start_date]
      ]
    end

    def irp_eligible_subject_check
      [
        [translate("irp.admin.tasks.eligible_subject"), eligibility.subject]
      ]
    end

    def irp_fifty_percent_rule_check
      [
        [translate("irp.admin.tasks.eligible_subject"), eligibility.subject]
      ]
    end

    def induction_confirmation
      year_type = eligibility.postgraduate_itt? ? "start" : "end"

      [
        [
          "ITT #{year_type} year",
          I18n.t("answers.qts_award_years.on_date", year: eligibility.itt_academic_year.to_s(:long))
        ]
      ]
    end
  end
end
