require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::FurtherEducationProvisionSearchForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:college) { create(:school) }

  let(:provision_search) { nil }
  let(:school_id) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        provision_search:,
        school_id:
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
          .with_message("Enter a college name or postcode")
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

    context "when school_id supplied" do
      let(:school_id) { college.id }

      it "updates the journey session with school_id" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.school_id }.to(school_id)
        )
      end
    end
  end
end
