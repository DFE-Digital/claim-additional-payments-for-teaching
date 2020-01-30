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
          net_pay: 10,
          gross_pay: 10)
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
          net_pay: 10,
          gross_pay: 10)
      end

      it "is valid" do
        expect(subject).to be_valid(:upload)
      end
    end
  end

  context "when the payment is for more than one claim" do
    subject { build(:payment, claims: claims) }
    let(:claims) do
      build_list(:claim, 2, :approved,
        national_insurance_number: "JM603818B",
        teacher_reference_number: "1234567",
        email_address: "email@example.com",
        bank_sort_code: "112233",
        bank_account_number: "95928482",
        building_society_roll_number: nil,
        address_line_1: "64 West Lane",
        student_loan_plan: StudentLoan::PLAN_1,
        date_of_birth: 30.years.ago.to_date,
        first_name: "Jennifer",
        middle_name: "Poppy",
        surname: "Blake",
        payroll_gender: :female)
    end

    it "is valid when all claims have matching personal details" do
      expect(subject).to be_valid
    end

    it "is invalid when claims’ teacher reference numbers do not match" do
      claims[0].teacher_reference_number = "9988776"

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for teacher reference number"])
    end

    it "is invalid when claims’ dates of birth do not match" do
      claims[0].date_of_birth = 20.years.ago.to_date

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for date of birth"])
    end

    it "is invalid when claims’ bank account numbers do not match" do
      claims[0].bank_account_number = "34192192"

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for bank account number"])
    end

    it "is invalid when claims’ bank sort codes do not match" do
      claims[0].bank_sort_code = "024828"

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for bank sort code"])
    end

    it "is invalid when claims’ building society roll numbers do not match" do
      claims[0].building_society_roll_number = "123456789/ABCD"

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for building society roll number"])
    end

    it "is invalid when claims’ student loan plans do not match" do
      claims[0].student_loan_plan = StudentLoan::PLAN_2

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for student loan plan"])
    end

    it "is invalid when its claims have multiple forbidden discrepancies in personal details" do
      claims[0].bank_account_number = "34192192"
      claims[0].bank_sort_code = "013028"

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for bank sort code and bank account number"])
    end

    it "remains valid when claims’ names do not match" do
      claims[0].first_name = "David"
      claims[0].middle_name = "Michael"
      claims[0].surname = "Rollins"
      claims[0].banking_name = "MR DM ROLLINS"

      expect(subject).to be_valid
    end

    it "remains valid when claims’ payroll gender do not match" do
      claims[0].payroll_gender = :male

      expect(subject).to be_valid
    end

    it "remains valid when claims’ addresses do not match" do
      claims[0].address_line_1 = "129 Brookland Drive"

      expect(subject).to be_valid
    end

    it "is valid when claims’ National Insurance numbers do not match" do
      claims[0].national_insurance_number = "JM102019D"

      expect(subject).to be_valid
    end
  end

  describe "personal details" do
    subject(:payment) { create(:payment, claims: claims) }
    let(:claims) do
      personal_details = {
        national_insurance_number: "JM603818B",
        teacher_reference_number: "1234567",
        bank_sort_code: "112233",
        bank_account_number: "95928482",
        building_society_roll_number: nil,
      }
      [
        build(:claim, :approved, personal_details.merge(first_name: "Margaret", address_line_1: "17 Green Road", payroll_gender: :female, submitted_at: 5.days.ago)),
        build(:claim, :approved, personal_details.merge(first_name: "John", address_line_1: "64 West Lane", payroll_gender: :male, submitted_at: 10.days.ago)),
      ]
    end

    it "is taken from the payment’s most recently submitted claim" do
      expect(payment.first_name).to eq("Margaret")
      expect(payment.address_line_1).to eq("17 Green Road")
      expect(payment.payroll_gender).to eq("female")
    end
  end
end
