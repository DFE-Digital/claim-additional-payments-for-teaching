# frozen_string_literal: true

require "rails_helper"

RSpec.describe StudentLoans::PermittedParameters do
  let(:claim) { Claim.new }
  let(:permitted_parameters) { described_class.new(claim) }

  describe "#keys" do
    context "when no fields have come from verify" do
      it "returns all permitted parameters" do
        expect(permitted_parameters.keys).to eq(StudentLoans::PermittedParameters::PARAMETERS)
      end
    end

    context "when fields have come from verify" do
      before do
        claim.verified_fields = ["payroll_gender", "address_line_1"]
      end

      it "excludes the verified fields" do
        expect(permitted_parameters.keys).to eq(StudentLoans::PermittedParameters::PARAMETERS.dup - [:address_line_1, :payroll_gender])
      end
    end
  end
end
