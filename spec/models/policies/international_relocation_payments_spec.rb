require "rails_helper"

RSpec.describe Policies::InternationalRelocationPayments do
  describe "#payroll_file_name" do
    it "returns correct name" do
      expect(subject.payroll_file_name).to eql("IRP")
    end
  end
end
