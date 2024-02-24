require "rails_helper"

RSpec.describe Payroll::PaymentCsvRow do
  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :additional_payments)
  end

  subject { described_class.new(payment) }

  describe "#to_s" do
    let(:row) { CSV.parse(subject.to_s).first }
    let(:payment_award_amount) { BigDecimal("1234.56") }
    let(:payment) { create(:payment, award_amount: payment_award_amount, claims: claims) }

    let(:personal_details_for_student_loans_and_early_career_payments_claim) do
      {
        national_insurance_number: generate(:national_insurance_number),
        teacher_reference_number: generate(:teacher_reference_number),
        payroll_gender: :female,
        date_of_birth: Date.new(1980, 12, 1),
        student_loan_plan: StudentLoan::PLAN_2,
        bank_sort_code: "001122",
        bank_account_number: "01234567",
        banking_name: "Jo Bloggs",
        building_society_roll_number: "1234/12345678",
        email_address: "email@example.com"
      }.merge(manual_populated_address)
    end

    let(:manual_populated_address) do
      {
        address_line_1: "1 Test Road",
        address_line_2: "",
        address_line_3: "Leicester",
        address_line_4: "Leicestershire",
        postcode: "LE11 1AA"
      }
    end

    let(:claims) do
      [
        create(:claim, :approved, personal_details_for_student_loans_and_early_career_payments_claim.merge(policy: StudentLoans)),
        create(:claim, :approved, personal_details_for_student_loans_and_early_career_payments_claim.merge(policy: Policies::EarlyCareerPayments))
      ]
    end

    # DfE Payroll Address format is described here:
    # ADDR_LINE_1 - House Name (optional)
    # ADDR_LINE_2 - Number and Street Name *
    # ADDR_LINE_3 - Local Area (optional)
    # ADDR_LINE_4 - Town *
    # ADDR_LINE_5 - County *
    # ADDR_LINE_6 - Postcode *
    context "with a StudentLoans and EarlyCareerPayments claim" do
      context "with a four part address" do
        it "generates a csv row formatted to match DfE Payroll address" do
          travel_to Date.new(2019, 9, 26) do
            claim = claims.first

            expect(row).to eq([
              "Prof.",
              claim.first_name,
              claim.middle_name,
              claim.surname,
              claim.national_insurance_number,
              "F",
              "Other",
              "09/09/2019",
              "15/09/2019",
              claim.date_of_birth.strftime("%d/%m/%Y"),
              claim.email_address,
              claim.address_line_1,
              "",
              nil,
              claim.address_line_3,
              claim.address_line_4,
              claim.postcode,
              "United Kingdom",
              "BR",
              "0",
              "A",
              "T",
              "2",
              "Direct BACS",
              "Weekly",
              claim.banking_name,
              "00-11-22",
              claim.bank_account_number,
              claim.building_society_roll_number,
              payment_award_amount.to_s,
              payment.id,
              payment.policies_in_payment,
              "2"
            ])
          end
        end
      end
    end

    context "with a EarlyCareerPayments claim" do
      let(:payment) { create(:payment, award_amount: payment_award_amount, claims: claims) }

      context "with a six part address" do
        let(:personal_details_for_ecp_claim_1) do
          {
            national_insurance_number: generate(:national_insurance_number),
            teacher_reference_number: generate(:teacher_reference_number),
            payroll_gender: :male,
            date_of_birth: Date.new(1988, 3, 21),
            student_loan_plan: StudentLoan::PLAN_1_AND_3,
            bank_sort_code: "330990",
            bank_account_number: "80014109",
            banking_name: "Stephen Hawkes",
            email_address: "shawkes@example.com"
          }.merge(auto_populated_address_with_building_name_and_street)
        end
        let(:auto_populated_address_with_building_name_and_street) do
          {
            address_line_1: "Flat 13, Millbrook Tower",
            address_line_2: "Windermere Avenue",
            address_line_3: "Southampton",
            address_line_4: "Southampton",
            postcode: "SO16 9FX"
          }
        end
        let(:claims) do
          [
            create(:claim, :approved, personal_details_for_ecp_claim_1.merge(policy: Policies::EarlyCareerPayments))
          ]
        end

        it "generates a csv row formatted to match DfE Payroll address" do
          travel_to Date.new(2019, 9, 26) do
            claim = claims.first

            expect(row).to eq([
              "Prof.",
              claim.first_name,
              claim.middle_name,
              claim.surname,
              claim.national_insurance_number,
              "M",
              "Other",
              "09/09/2019",
              "15/09/2019",
              claim.date_of_birth.strftime("%d/%m/%Y"),
              claim.email_address,
              claim.address_line_1,
              claim.address_line_2,
              nil,
              claim.address_line_3,
              claim.address_line_4,
              claim.postcode,
              "United Kingdom",
              "BR",
              "0",
              "A",
              "T",
              "1 and 3",
              "Direct BACS",
              "Weekly",
              claim.banking_name,
              "33-09-90",
              claim.bank_account_number,
              nil,
              payment_award_amount.to_s,
              payment.id,
              payment.policies_in_payment,
              "2"
            ])
          end
        end
      end

      context "with a five part address" do
        let(:personal_details_for_ecp_claim_2) do
          {
            national_insurance_number: generate(:national_insurance_number),
            teacher_reference_number: generate(:teacher_reference_number),
            payroll_gender: :female,
            date_of_birth: Date.new(1994, 6, 30),
            student_loan_plan: StudentLoan::PLAN_1,
            bank_sort_code: "210909",
            bank_account_number: "13810025",
            banking_name: "Miss Jessica Xu",
            email_address: "j-xu@example.com"
          }.merge(auto_populated_address_with_house_number_and_street_name)
        end

        let(:auto_populated_address_with_house_number_and_street_name) do
          {
            address_line_1: "4",
            address_line_2: "Wearside Road",
            address_line_3: "London",
            address_line_4: "London",
            postcode: "SE13 7UN"
          }
        end
        let(:claims) do
          [
            create(:claim, :approved, personal_details_for_ecp_claim_2.merge(policy: Policies::EarlyCareerPayments))
          ]
        end

        it "generates a csv row formatted to match DfE Payroll address" do
          travel_to Date.new(2019, 9, 26) do
            claim = claims.first

            expect(row).to eq([
              "Prof.",
              claim.first_name,
              claim.middle_name,
              claim.surname,
              claim.national_insurance_number,
              "F",
              "Other",
              "09/09/2019",
              "15/09/2019",
              claim.date_of_birth.strftime("%d/%m/%Y"),
              claim.email_address,
              nil,
              "4, Wearside Road",
              nil,
              claim.address_line_3,
              claim.address_line_4,
              claim.postcode,
              "United Kingdom",
              "BR",
              "0",
              "A",
              "T",
              "1",
              "Direct BACS",
              "Weekly",
              claim.banking_name,
              "21-09-09",
              claim.bank_account_number,
              nil,
              payment_award_amount.to_s,
              payment.id,
              payment.policies_in_payment,
              "2"
            ])
          end
        end
      end
    end

    describe "start and end dates" do
      context "when the first of the month is a Friday" do
        it "returns the date of the second Monday and Sunday" do
          travel_to Date.parse "20 February 2019" do
            row = CSV.parse(subject.to_s).first
            expect(row[7]).to eq "11/02/2019"
            expect(row[8]).to eq "17/02/2019"
          end
        end
      end

      context "when the first of the month is a Sunday" do
        it "returns the date of the second Monday and Sunday" do
          travel_to Date.parse "9 July 2040" do
            row = CSV.parse(subject.to_s).first
            expect(row[7]).to eq "09/07/2040"
            expect(row[8]).to eq "15/07/2040"
          end
        end
      end

      context "when the first of the month is a Monday" do
        it "returns the date of the second Monday and Sunday" do
          travel_to Date.parse "1 June 2020" do
            row = CSV.parse(subject.to_s).first
            expect(row[7]).to eq "08/06/2020"
            expect(row[8]).to eq "14/06/2020"
          end
        end
      end
    end

    describe "PAYMENT_ID" do
      it "is 36 characters long, satisfying DfE Payroll’s length validation" do
        expect(row[30].length).to eq(36)
      end
    end

    it "escapes fields with strings that could be dangerous in Microsoft Excel and friends" do
      claims.each do |claim|
        claim.address_line_2 = "=ActiveCell.Row-1,14"
      end

      expect(row[Payroll::PaymentsCsv::FIELDS_WITH_HEADERS.find_index { |k, _| k == :address_line_2 }]).to eq("\\#{claims.first.address_line_2}")
    end
  end
end
