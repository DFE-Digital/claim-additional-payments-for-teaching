require "rails_helper"

RSpec.describe Policies::InternationalRelocationPayments::PolicyEligibilityChecker do
  before do
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  let(:answers) do
    build(
      :get_a_teacher_relocation_payment_answers,
      attributes: attributes
    )
  end

  let(:checker) { described_class.new(answers: answers) }

  describe "#ineligible?" do
    subject { checker.ineligible? }

    context "when the previous IRP payment question is answered 'no'" do
      let(:attributes) do
        {
          previous_payment_received: false
        }
      end

      it { is_expected.to eq(true) }
    end

    context "when the application route is 'other'" do
      let(:attributes) do
        {
          application_route: "other"
        }
      end

      it { is_expected.to eq(true) }
    end

    context "when the application route is 'teacher'" do
      let(:attributes) do
        {
          application_route: "teacher"
        }
      end

      it { is_expected.to eq(false) }
    end

    context "when the application route is 'salaried_trainee'" do
      let(:attributes) do
        {
          application_route: "salaried_trainee"
        }
      end

      it { is_expected.to eq(true) }
    end

    context "with a non state funded secondary school" do
      let(:attributes) do
        {
          application_route: "teacher",
          state_funded_secondary_school: false
        }
      end

      it { is_expected.to eq(true) }
    end

    context "with a contract duration of less than one year" do
      let(:attributes) do
        {
          application_route: "teacher",
          state_funded_secondary_school: true,
          one_year: false
        }
      end

      it { is_expected.to eq(true) }
    end

    context "with a taught subject of 'other'" do
      let(:attributes) do
        {
          application_route: "teacher",
          state_funded_secondary_school: true,
          one_year: true,
          subject: "other"
        }
      end

      it { is_expected.to eq(true) }
    end

    context "with a visa type of 'Other'" do
      let(:attributes) do
        {
          application_route: "teacher",
          state_funded_secondary_school: true,
          one_year: true,
          subject: "physics",
          visa_type: "Other"
        }
      end

      it { is_expected.to eq(true) }
    end

    context "with a contract start date before the earliest eligible date" do
      let(:attributes) do
        {
          application_route: "teacher",
          state_funded_secondary_school: true,
          one_year: true,
          subject: "physics",
          visa_type: "British National (Overseas) visa",
          start_date: Policies::InternationalRelocationPayments::PolicyEligibilityChecker.earliest_eligible_contract_start_date - 1.day
        }
      end

      it { is_expected.to eq(true) }
    end

    context "with an entry date more than 3 months before the contract start date" do
      let(:attributes) do
        {
          application_route: "teacher",
          state_funded_secondary_school: true,
          one_year: true,
          subject: "physics",
          visa_type: "British National (Overseas) visa",
          start_date: Policies::InternationalRelocationPayments::PolicyEligibilityChecker.earliest_eligible_contract_start_date,
          date_of_entry: Policies::InternationalRelocationPayments::PolicyEligibilityChecker.earliest_eligible_contract_start_date - 4.months
        }
      end

      it { is_expected.to eq(false) }
    end

    context "with a non secondary school" do
      let(:attributes) do
        {
          application_route: "teacher",
          state_funded_secondary_school: true,
          one_year: true,
          subject: "physics",
          visa_type: "British National (Overseas) visa",
          start_date: Policies::InternationalRelocationPayments::PolicyEligibilityChecker.earliest_eligible_contract_start_date,
          date_of_entry: Policies::InternationalRelocationPayments::PolicyEligibilityChecker.earliest_eligible_contract_start_date - 1.week,
          current_school_id: create(:school, school_type_group: "la_maintained", phase: :primary).id
        }
      end

      it { is_expected.to eq(true) }
    end

    context "with a non state funded secondary school" do
      let(:attributes) do
        {
          application_route: "teacher",
          state_funded_secondary_school: true,
          one_year: true,
          subject: "physics",
          visa_type: "British National (Overseas) visa",
          start_date: Policies::InternationalRelocationPayments::PolicyEligibilityChecker.earliest_eligible_contract_start_date,
          date_of_entry: Policies::InternationalRelocationPayments::PolicyEligibilityChecker.earliest_eligible_contract_start_date - 1.week,
          current_school_id: create(:school, school_type_group: "independent_schools", phase: :secondary).id
        }
      end

      it { is_expected.to eq(true) }
    end

    context "with an eligible application" do
      let(:attributes) do
        {
          application_route: "teacher",
          state_funded_secondary_school: true,
          one_year: true,
          subject: "physics",
          visa_type: "British National (Overseas) visa",
          start_date: Policies::InternationalRelocationPayments::PolicyEligibilityChecker.earliest_eligible_contract_start_date,
          date_of_entry: Policies::InternationalRelocationPayments::PolicyEligibilityChecker.earliest_eligible_contract_start_date - 1.week,
          current_school_id: create(:school, school_type_group: "la_maintained", phase: :secondary).id
        }
      end

      it { is_expected.to eq(false) }
    end
  end
end
