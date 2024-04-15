require "rails_helper"

class TestSlugForm < Form
  attribute :first_name
end

module Journeys
  module TestJourney
    extend Journeys::Base
    extend self

    VIEW_PATH = "test_view_path"
    I18N_NAMESPACE = "test_i18n_ns"

    class SlugSequence
      def initialize(claim)
        # NOOP
      end
    end
  end
end

RSpec.describe Form, type: :model do
  describe ".model_name" do
    it { expect(TestSlugForm.model_name).to eq(Claim.model_name) }
  end

  subject(:form) { TestSlugForm.new(claim:, journey:, params:) }

  let(:claim) { CurrentClaim.new(claims: [build(:claim, policy: Policies::StudentLoans)]) }
  let(:journey) { Journeys::TestJourney }
  let(:params) { ActionController::Parameters.new({journey: "test-journey", slug: "test_slug", claim: claim_params}) }
  let(:claim_params) { {first_name: "test-name"} }

  describe "#initialize" do
    # TODO
  end

  describe "#persisted?" do
    before do
      allow(claim).to receive(:persisted?)
      form.persisted?
    end

    it { expect(claim).to have_received(:persisted?) }
  end

  describe "#update!" do
    context "when successful" do
      it "updates the claim" do
        expect { form.update!(first_name: "test-name") }
          .to change { claim.first_name }.to("test-name")
      end
    end

    context "when an error occurrs" do
      before do
        allow(claim).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "does not update the claim" do
        expect { form.update!(first_name: "test-name") }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#view_path" do
    it { expect(form.view_path).to eq("test_view_path") }
  end

  describe "#i18n_namespace" do
    it { expect(form.i18n_namespace).to eq("test_i18n_ns") }
  end

  describe "#backlink_path" do
    before do
      allow_any_instance_of(Journeys::PageSequence).to receive(:previous_slug)
        .and_return(previous_slug)
    end

    describe "when the previous slug is present" do
      let(:previous_slug) { "previous-slug" }

      it { expect(form.backlink_path).to eq("/test-journey/previous-slug") }
    end

    describe "when the previous slug is not present" do
      let(:previous_slug) { nil }

      it { expect(form.backlink_path).to be_nil }
    end
  end

  describe "#i18n_errors_path" do
    before do
      allow(I18n).to receive(:t)
      form.i18n_errors_path("message")
    end

    it { expect(I18n).to have_received(:t).with("test_i18n_ns.forms.test_slug.errors.message") }
  end

  describe "#permitted_params" do
    let(:claim_params) { {first_name: "test-value"} }

    context "with params containing attributes defined on the form" do
      it "permits the attributes in the params" do
        expect(form.permitted_params).to eq(claim_params.stringify_keys)
      end
    end

    context "with params containing attributes not defined on the form" do
      let(:claim_params) { super().merge(unpermitted_attribute: "test-value") }

      it "raises an error" do
        expect { form.permitted_params }.to raise_error(ActionController::UnpermittedParameters)
      end
    end
  end
end
