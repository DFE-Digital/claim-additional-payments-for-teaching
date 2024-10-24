require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments do
  describe "#payroll_file_name" do
    it "returns correct name" do
      expect(subject.payroll_file_name).to eql("FELUPEXPANSION")
    end
  end
end
