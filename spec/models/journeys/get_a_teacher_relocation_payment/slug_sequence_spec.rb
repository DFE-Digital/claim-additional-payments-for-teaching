require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::SlugSequence do
  before do
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  let(:journey_session) do
    create(:get_a_teacher_relocation_payment_session, answers: {})
  end

  let(:slugs) { described_class.new(journey_session).slugs }

  describe "#slugs" do
    context "eligibility slugs" do
      subject { slugs }

      context "with default settings" do
        it do
          is_expected.to match_array %w[
            previous-payment-received
            application-route
            state-funded-secondary-school
            current-school
            headteacher-details
            contract-details
            start-date
            subject
            changed-workplace-or-new-contract
            breaks-in-employment
            visa
            entry-date
            check-your-answers-part-one
            information-provided
            nationality
            passport-number
            personal-details
            postcode-search
            select-home-address
            address
            email-address
            email-verification
            provide-mobile-number
            mobile-number
            mobile-verification
            personal-bank-account
            gender
            check-your-answers
            confirmation
          ]
        end
      end

      context "when skip_postcode_search is true" do
        before do
          journey_session.answers.assign_attributes(
            skip_postcode_search: true
          )

          journey_session.save!
        end

        it { is_expected.not_to include("select-home-address") }
        it { is_expected.to include("address") }
      end

      context "when ordnance_survey_error is true" do
        before do
          journey_session.answers.assign_attributes(
            ordnance_survey_error: true
          )

          journey_session.save!
        end

        it { is_expected.not_to include("select-home-address") }
        it { is_expected.to include("address") }
      end

      context "when selected address from postcode search" do
        before do
          journey_session.answers.assign_attributes(
            address_line_1: "123 Main Street",
            postcode: "SW1A 1AA"
          )

          journey_session.save!
        end

        it { is_expected.not_to include("address") }
        it { is_expected.to include("postcode-search") }
        it { is_expected.to include("select-home-address") }
      end

      context "when email_verified is true" do
        before do
          journey_session.answers.assign_attributes(
            email_verified: true
          )

          journey_session.save!
        end

        it { is_expected.not_to include("email-verification") }
        it { is_expected.to include("email-address") }
      end

      context "when email_verified is false" do
        before do
          journey_session.answers.assign_attributes(
            email_verified: false
          )

          journey_session.save!
        end

        it { is_expected.to include("email-verification") }
        it { is_expected.to include("email-address") }
      end

      context "when provide_mobile_number is false" do
        before do
          journey_session.answers.assign_attributes(
            provide_mobile_number: false
          )

          journey_session.save!
        end

        it { is_expected.not_to include("mobile-number") }
        it { is_expected.not_to include("mobile-verification") }
        it { is_expected.to include("provide-mobile-number") }
      end

      context "when provide_mobile_number is true" do
        before do
          journey_session.answers.assign_attributes(
            provide_mobile_number: true
          )

          journey_session.save!
        end

        it { is_expected.to include("mobile-number") }
        it { is_expected.to include("mobile-verification") }
        it { is_expected.to include("provide-mobile-number") }
      end

      context "when mobile_verified is true" do
        before do
          journey_session.answers.assign_attributes(
            provide_mobile_number: true,
            mobile_verified: true
          )

          journey_session.save!
        end

        it { is_expected.not_to include("mobile-verification") }
        it { is_expected.to include("mobile-number") }
      end

      context "when mobile_verified is false" do
        before do
          journey_session.answers.assign_attributes(
            provide_mobile_number: true,
            mobile_verified: false
          )

          journey_session.save!
        end

        it { is_expected.to include("mobile-verification") }
        it { is_expected.to include("mobile-number") }
      end
    end
  end
end
