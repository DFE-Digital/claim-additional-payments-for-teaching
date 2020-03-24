require "rails_helper"

RSpec.describe Amendment, type: :model do
  it "is invalid if there are no claim changes" do
    amendment = build(:amendment, claim_changes: {})
    expect(amendment).not_to be_valid

    amendment.claim_changes = {"teacher_reference_number" => ["7654321", "1234567"]}
    expect(amendment).to be_valid
  end

  it "is invalid if the notes are empty" do
    amendment = build(:amendment, notes: "")
    expect(amendment).not_to be_valid

    amendment.notes = "Claimant made a typo"
    expect(amendment).to be_valid
  end

  it "is invalid if its claim is not amendable" do
    amendment = build(:amendment, claim: create(:claim, :rejected))
    expect(amendment).not_to be_valid

    amendment.claim = build(:claim, :approved)
    expect(amendment).to be_valid
  end

  describe ".amend_claim" do
    let(:claim) { create(:claim, :submitted, teacher_reference_number: "1234567", bank_sort_code: "111213", bank_account_number: "12345678", building_society_roll_number: nil, policy: MathsAndPhysics) }
    let(:dfe_signin_user) { create(:dfe_signin_user) }

    context "given valid claim attributes and valid amendment attributes" do
      let(:claim_attributes) do
        {
          teacher_reference_number: "7654321",
          bank_account_number: "87654321"
        }
      end
      let(:amendment_attributes) do
        {
          notes: "This is a change",
          created_by: dfe_signin_user
        }
      end

      it "updates and saves the claim, and returns a persisted amendment describing the changes to the claim" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment).to be_persisted
        expect(amendment.claim_changes).to be_an_instance_of(Hash)
        expect(amendment.claim_changes).to eq("teacher_reference_number" => ["1234567", "7654321"], "bank_account_number" => ["12345678", "87654321"])
        expect(amendment.notes).to eq("This is a change")
        expect(amendment.created_by).to eq(dfe_signin_user)

        expect(claim.reload.amendments).to eq([amendment])
        expect(claim.teacher_reference_number).to eq("7654321")
        expect(claim.bank_account_number).to eq("87654321")
      end
    end

    context "given valid claim attributes and missing amendment notes" do
      let(:claim_attributes) do
        {
          teacher_reference_number: "7654321",
          bank_account_number: "87654321"
        }
      end
      let(:amendment_attributes) do
        {
          created_by: dfe_signin_user
        }
      end

      it "assigns the new values to the claim but does not persist them, and returns a non-persisted amendment which has errors and which describes the changes to the claim" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment).to_not be_persisted
        expect(amendment.claim_changes).to be_an_instance_of(Hash)
        expect(amendment.claim_changes).to eq("teacher_reference_number" => ["1234567", "7654321"], "bank_account_number" => ["12345678", "87654321"])
        expect(amendment.created_by).to eq(dfe_signin_user)

        expect(claim.teacher_reference_number).to eq("7654321")
        expect(claim.bank_account_number).to eq("87654321")

        expect(claim.reload.amendments).to be_empty
        expect(claim.teacher_reference_number).to eq("1234567")
        expect(claim.bank_account_number).to eq("12345678")

        expect(amendment.errors.keys).to eq([:notes])
      end
    end

    context "given invalid claim attributes and valid amendment attributes" do
      let(:claim_attributes) do
        {
          teacher_reference_number: "765432",
          bank_account_number: "87654321"
        }
      end
      let(:amendment_attributes) do
        {
          notes: "This is a change",
          created_by: dfe_signin_user
        }
      end

      it "assigns the new values to the claim but does not persist them, and returns a non-persisted amendment, with the errors from the claim copied to the amendment’s errors" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment).to_not be_persisted
        expect(amendment.created_by).to eq(dfe_signin_user)

        expect(claim.teacher_reference_number).to eq("765432")
        expect(claim.bank_account_number).to eq("87654321")

        expect(claim.reload.amendments).to be_empty
        expect(claim.teacher_reference_number).to eq("1234567")
        expect(claim.bank_account_number).to eq("12345678")

        expect(amendment.errors.keys).to match_array([:teacher_reference_number])
      end
    end

    context "given invalid claim attributes and missing amendment notes" do
      let(:claim_attributes) do
        {
          teacher_reference_number: "765432",
          bank_account_number: "87654321"
        }
      end
      let(:amendment_attributes) do
        {
          created_by: dfe_signin_user
        }
      end

      it "assigns the new values to the claim but does not persist them, and returns a non-persisted amendment which has errors, with the errors from the claim copied to the amendment’s errors" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment).to_not be_persisted
        expect(amendment.created_by).to eq(dfe_signin_user)

        expect(claim.teacher_reference_number).to eq("765432")
        expect(claim.bank_account_number).to eq("87654321")

        expect(claim.reload.amendments).to be_empty
        expect(claim.teacher_reference_number).to eq("1234567")
        expect(claim.bank_account_number).to eq("12345678")

        expect(amendment.errors.keys).to match_array([:notes, :teacher_reference_number])
      end
    end

    context "given claim attributes which are all the same as the current values" do
      let(:claim_attributes) do
        {
          teacher_reference_number: claim.teacher_reference_number
        }
      end
      let(:amendment_attributes) do
        {
          notes: "This is a change",
          created_by: dfe_signin_user
        }
      end

      it "returns a non-persisted amendment which has errors on claim_changes" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment).to_not be_persisted
        expect(claim.reload.amendments).to be_empty

        expect(amendment.errors.keys).to eq([:claim_changes])
      end
    end

    context "when updating an attribute that gets normalised in a before_save hook" do
      let(:claim_attributes) do
        {
          bank_sort_code: "01-02-03"
        }
      end
      let(:amendment_attributes) do
        {
          notes: "This is a change",
          created_by: dfe_signin_user
        }
      end

      it "stores the normalised value in the amendment’s claim_changes" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment.claim_changes).to eq("bank_sort_code" => ["111213", "010203"])
      end
    end

    context "when amending the claim’s eligibility attributes" do
      let(:claim) do
        create(:claim, :submitted, eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 1000))
      end

      let(:claim_attributes) do
        {
          eligibility_attributes: {
            student_loan_repayment_amount: 555
          }
        }
      end
      let(:amendment_attributes) do
        {
          notes: "This is a change",
          created_by: dfe_signin_user
        }
      end

      it "stores the value in the amendment’s claim_changes" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment.claim_changes).to eq("student_loan_repayment_amount" => [1000, 555])
      end
    end

    context "when updating a value from nil to an empty string" do
      let(:claim_attributes) do
        {
          teacher_reference_number: "7654321",
          building_society_roll_number: ""
        }
      end
      let(:amendment_attributes) do
        {
          notes: "This is a change",
          created_by: dfe_signin_user
        }
      end

      it "does not mark the value as changed in the amendment’s claim_changes" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment.claim_changes).to eq("teacher_reference_number" => ["1234567", "7654321"])
      end
    end
  end
end
