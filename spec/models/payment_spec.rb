require "rails_helper"

RSpec.describe Payment do
  subject { build(:payment) }

  describe ".non_topup_claims" do
    it "returns claims that are not associated with topups" do
      create(:journey_configuration, :targeted_retention_incentive_payments)
      create(:targeted_retention_incentive_payments_award, award_amount: 9999)

      claim = create(:claim, :approved)

      personal_details = Payment::PERSONAL_CLAIM_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES.map do |attr|
        [attr, claim.send(attr)]
      end.to_h

      topup_claim = create(:claim, :current_academic_year, **personal_details)
      topup = create(:topup, claim: topup_claim)

      payment = create(:payment, claims: [claim, topup_claim], topups: [topup])

      expect(payment.reload.non_topup_claims).to eq([claim])
    end
  end

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
          gross_pay: 10,
          scheduled_payment_date: Date.today)
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
          gross_pay: 10,
          scheduled_payment_date: Date.today)
      end

      it "is valid" do
        expect(subject).to be_valid(:upload)
      end
    end

    context "with all required fields present and valid, with nil scheduled_payment_date" do
      subject do
        build(:payment,
          payroll_reference: "DFE123",
          gross_value: 10.25,
          national_insurance: 15,
          employers_national_insurance: 10,
          student_loan_repayment: nil,
          tax: 10,
          net_pay: 10,
          gross_pay: 10,
          scheduled_payment_date: nil)
      end

      it "is invalid" do
        expect(subject).not_to be_valid(:upload)
      end
    end
  end

  context "when the payment is for more than one claim" do
    subject { build(:payment, claims: claims) }
    let(:claims) do
      build_list(:claim, 2, :approved,
        national_insurance_number: "JM603818B",
        eligibility_attributes: {teacher_reference_number: "1234567"},
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

    it "is valid when claims have different type of blank values for the same field" do
      claims[0].building_society_roll_number = ""
      claims[1].building_society_roll_number = nil

      expect(subject).to be_valid
    end

    it "is invalid when claims' dates of birth do not match" do
      claims[0].date_of_birth = 20.years.ago.to_date

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for date of birth"])
    end

    it "is invalid when claims' bank account numbers do not match" do
      claims[0].bank_account_number = "34192192"

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for bank account number"])
    end

    it "is invalid when claims' bank sort codes do not match" do
      claims[0].bank_sort_code = "024828"

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for bank sort code"])
    end

    it "is invalid when claims' building society roll numbers do not match" do
      claims[0].building_society_roll_number = "123456789/ABCD"

      expect(subject).not_to be_valid
      expect(subject.errors[:claims]).to eq(["#{claims[0].reference} and #{claims[1].reference} have different values for building society roll number"])
    end

    it "is invalid when claims' student loan plans do not match" do
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

    it "remains valid when claims' names do not match" do
      claims[0].first_name = "David"
      claims[0].middle_name = "Michael"
      claims[0].surname = "Rollins"
      claims[0].banking_name = "MR DM ROLLINS"

      expect(subject).to be_valid
    end

    it "remains valid when claims' payroll gender do not match" do
      claims[0].payroll_gender = :male

      expect(subject).to be_valid
    end

    it "remains valid when claims' addresses do not match" do
      claims[0].address_line_1 = "129 Brookland Drive"

      expect(subject).to be_valid
    end

    it "is valid when claims' National Insurance numbers do not match" do
      claims[0].national_insurance_number = "JM102019D"

      expect(subject).not_to be_valid
    end
  end

  describe "personal details" do
    subject(:payment) { create(:payment, claims: claims) }
    let(:claims) do
      personal_details = {
        national_insurance_number: "JM603818B",
        eligibility_attributes: {teacher_reference_number: "1234567"},
        bank_sort_code: "112233",
        bank_account_number: "95928482",
        building_society_roll_number: nil
      }
      [
        build(:claim, :approved, personal_details.merge(first_name: "Margaret", address_line_1: "17 Green Road", payroll_gender: :female, submitted_at: 5.days.ago)),
        build(:claim, :approved, personal_details.merge(first_name: "John", address_line_1: "64 West Lane", payroll_gender: :male, submitted_at: 10.days.ago))
      ]
    end

    it "is taken from the payment's most recently submitted claim" do
      expect(payment.first_name).to eq("Margaret")
      expect(payment.address_line_1).to eq("17 Green Road")
      expect(payment.payroll_gender).to eq("female")
    end
  end

  describe "policies in payment" do
    let(:personal_details) do
      {
        national_insurance_number: generate(:national_insurance_number),
        eligibility_attributes: {teacher_reference_number: generate(:teacher_reference_number)},
        email_address: generate(:email_address),
        bank_sort_code: "112233",
        bank_account_number: "95928482",
        address_line_1: "64 West Lane",
        student_loan_plan: StudentLoan::PLAN_1
      }
    end

    it "returns the correct string for a payment with one claim" do
      payment = create(:payment, claims: [
        create(:claim, :approved, personal_details.merge(policy: Policies::StudentLoans))
      ])

      expect(payment.policies_in_payment).to eq("TSLR")
    end

    it "returns the correct string for a payment with multiple claims under one policy" do
      payment = create(:payment, claims: [
        create(:claim, :approved, personal_details.merge(policy: Policies::StudentLoans)),
        create(:claim, :approved, personal_details.merge(policy: Policies::StudentLoans))
      ])

      expect(payment.policies_in_payment).to eq("TSLR")
    end

    it "returns the correct string for a payment with multiple claims under different policies" do
      payment = create(:payment, claims: [
        create(:claim, :approved, personal_details.merge(policy: Policies::StudentLoans)),
        create(:claim, :approved, personal_details.merge(policy: Policies::EarlyCareerPayments))
      ])

      expect(payment.policies_in_payment).to eq("EarlyCareerPayments TSLR")
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:claim_payments).dependent(:destroy) }
    it { is_expected.to have_many(:claims).through(:claim_payments) }
    it { is_expected.to have_many(:topups).dependent(:nullify) }
    it { is_expected.to belong_to(:payroll_run) }
    it { is_expected.to belong_to(:confirmation).class_name("PaymentConfirmation").optional(true) }
  end

  describe "scopes" do
    describe ".ordered" do
      it "runs a query with ORDER BY id ASC" do
        expect(described_class.ordered.to_sql)
          .to eq described_class.all.order(id: :asc).to_sql
      end
    end

    describe ".unconfirmed" do
      it "runs a query with WHERE confirmation_id IS NULL" do
        expect(described_class.unconfirmed.to_sql)
          .to eq described_class.all.where(confirmation_id: nil).to_sql
      end
    end
  end

  describe "method delegations" do
    described_class::PERSONAL_CLAIM_DETAILS_ATTRIBUTES_PERMITTING_DISCREPANCIES.each do |method|
      it { is_expected.to delegate_method(method).to(:claim_for_personal_details) }
    end

    described_class::PERSONAL_CLAIM_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES.each do |method|
      it { is_expected.to delegate_method(method).to(:claim_for_personal_details) }
    end
  end

  describe "#confirmed?" do
    subject { payment.confirmed? }

    context "when confirmation is not present" do
      let(:payment) { create(:payment) }

      it { is_expected.to eq(false) }
    end

    context "when confirmation is present" do
      let(:payment) { create(:payment, :confirmed) }

      it { is_expected.to eq(true) }
    end
  end
end
