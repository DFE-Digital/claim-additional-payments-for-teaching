class Admin::Tasks::FeAlternativeVerificationForm
  PERMITTED_PARAMS = %w[passed].freeze

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActionView::Helpers::TextHelper

  attribute :claim
  attribute :admin_user
  attribute :name, :string # aka task_name
  attribute :passed, :boolean

  validates :passed,
    inclusion: {
      in: [true, false],
      message: "You must select ‘Yes’ or ‘No’"
    }

  def self.permitted_params
    PERMITTED_PARAMS
  end

  def data_table_head
    [
      "Alternative verification",
      "Claimant submitted",
      "Provider response"
    ]
  end

  def data_table_rows
    [
      [
        "Does #{school_name} employ #{claimant_name}?",
        claimant_name,
        provider_response_employed_by_school
      ],
      [
        "Date of birth",
        I18n.l(claim.date_of_birth),
        provider_response_date_of_birth
      ],
      [
        "Postcode",
        claim.postcode,
        provider_response_postcode
      ],
      [
        "National Insurance number",
        claim.national_insurance_number,
        provider_response_national_insurance_number
      ],
      [
        "Do claimant’s bank details match provider’s records?",
        simple_format(
          [claim.banking_name, claim.bank_sort_code, claim.bank_account_number].join("\n"),
          {},
          {wrapper_tag: "div"}
        ),
        provider_response_bank_details_match
      ],
      [
        "Email",
        claim.email_address,
        provider_response_email
      ]
    ]
  end

  def save
    return false if invalid?

    task.update(
      passed:,
      created_by: admin_user,
      manual: true
    )
  end

  def radio_options
    [
      OpenStruct.new(id: true, name: "Yes"),
      OpenStruct.new(id: false, name: "No")
    ]
  end

  def claim_verifier_match
    task.claim_verifier_match
  end

  def translation
    "#{claim.policy.to_s.underscore}.admin.task_questions.#{task.name}"
  end

  def task
    @task ||= claim.tasks.where(name:).first || claim.tasks.build(name:)
  end

  private

  def answer_not_applicable?
    eligibility.provider_verification_claimant_employed_by_college == false
  end

  def not_applicable_answer
    "N/A"
  end

  def provider_response_employed_by_school
    if eligibility.provider_verification_claimant_employed_by_college.nil?
      empty_provider_response
    else
      I18n.t(eligibility.provider_verification_claimant_employed_by_college, scope: :boolean)
    end
  end

  def provider_response_date_of_birth
    return not_applicable_answer if answer_not_applicable?

    if eligibility.provider_verification_claimant_date_of_birth.nil?
      empty_provider_response
    else
      I18n.l(eligibility.provider_verification_claimant_date_of_birth)
    end
  end

  def provider_response_postcode
    return not_applicable_answer if answer_not_applicable?

    eligibility.provider_verification_claimant_postcode.presence ||
      empty_provider_response
  end

  def provider_response_national_insurance_number
    return not_applicable_answer if answer_not_applicable?

    eligibility.provider_verification_claimant_national_insurance_number.presence ||
      empty_provider_response
  end

  def provider_response_bank_details_match
    return not_applicable_answer if answer_not_applicable?

    if eligibility.provider_verification_claimant_bank_details_match.nil?
      empty_provider_response
    else
      I18n.t(eligibility.provider_verification_claimant_bank_details_match, scope: :boolean)
    end
  end

  def provider_response_email
    return not_applicable_answer if answer_not_applicable?

    eligibility.provider_verification_claimant_email.presence ||
      empty_provider_response
  end

  def empty_provider_response
    "Awaiting provider response"
  end

  def eligibility
    claim.eligibility
  end

  def claimant_name
    claim.full_name
  end

  def school_name
    claim.school.name
  end
end
