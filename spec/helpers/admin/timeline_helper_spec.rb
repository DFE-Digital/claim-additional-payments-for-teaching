require "rails_helper"

describe Admin::TimelineHelper do
  describe "#admin_amendment_details" do
    let(:amendment) {
      build(:amendment, :personal_data_removed, claim_changes: {
        "teacher_reference_number" => [generate(:teacher_reference_number).to_s, generate(:teacher_reference_number).to_s],
        "bank_account_number" => ["12345678", "87654321"],
        "bank_sort_code" => ["123456", "654321"],
        "payroll_gender" => ["male", "dont_know"],
        "date_of_birth" => [Date.new(1995, 2, 25), Date.new(1990, 2, 25)],
        "student_loan_plan" => ["not_applicable", "plan_1"],
        "student_loan_repayment_amount" => [123, 456]
      })
    }

    it "returns an array of arrays, each of which contains formatted attribute name and old and new values" do
      expect(helper.admin_amendment_details(amendment)).to eq([
        ["Bank account number", "12345678", "87654321"],
        ["Bank sort code", "123456", "654321"],
        ["Date of birth", "25/02/1995", "25/02/1990"],
        ["Payroll gender", "male", "don’t know"],
        ["Student loan repayment amount", "£123.00", "£456.00"],
        ["Student loan repayment plan", "not applicable", "Plan 1"],
        ["Teacher reference number", "1000000", "1000001"]
      ])
    end

    context "with an amendment with its personal data removed" do
      let(:amendment) {
        build(:amendment, :personal_data_removed, claim_changes: {
          "teacher_reference_number" => [generate(:teacher_reference_number).to_s, generate(:teacher_reference_number).to_s],
          "bank_account_number" => nil
        })
      }

      it "doesn’t return old or new values for the removed attributes" do
        expect(helper.admin_amendment_details(amendment)).to eq([
          ["Bank account number"],
          ["Teacher reference number", amendment.claim_changes["teacher_reference_number"][0], amendment.claim_changes["teacher_reference_number"][1]]
        ])
      end
    end
  end
end
