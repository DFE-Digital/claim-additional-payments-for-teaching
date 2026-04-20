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

      def journey
        Journeys::EarlyYearsTeachersFinancialIncentivePayments
      end

      def load_current_value(attribute)
        public_send "default_#{attribute}"
      end
    end
  end
end
