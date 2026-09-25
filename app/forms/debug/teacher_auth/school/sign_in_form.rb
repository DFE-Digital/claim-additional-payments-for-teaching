require "faker"

module Debug
  module TeacherAuth
    module School
      class SignInForm < Form
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveRecord::AttributeAssignment

        attribute :verified_name, :string
        attribute :verified_date_of_birth, :date
        attribute :email, :string
        attribute :trn, :string
        attribute :sub, :string
        attribute :has_national_insurance_number, :boolean
        attribute :national_insurance_number, :string

        def has_national_insurance_number?
          has_national_insurance_number
        end

        def default_email
          "#{@default_verified_name.downcase.tr(" ", ".")}@example.com"
        end

        def default_verified_name
          Faker::Config.locale = "en-GB"

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

        def default_has_national_insurance_number
          true
        end

        def default_national_insurance_number
          Faker::IdNumber.valid
        end

        def journey
          Journeys::SchoolTargetedRetentionIncentivePayments
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
end
