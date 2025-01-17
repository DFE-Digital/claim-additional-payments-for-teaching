require "rails_helper"

class TestSlugForm < Form
  attribute :first_name
  attribute :student_loan_repayment_amount
end

module Journeys
  module TestJourney
    extend Journeys::Base
    extend self

    VIEW_PATH = "test_view_path"
    I18N_NAMESPACE = "test_i18n_ns"

    class SlugSequence
      def initialize(journey_session)
        # NOOP
      end
    end
  end
end

RSpec.describe Form, type: :model do
  describe ".model_name" do
    it { expect(TestSlugForm.model_name).to eq(Claim.model_name) }
  end

  describe ".i18n_error_message" do
    let(:form_double) { instance_double(TestSlugForm) }

    it "returns a lambda function for generating error messages" do
      path = :test_error_path
      error_message_lambda = described_class.i18n_error_message(path)

      allow(form_double).to receive(:i18n_errors_path).with(path, {}).and_return("Test error message")

      result = error_message_lambda.call(form_double, nil)
      expect(result).to eq("Test error message")
    end
  end

  subject(:form) { TestSlugForm.new(journey:, journey_session:, params:) }

  let(:journey) { Journeys::TestJourney }
  let(:journey_session) { build(:student_loans_session) }
  let(:params) { ActionController::Parameters.new({journey: "test-journey", slug: "test_slug", claim: claim_params}) }
  let(:claim_params) { {first_name: "test-name"} }

  describe "#initialize" do
    context "with valid params" do
      let(:claim_params) { {first_name: "my-name"} }

      it "initialises the attributes with values from the params" do
        expect(form).to have_attributes(first_name: "my-name")
      end
    end

    context "with no params" do
      let(:claim_params) { {} }

      context "when an existing value can be found on the journey session" do
        let(:journey_session) do
          build(
            :student_loans_session,
            answers: {
              first_name: "existing-name",
              student_loan_repayment_amount: 2000
            }
          )
        end

        it "initialises the attributes with values from the journey session" do
          expect(form).to have_attributes(
            first_name: "existing-name",
            student_loan_repayment_amount: 2000
          )
        end
      end

      context "when an existing `nil` value can be found on the journey session" do
        let(:claims) do
          [
            build(
              :claim,
              first_name: "existing-name",
              eligibility_attributes: {
                student_loan_repayment_amount: 100
              },
              policy: Policies::StudentLoans
            )
          ]
        end

        let(:journey_session) do
          build(
            :student_loans_session,
            answers: {
              first_name: "existing-name",
              student_loan_repayment_amount: nil
            }
          )
        end

        it "initialises the attributes with values from the journey session" do
          expect(form).to have_attributes(
            first_name: "existing-name",
            student_loan_repayment_amount: nil
          )
        end
      end

      context "when an existing value cannot be found on journey session" do
        let(:claims) { [build(:claim, first_name: nil, policy: Policies::StudentLoans)] }

        it "initialises the attributes with nil" do
          expect(form).to have_attributes(first_name: nil, student_loan_repayment_amount: nil)
        end
      end
    end
  end

  describe "#persisted?" do
    it { expect(form.persisted?).to eq(true) }
  end

  describe "#view_path" do
    it { expect(form.view_path).to eq("test_view_path") }
  end

  describe "#i18n_namespace" do
    it { expect(form.i18n_namespace).to eq("test_i18n_ns") }
  end

  describe "#i18n_errors_path" do
    before do
      allow(I18n).to receive(:t)
      form.i18n_errors_path("message")
    end

    it do
      expect(I18n).to have_received(:t)
        .with("test_i18n_ns.forms.test_slug.errors.message", default: :"forms.test_slug.errors.message")
    end

    context "when more arguments are supplied" do
      before do
        form.i18n_errors_path("message", school_name: "Academy for Lizards")
      end

      it do
        expect(I18n).to have_received(:t)
          .with("test_i18n_ns.forms.test_slug.errors.message", default: :"forms.test_slug.errors.message", school_name: "Academy for Lizards")
      end
    end
  end

  describe "#t" do
    let(:form) { TestSlugForm.new(journey:, journey_session:, params:) }
    let(:args) { {} }
    let(:key) { "some_key" }

    before do
      allow(I18n).to receive(:t)
      form.t(key, args)
    end

    context "no args" do
      it do
        expect(I18n).to have_received(:t).with("test_i18n_ns.forms.test_slug.some_key", {default: :"forms.test_slug.some_key"})
      end
    end

    context "override i18n_form_namespace" do
      let(:args) { {i18n_form_namespace: "overriden_ns"} }

      it do
        expect(I18n).to have_received(:t).with("test_i18n_ns.forms.overriden_ns.some_key", {default: :"forms.overriden_ns.some_key"})
      end
    end
  end

  describe "#t - actually use something from en.yml" do
    let(:params) { ActionController::Parameters.new({}) }

    subject(:form) { GenderForm.new(journey:, journey_session:, params:) }

    context "FE journey overrides gender form in en.yml" do
      let(:journey) { Journeys::FurtherEducationPayments }

      it "calls the i18n namespaced version" do
        expect(form.t("questions.payroll_gender")).to eq("How is your gender recorded on your employer’s payroll system?")
      end
    end

    context "TSLR journey uses the base gender form in en.yml" do
      let(:journey) { Journeys::TeacherStudentLoanReimbursement }

      it "calls the base version" do
        expect(form.t("questions.payroll_gender")).to eq("How is your gender recorded on your school’s payroll system?")
      end
    end
  end

  describe "#permitted_params" do
    let(:claim_params) { {first_name: "test-value"} }

    context "with params containing attributes defined on the form" do
      it "permits the attributes in the params" do
        expect(form.permitted_params).to eql(ActionController::Parameters.new(claim_params.stringify_keys).permit!)
      end
    end
  end
end
