module Admin
  module Tasks
    class AlternativeVerificationForm
      PERMITTED_PARAMS = %w[personal_details_match bank_details_match].freeze

      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActionView::Helpers::TextHelper

      attribute :claim
      attribute :admin_user
      attribute :name, :string # aka task_name
      attribute :personal_details_match, :boolean
      attribute :bank_details_match, :boolean

      validates(
        :personal_details_match,
        inclusion: {
          in: ->(form) { form.personal_details_match_options.map(&:id) },
          message: "You must select ‘Yes’ or ‘No’"
        }
      )

      validates(
        :bank_details_match,
        inclusion: {
          in: ->(form) { form.bank_details_match_options.map(&:id) },
          message: "You must select ‘Yes’ or ‘No’"
        }
      )

      def self.permitted_params
        PERMITTED_PARAMS
      end

      def initialize(params = {})
        super

        if task.persisted?
          self.personal_details_match = params[:personal_details_match] || task.data["personal_details_match"]
          self.bank_details_match = params[:bank_details_match] || task.data["bank_details_match"]
        end
      end

      def employed_by_provider_text
        return empty_provider_response if awaiting_provider_response?

        if practitioner_employed_by_provider?
          "The provider told us that they employ #{claimant_name}."
        else
          "The provider told us that they do not employ #{claimant_name}."
        end
      end

      def bank_details_text
        return empty_provider_response if awaiting_provider_response?
        return "Not applicable" unless practitioner_employed_by_provider?

        if provider_confirmed_bank_details?
          "The provider told us that they recognise the bank account details that #{claimant_name} submitted."
        else
          "The provider told us that they do not recognise the bank account details that #{claimant_name} submitted."
        end
      end

      def personal_details_data_table_head
        [
          "Alternative verification",
          "Claimant submitted",
          "Provider response"
        ]
      end

      def personal_details_data_table_rows
        [
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
            "Email",
            claim.email_address,
            provider_response_email
          ]
        ]
      end

      def personal_details_match_options
        [
          Form::Option.new(id: true, name: "Yes"),
          Form::Option.new(id: false, name: "No")
        ]
      end

      def personal_details_result
        # If the task has been auto failed because bank details were not confirmed
        # by provider, we don't have a personal_details_match value saved.
        return not_applicable_answer if personal_details_match.nil?

        I18n.t(personal_details_match, scope: :boolean)
      end

      def bank_details_result
        # If the task has been auto failed because bank details were not confirmed
        # by provider, we don't have a bank_details_match value saved.
        return not_applicable_answer if bank_details_match.nil?

        I18n.t(bank_details_match, scope: :boolean)
      end

      def bank_details_match_options
        [
          Form::Option.new(id: true, name: "Yes"),
          Form::Option.new(id: false, name: "No")
        ]
      end

      def bank_details_data_table_head
        [
          "Claimant’s Bank Account Name",
          "Claimant’s application name",
          "HMRC result"
        ]
      end

      def bank_details_data_table_rows
        [
          [
            claim.banking_name,
            claim.full_name,
            claim.hmrc_name_match.presence || "No value from HMRC"
          ]
        ]
      end

      def save
        return false if invalid?

        task_data = task.data || {}

        task_data["personal_details_match"] = personal_details_match
        task_data["bank_details_match"] = bank_details_match

        task.update(
          passed: personal_details_match && bank_details_match,
          created_by: admin_user,
          manual: true,
          data: task_data
        )
      end

      def translation
        "#{claim.policy.to_s.underscore}.admin.task_questions.#{task.name}"
      end

      def task
        @task ||= claim.tasks.find_or_initialize_by(name: self.class::TASK_NAME)
      end

      def claimant_name
        claim.full_name
      end

      def personal_details_task_completed_automatically?
        task.persisted? && task.data["personal_details_task_completed_automatically"] == true
      end

      def bank_details_task_completed_automatically?
        task.persisted? && task.data["bank_details_task_completed_automatically"] == true
      end

      def task_completed?
        task.persisted? && !task.passed.nil?
      end

      private

      def eligibility
        claim.eligibility
      end

      def not_applicable_answer
        "N/A"
      end

      def empty_provider_response
        "Awaiting provider response"
      end

      def provider_response_date_of_birth
        return not_applicable_answer if answer_not_applicable?

        if provider_entered_claimant_date_of_birth.nil?
          empty_provider_response
        else
          I18n.l(provider_entered_claimant_date_of_birth)
        end
      end

      def provider_response_postcode
        return not_applicable_answer if answer_not_applicable?

        provider_entered_claimant_postcode.presence || empty_provider_response
      end

      def provider_response_national_insurance_number
        return not_applicable_answer if answer_not_applicable?

        provider_entered_national_insurance_number.presence || empty_provider_response
      end

      def provider_response_bank_details_match
        return not_applicable_answer if answer_not_applicable?

        if provider_entered_bank_details_match.nil?
          empty_provider_response
        else
          I18n.t(provider_entered_bank_details_match, scope: :boolean)
        end
      end

      def provider_response_email
        return not_applicable_answer if answer_not_applicable?

        provider_entered_claimant_email.presence || empty_provider_response
      end
    end
  end
end
