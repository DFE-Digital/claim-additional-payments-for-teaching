require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments do
  describe ".duplicate_claim?" do
    subject { described_class.duplicate_claim?(candidate_claim) }

    let(:existing_claim) do
      create(
        :claim,
        policy: Policies::FurtherEducationPayments,
        eligibility: eligibility_1,
        first_name: "Edna",
        surname: "Krabappel",
        email_address: "edna.krabappel@springfield-elementary.edu"
      )
    end

    let(:eligibility_1) do
      create(
        :further_education_payments_eligibility,
        school: create(:school)
      )
    end

    let(:eligibility_2) do
      create(
        :further_education_payments_eligibility,
        school: school
      )
    end

    let(:candidate_claim) do
      create(
        :claim,
        policy: Policies::FurtherEducationPayments,
        eligibility: eligibility_2,
        first_name: first_name,
        surname: surname,
        email_address: email_address
      )
    end

    context "when the schools are different" do
      let(:first_name) { existing_claim.first_name }
      let(:surname) { existing_claim.surname }
      let(:email_address) { existing_claim.email_address }
      let(:school) { create(:school) }

      it { is_expected.to be false }
    end

    context "when the first names are different" do
      let(:first_name) { existing_claim.first_name + "different" }
      let(:surname) { existing_claim.surname }
      let(:email_address) { existing_claim.email_address }
      let(:school) { existing_claim.eligibility.school }

      it { is_expected.to be false }
    end

    context "when the last names are different" do
      let(:first_name) { existing_claim.first_name }
      let(:surname) { existing_claim.surname + "different" }
      let(:email_address) { existing_claim.email_address }
      let(:school) { existing_claim.eligibility.school }

      it { is_expected.to be false }
    end

    context "when the email_address addresses are different" do
      let(:first_name) { existing_claim.first_name }
      let(:surname) { existing_claim.surname }
      let(:email_address) { "different" + existing_claim.email_address }
      let(:school) { existing_claim.eligibility.school }

      it { is_expected.to be false }
    end

    context "when the details match" do
      let(:first_name) { existing_claim.first_name }
      let(:surname) { existing_claim.surname }
      let(:email_address) { existing_claim.email_address }
      let(:school) { existing_claim.eligibility.school }

      it { is_expected.to be true }
    end
  end
end
