#
# Encapsulates business rules around eligibility
#

class Form::EligibilityCheck
  def initialize(form)
    @form = form
    # TODO: Reinstate AppSettings
    # @months_before_service_start = AppSettings.current.service_start_date.months_ago(months_limit).beginning_of_month
    @months_before_service_start = Date.today.months_ago(months_limit).beginning_of_month
  end
  attr_reader :form, :months_before_service_start

  def passed?
    !failed?
  end

  def failed?
    return true if failure_reason

    false
  end

  def failure_reason
    case form
    in application_route: "other"
      I18n.t("application_route_other_not_accepted")
    in one_year: false, application_route: "teacher"
      I18n.t("teacher_contract_duration_of_less_than_one_year_no")
    in state_funded_secondary_school: false
      I18n.t("school_not_state_funded")
    in subject: "other"
      I18n.t("taught_subject_not_accepted")
    in visa_type: "Other"
      I18n.t("visa_not_accepted")
    in start_date: Date unless contract_start_date_eligible?(form.start_date)
      I18n.t("contract_must_start_within_months", count: months_limit_in_words)
    in date_of_entry: Date, start_date: Date unless date_of_entry_eligible?(form.date_of_entry, form.start_date)
      I18n.t("cannot_enter_the_uk_more_than_3_months_before_your")
    else
      nil
    end
  end

  def date_of_entry_eligible?(date_of_entry, start_date)
    return false unless date_of_entry && start_date

    date_of_entry >= start_date - 3.months
  end

  # The contract start date is valid from the start of the previous application window.
  def contract_start_date_eligible?(start_date)
    start_date >= months_before_service_start
  end

  private

  # default to 6 and only allow 5 or 6. anything else results in 6.
  def months_limit
    limit = Rails.configuration.x.form_eligibility.contract_start_months_limit.to_i
    [5, 6].include?(limit) ? limit : 6
  end

  def months_limit_in_words
    (months_limit == 5) ? "five" : "six"
  end
end
