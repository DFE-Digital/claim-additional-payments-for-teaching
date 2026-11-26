require "csv"

module Reports
  class EytrpBusinessAnalysis
    NAME = "EYTRP business analysis"
    HEADERS = [
      "Link",
      "Reference",
      "Submitted at",
      "provider_claim_count",
      "identity confirmation",
      "qualifications",
      "employment",
      "HMRC response",
      "HMRC number of employments found",
      "HMRC check",
      "HMRC check status",
      "HMRC check failure reason",
      "HMRC employer names",
      "HMRC employer payee references",
      "Nursery name",
      "Nursery employer payee references",
      "Nursery registered person",
      "Nursery registered person has ineligible nurseries",
      "Student loan plan",
      "Decision",
      "QA decision",
      "Original rejection reasons",
      "QA rejection reasons"
    ].freeze

    def to_csv
      claims = Claim
        .includes(:tasks, :eligibility, :decisions)
        .by_policy(Policies::EarlyYearsTeachersFinancialIncentivePayments)
        .by_academic_year(AcademicYear.new(2026))
        .where.not(submitted_at: nil)
        .order(created_at: :asc)

      # Eager load the look up for ineligible registered person to avoid an N + 1
      nurseries = claims.map { it.eligibility.nursery }
      ineligible_registered_people = ineligible_registered_people_for(nurseries)

      CSV.generate(write_headers: true, headers: HEADERS) do |csv|
        claims.zip(nurseries) do |claim, nursery|
          csv << claim_row(claim, nursery, ineligible_registered_people)
        end
      end
    end

    private

    def claim_row(claim, nursery, ineligible_registered_people)
      eligibility = claim.eligibility

      employment_task = claim.tasks.detect { it.name == "employment" }

      employment_data = employment_task&.data || {}

      employment_checker = Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck.new(
        setting: nursery,
        hmrc_response_status: eligibility.hmrc_response_status,
        hmrc_response_body: eligibility.hmrc_response_body
      )

      hmrc_employments = employment_checker.send(:employments)

      decisions = claim.decisions.sort_by(&:created_at)

      original_decision = decisions.first

      qa_decision = decisions.last if decisions.size > 1

      admin_site_link = Rails.application.routes.url_helpers.admin_claim_tasks_url(
        claim,
        host: "claim-additional-teaching-payment.service.gov.uk",
        protocol: "https"
      )

      ineligible_registered_person = ineligible_registered_people.include?(
        [
          nursery.file_upload_id,
          nursery.registered_person_name
        ]
      )

      [
        admin_site_link,
        claim.reference,
        claim.submitted_at.iso8601,
        provider_claim_count_status(claim),
        "PASS", # Identity confirm is always a pass
        eligibility.ey_qualification,
        employment_status(employment_task),
        hmrc_response_status(eligibility.hmrc_response_status),
        hmrc_employments.count,
        employment_data["check"],
        employment_data["passed"],
        employment_data["failure_reason"].presence || "N/A",
        hmrc_employments.map { it.dig("employer", "name") }.join(";"),
        hmrc_employments.map { it.dig("employer", "payeReference") }.join(";"),
        nursery.name,
        nursery.paye_references.join(";"),
        nursery.registered_person_name,
        ineligible_registered_person ? "TRUE" : "FALSE",
        student_loan_plan_status(claim.tasks.detect { it.name == "student_loan_plan" }),
        decision_status(original_decision),
        decision_status(qa_decision),
        rejection_reasons(original_decision),
        rejection_reasons(qa_decision)
      ].map { |value| value.to_s.tr(",", " ") }
    end

    def provider_claim_count_status(claim)
      if claim.claim_checking_tasks.applicable_task_names.exclude?("provider_claim_count")
        return "N/A"
      end

      task = claim.tasks.detect { it.name == "provider_claim_count" }

      case task&.passed
      when true then "PASS"
      when false then "FAIL"
      else "INCOMPLETE"
      end
    end

    def employment_status(task)
      case task&.passed
      when true then (task.manual == false) ? "AUTO PASS" : "MANUAL PASS"
      when false then "MANUAL FAIL"
      else "INCOMPLETE"
      end
    end

    def hmrc_response_status(status)
      case status
      when 200 then "FOUND"
      when 404 then "NOT FOUND"
      else "ERROR"
      end
    end

    def ineligible_registered_people_for(nurseries)
      Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider
        .where(eligible: false, file_upload_id: nurseries.map(&:file_upload_id).uniq)
        .distinct
        .pluck(:file_upload_id, :registered_person_name)
        .to_set
    end

    def student_loan_plan_status(task)
      return "N/A" unless task

      case task.passed
      when true then "PASSED"
      when false then "FAILED"
      else "INCOMPLETE"
      end
    end

    def decision_status(decision)
      return "UNDECIDED" unless decision

      decision.approved ? "APPROVED" : "REJECTED"
    end

    def rejection_reasons(decision)
      return "N/A" unless decision && decision.rejected?

      decision
        .rejected_reasons
        .select { |_, result| result.to_i == 1 }
        .keys
        .join(";")
    end
  end
end
