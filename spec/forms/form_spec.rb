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
  end
end

module Journeys
  module TestJourney
    class SlugSequence
      def initialize(claim)
        # NOOP
      end

      def slugs
        []
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
  let(:params) { ActionController::Parameters.new({slug: "test_slug", claim: {first_name: "test-name"}}) }

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
    context "when the subclass does not define it" do
      it { expect(form.backlink_path).to be_nil }
    end

    context "when the subclass defines it" do
      before do
        form.instance_eval do
          def backlink_path
            "/custom-path"
          end
        end
      end

      it { expect(form.backlink_path).to eq("/custom-path") }
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
    it { expect(form.permitted_params.to_h).to eq("first_name" => "test-name") }
  end

  describe "force_update_session_with_current_slug" do
    it { expect(form.force_update_session_with_current_slug).to be false }
  end

  describe "redirect_to_next_slug" do
    context "@redirect_to_next_slug is nil or not set" do
      it { expect(form.redirect_to_next_slug).to be false }
    end

    context "@redirect_to_next_slug false" do
      before { form.instance_variable_set(:@redirect_to_next_slug, false) }

      it { expect(form.redirect_to_next_slug).to be false }
    end

    context "@redirect_to_next_slug true" do
      before { form.instance_variable_set(:@redirect_to_next_slug, true) }

      it { expect(form.redirect_to_next_slug).to be true }
    end
  end
end
