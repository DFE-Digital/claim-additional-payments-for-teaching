require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::FurtherEducationProvisionSearchForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }
  let(:college) { create(:school) }

  let(:provision_search) { nil }
  let(:possible_school_id) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        provision_search:,
        possible_school_id:
      }
    )
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "validations" do
    context "when search query is blank" do
      let(:provision_search) { "" }

      it do
        is_expected.not_to(
          allow_value(provision_search)
          .for(:provision_search)
          .with_message("Enter the name of the FE provider you are employed by")
        )
      end
    end

    context "when search query is under 3 characters long" do
      let(:provision_search) { "ab" }

      it do
        is_expected.not_to(
          allow_value(provision_search)
          .for(:provision_search)
          .with_message("Enter a college name or postcode that is at least 3 characters long")
        )
      end
    end
  end

  describe "#save" do
    context "when provision_search supplied" do
      let(:provision_search) { college.name }

      it "updates the journey session with provision search" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.provision_search }.to(provision_search)
        )
      end
    end

    context "when possible_school_id supplied" do
      let(:possible_school_id) { college.id }

      it "updates the journey session with school_id" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.possible_school_id }.to(possible_school_id)
        )
      end
    end
  end

  describe "#clear_answers_from_session" do
    let(:answers_hash) do
      {
        possible_school_id: college.id,
        provision_search: college.name
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.possible_school_id }.from(college.id).to(nil)
        .and change { journey_session.reload.answers.provision_search }.from(college.name).to(nil)
    end
  end
end
