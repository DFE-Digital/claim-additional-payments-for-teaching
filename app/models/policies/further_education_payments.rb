module Policies
  module FurtherEducationPayments
    include BasePolicy
    extend self

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 10

    URL_SPREADSHEET_ELIGIBLE_PROVIDERS = "https://assets.publishing.service.gov.uk/media/667300fe64e554df3bd0db92/List_of_eligible_FE_providers_and_payment_value_for_levelling_up_premium.xlsx".freeze

    # Options shown to admins when rejecting a claim
    ADMIN_DECISION_REJECTED_REASONS = [
      # FIXME RL: this `placeholder` is required to make the
      # `spec/models/policies/further_education_payments/claim_personal_data_scrubber_spec.rb`
      # test pass. Once we add a real rejection reason we can remove this
      # placeholder. Figured this was better than removing the test!
      :placeholder
    ]

    # TODO: This is needed once the reply-to email address has been added to Gov Notify
    def notify_reply_to_id
      nil
    end
  end
end
