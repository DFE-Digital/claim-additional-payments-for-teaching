require "rails_helper"

RSpec.describe Payment do
  subject { build(:payment) }

  context "when validating in the :upload context" do
    it "is invalid" do
      expect(subject).not_to be_valid(:upload)
    end

    context "with all fields present and valid" do
      subject do
        build(:payment,
          payroll_reference: "DFE123",
          gross_value: 10.25,
          national_insurance: 15,
          employers_national_insurance: 10,
          student_loan_repayment: 10,
          tax: 10,
          net_pay: 10)
      end

      it "is valid" do
        expect(subject).to be_valid(:upload)
      end
    end

    context "with all required fields present and valid, with nil student_loan_repayment" do
      subject do
        build(:payment,
          payroll_reference: "DFE123",
          gross_value: 10.25,
          national_insurance: 15,
          employers_national_insurance: 10,
          student_loan_repayment: nil,
          tax: 10,
          net_pay: 10)
      end

      it "is valid" do
        expect(subject).to be_valid(:upload)
      end
    end
  end
end
