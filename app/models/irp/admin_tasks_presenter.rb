module Irp
  # Used to display the information a claim checker needs to check to either
  # approve or reject a claim.
  class AdminTasksPresenter < BaseAdminTasksPresenter
    include Admin::PresenterMethods

    def home_office_details
      [
        [I18n.t("home_office_nationality"), eligibility.nationality],
        [I18n.t("home_office_passport_number"), eligibility.passport_number]
      ]
    end

    alias_method :home_office_checks, :home_office_details

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

    def bank_approval
      [
        ['test', 'test2'],
        ['test', 'test2']
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
