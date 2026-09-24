module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class HmrcBypassForm < Form
      class EmploymentForm
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveRecord::AttributeAssignment

        validates :start_date, presence: true
        validates :employer_name, presence: true
        validates :employer_paye_reference, presence: true
        validates :employer_address_line_1, presence: true
        validates :employer_postcode, presence: true

        attribute :start_date, :date
        attribute :end_date, :date
        attribute :pay_frequency, :string
        attribute :employer_name, :string
        attribute :employer_paye_reference, :string
        attribute :employer_address_line_1, :string
        attribute :employer_address_line_2, :string
        attribute :employer_address_line_3, :string
        attribute :employer_address_line_4, :string
        attribute :employer_address_line_5, :string
        attribute :employer_postcode, :string
        attribute :payment_date, :date
        attribute :payment_paid_taxable_pay, :decimal

        def to_h
          {
            "startDate" => start_date,
            "endDate" => end_date,
            "payFrequency" => pay_frequency,
            "employer" => {
              "name" => employer_name,
              "payeReference" => employer_paye_reference,
              "address" => {
                "line1" => employer_address_line_1,
                "line2" => employer_address_line_2,
                "line3" => employer_address_line_3,
                "line4" => nil,
                "line5" => nil,
                "postcode" => employer_postcode
              }
            },
            "payment" => [
              {
                "date" => payment_date,
                "paidTaxablePay" => payment_paid_taxable_pay
              }
            ]
          }
        end
      end

      def employments_attributes=(attributes)
        attributes = attributes.values if attributes.respond_to?(:values)
        @employments = attributes.map { |employment| EmploymentForm.new(employment) }
      end

      def save
        if (match = /\ARemove employment ([1-9]\d*)\z/.match(params[:commit].to_s))
          employments.delete_at(match[1].to_i - 1)
          return false
        end

        if params[:commit] == "Add another employment"
          employments << EmploymentForm.new
          return false
        end

        # Set hmrc_api_job_completed so we skip the HmrcEmploymentCheckJob
        journey_session.answers.assign_attributes(
          hmrc_api_job_completed: true,
          hmrc_employment_history: employments.map(&:to_h),
          hmrc_employent_api_call_status: "success"
        )

        employment_check = EmploymentCheck.new(
          setting: answers.nursery,
          employments: answers.hmrc_employment_history
        )

        journey_session.answers.assign_attributes(
          hmrc_employment_check_passed: employment_check.passed?
        )

        journey_session.save!

        true
      end

      def employments
        @employments ||= [EmploymentForm.new(
          start_date: 1.month.ago.to_date,
          end_date: nil,
          pay_frequency: "MONTHLY",
          employer_name: answers.nursery.name,
          employer_address_line_1: answers.nursery.address_line_1,
          employer_address_line_2: answers.nursery.address_line_2,
          employer_address_line_3: answers.nursery.address_line_3,
          employer_postcode: answers.nursery.postcode,
          payment_date: Date.current,
          payment_paid_taxable_pay: 1_000.00
        )]
      end

      private

      def permitted_attributes
        [{employments_attributes: EmploymentForm.attribute_names}]
      end

      def attributes_with_current_value
        return super unless params[:claim].present?

        super.merge("employments_attributes" => permitted_params.fetch(:employments_attributes, []))
      end
    end
  end
end
