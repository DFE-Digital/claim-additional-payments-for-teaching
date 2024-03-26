module Admin
  module ClaimsHelper
    include Policies::StudentLoans::PresenterMethods
    include Pagy::Frontend

    # Take user back to where View Claim was clicked from
    def claims_backlink_path
      session[:claims_backlink_path] || admin_claims_path
    end

    def claim_links(claims)
      claims.map { |claim| link_to(claim.reference, admin_claim_path(claim), class: "govuk-link") }.to_sentence.html_safe
    end

    def confirming_identity_playbook_url
      "https://docs.google.com/document/d/1wZh68_RV_FTJLxXIDPr3XFtJHW3vRgiXGaBDUo1Q1ZU"
    end

    def admin_eligibility_answers(claim)
      claim.policy::EligibilityAdminAnswersPresenter.new(claim.eligibility).answers
    end

    def admin_policy_options_provided(claim)
      claim.policy_options_provided.map do |option|
        policy = Policies.constantize(option["policy"])
        label = t(:payment_name, scope: policy.locale_key)
        answer = number_to_currency(option["award_amount"], precision: 0)

        [label, answer]
      end
    end

    def personal_data_removed_text
      content_tag(:span, "Removed", class: "capt-text-quiet")
    end

    def admin_personal_details(claim)
      [
        [translate("admin.teacher_reference_number"), claim.teacher_reference_number],
        [translate("govuk_verify_fields.full_name").capitalize, claim.personal_data_removed? ? personal_data_removed_text : claim.full_name],
        [translate("govuk_verify_fields.date_of_birth").capitalize, claim.personal_data_removed? ? personal_data_removed_text : l(claim.date_of_birth, format: :day_month_year)],
        [translate("admin.national_insurance_number"), claim.personal_data_removed? ? personal_data_removed_text : claim.national_insurance_number],
        [translate("govuk_verify_fields.address").capitalize, claim.personal_data_removed? ? personal_data_removed_text : sanitize(claim.address("<br>").html_safe, tags: %w[br])],
        [translate("admin.email_address"), claim.email_address]
      ]
    end

    def admin_student_loan_details(claim)
      [].tap do |a|
        a << [translate("student_loans.admin.student_loan_repayment_amount"), number_to_currency(claim.eligibility.student_loan_repayment_amount)] if claim.eligibility.respond_to?(:student_loan_repayment_amount)
        a << [translate("student_loans.admin.student_loan_repayment_plan"), claim.student_loan_plan&.humanize]
      end
    end

    def admin_submission_details(claim)
      [
        [translate("admin.started_at"), l(claim.created_at)],
        [translate("admin.submitted_at"), l(claim.submitted_at)],
        [translate("admin.decision_deadline"), l(claim.decision_deadline_date)],
        [translate("admin.decision_overdue"), decision_deadline_warning(claim)]
      ]
    end

    def admin_decision_details(decision)
      [].tap do |a|
        a << [translate("admin.decision.created_at"), l(decision.created_at)]
        a << [translate("admin.decision.result"), decision.result.capitalize]
        a << [translate("admin.decision.reasons"), rejected_reasons_list(decision)] if decision.rejected?
        a << [translate("admin.decision.notes"), simple_format(decision.notes, class: "govuk-body")] if decision.notes.present?
        a << [translate("admin.decision.created_by"), user_details(decision.created_by)] if decision.created_by_id?
      end
    end

    def rejected_reasons_list(decision)
      decision.selected_rejected_reasons
        .sort_by { |k| Decision::REJECTED_REASONS.index(k) }
        .map { |reason| t("admin.decision.rejected_reasons.#{reason}") }
        .join(", ")
    end

    def decision_deadline_warning(claim, opts = {})
      days_until_decision_deadline = days_between(Date.today, claim.decision_deadline_date)

      if days_until_decision_deadline.days > Claim::DECISION_DEADLINE_WARNING_POINT
        return opts.key?(:na_text) ? opts[:na_text] : I18n.t("admin.decision_overdue_not_applicable")
      end

      decision_deadline_warning_lozenge(days_until_decision_deadline)
    end

    def decision_deadline_warning_lozenge(days_until_decision_deadline)
      decision_deadline_warning_class = (days_until_decision_deadline < 0) ? "tag--alert" : "tag--information"
      content_tag(:strong, pluralize(days_until_decision_deadline, "day"), class: "govuk-tag #{decision_deadline_warning_class}")
    end

    def claim_route(claim)
      claim.logged_in_with_tid? ? I18n.t("admin.claim_route_with_tid") : I18n.t("admin.claim_route_not_tid")
    end

    def matching_attributes(first_claim, second_claim)
      first_attributes = matching_attributes_for(first_claim)
      second_attributes = matching_attributes_for(second_claim)

      matching_attributes = first_attributes & second_attributes
      matching_attributes.to_h.compact.keys.map(&:humanize).sort
    end

    def identity_confirmation_task_claim_verifier_match_status_tag(claim)
      task = claim.tasks.detect { |t| t.name == "identity_confirmation" }

      if task.nil? || task.claim_verifier_match.nil?
        status = "Unverified"
        status_colour = "grey"
      elsif task.passed?
        status = "Passed"
        status_colour = "green"
      elsif task.passed == false
        status = "Failed"
        status_colour = "red"
      elsif task.claim_verifier_match_all?
        status = "Full match"
        status_colour = "green"
      elsif task.claim_verifier_match_any?
        status = "Partial match"
        status_colour = "yellow"
      elsif task.claim_verifier_match_none?
        status = "No match"
        status_colour = "red"
      end

      tag_classes = "govuk-tag app-task-list__task-completed govuk-tag--#{status_colour}"

      content_tag("strong", status, class: tag_classes)
    end

    def qualification_status_tag(claim)
      task_status_tag(claim, task_name)
    end

    def task_status_tag(claim, task_name)
      task = claim.tasks.detect { |t| t.name == task_name }

      if task.nil?
        status = "Incomplete"
        status_colour = "grey"
      elsif task.passed?
        status = "Passed"
        status_colour = "green"
      elsif task.passed == false
        status = "Failed"
        status_colour = "red"
      elsif task.claim_verifier_match_all?
        status = "Full match"
        status_colour = "green"
      elsif task.claim_verifier_match_any?
        status = "Partial match"
        status_colour = "yellow"
      elsif task.claim_verifier_match_none?
        status = "No match"
        status_colour = "red"
      elsif task.claim_verifier_match.nil? && %w[census_subjects_taught employment induction_confirmation student_loan_amount student_loan_plan].include?(task_name)
        status = "No data"
        status_colour = "red"
      end

      tag_classes = "govuk-tag app-task-list__task-completed govuk-tag--#{status_colour}"

      content_tag("strong", status, class: tag_classes)
    end

    def claim_summary_heading(claim)
      if claim.decision_made?
        claim.reference + " – " + claim.latest_decision.result.capitalize
      else
        claim.reference
      end
    end

    def status(claim)
      if claim.all_payrolled?
        "Payrolled"
      elsif claim.latest_decision&.approved? && claim.awaiting_qa? && !claim.held?
        "Approved awaiting QA"
      elsif claim.latest_decision&.approved?
        "Approved awaiting payroll"
      elsif claim.latest_decision&.rejected?
        "Rejected"
      elsif claim.held?
        "Awaiting decision - on hold"
      else
        "Awaiting decision - not on hold"
      end
    end

    STATUS_FILTERS = [
      ["Awaiting decision - on hold", "held"],
      ["Awaiting decision - failed bank details", "failed_bank_validation"],
      ["Approved awaiting QA", "approved_awaiting_qa"],
      ["Approved awaiting payroll", "approved_awaiting_payroll"],
      ["Automatically approved awaiting payroll", "automatically_approved_awaiting_payroll"],
      ["Approved", "approved"],
      ["Rejected", "rejected"]
    ]

    def claim_status_filters
      STATUS_FILTERS
    end

    def index_status_filter(status)
      return "awaiting a decision" unless status.present?

      status.humanize.downcase
    end

    NO_CLAIMS = {
      "approved_awaiting_qa" => "There are currently no approved claims awaiting QA.",
      "approved_awaiting_payroll" => "There are currently no approved claims awaiting payroll.",
      "automatically_approved_awaiting_payroll" => "There are currently no automatically approved claims awaiting payroll.",
      "approved" => "There are currently no approved claims.",
      "rejected" => "There are currently no rejected claims."
    }

    def no_claims(status)
      NO_CLAIMS[status] || "There are currently no claims to approve."
    end

    private

    def matching_attributes_for(claim)
      claim.attributes
        .slice(*Claim::MatchingAttributeFinder::ATTRIBUTE_GROUPS_TO_MATCH.flatten)
        .reject { |_, v| v.blank? }
        .to_a
    end

    def days_between(first_date, second_date)
      (second_date - first_date).to_i
    end

    def code_msg(bank_account_verification_response, claim)
      "Error #{bank_account_verification_response.code} - HMRC API failure. No checks have been completed on the claimant’s #{t("admin.#{claim.bank_or_building_society}")} details. Select yes to manually approve the claimant’s #{t("admin.#{claim.bank_or_building_society}")} details"
    end

    def sort_code_msg(bank_account_verification_response)
      if bank_account_verification_response.sort_code_correct?
        "Yes - sort code found"
      else
        "No - sort code not found"
      end
    end

    def account_number_msg(bank_account_verification_response)
      case bank_account_verification_response.account_exists
      when "yes"
        "Yes - sort code and account number match"
      when "no"
        "No - account number not valid for the given sort code"
      when "indeterminate"
        "Indeterminate - sort code and account number not found"
      when "inapplicable"
        "Inapplicable - sort code and/or account number failed initial validation, no further checks completed"
      end
    end

    def name_matches_msg(bank_account_verification_response)
      case bank_account_verification_response.name_matches
      when "yes"
        "Yes - name matches the account holder name"
      when "partial"
        "Partial - After normalisation, the provided name is a close match"
      when "no"
        "No - name does not match the account holder name"
      when "inapplicable"
        "Inapplicable - sort code and/or account number failed initial validation, no further checks completed"
      end
    end

    def zendesk_email_search_url(email_address)
      "https://additional-teaching-payment.zendesk.com/agent/search/1?copy&type=ticket&q=#{CGI.escape(email_address)}"
    end
  end
end
