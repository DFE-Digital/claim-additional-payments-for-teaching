require "faker"

module Debug
  module TeacherAuth
    class SignInForm < Form
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveRecord::AttributeAssignment

      attribute :verified_name, :string
      attribute :verified_date_of_birth, :date
      attribute :email, :string
      attribute :trn, :string
      attribute :sub, :string
      attribute :has_eligible_qualification, :boolean
      attribute :has_national_insurance_number_on_trs, :boolean
      attribute :trs_national_insurance_number, :string

      def default_email
        "#{@default_verified_name.downcase.tr(" ", ".")}@example.com"
      end

      def default_verified_name
        @default_verified_name ||= Faker::Name.unique.name
      end

      def default_verified_date_of_birth
        rand(50.years.ago..20.years.ago).to_date
      end

      def default_trn
        rand(1000000..9999999)
      end

      def default_sub
        "urn:fdc:gov.uk:2022:#{SecureRandom.base64(30)}"
      end

      def default_has_eligible_qualification
        true
      end

      def default_has_national_insurance_number_on_trs
        true
      end

      def default_trs_national_insurance_number
        [
          ("A".."Z").to_a.sample(2).flatten +
            (0..9).to_a.sample(6).flatten +
            [("A".."D").to_a.sample]
        ].join
      end

      def trs_national_insurance_number
        if has_national_insurance_number_on_trs
          super
        end
      end

      def journey
        Journeys::EarlyYearsTeachersFinancialIncentivePayments
      end

      def load_current_value(attribute)
        public_send "default_#{attribute}"
      end

      def completed?
        journey_session.answers.teacher_auth_completed_at
      end
    end
  end
end
