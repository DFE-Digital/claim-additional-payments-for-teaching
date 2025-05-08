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
    claim = create(:claim, :approved)
    create(:payment, claims: [claim])

    amendment = build(:amendment, claim: claim)
    expect(amendment).not_to be_valid

    amendment.claim = build(:claim, :approved)
    expect(amendment).to be_valid
  end

  describe ".amend_claim" do
    # Needs to reload as .amend_claim looks at the ActiveModel #previous_changes and the factory setup confuses it
    let(:claim) {
      create(:claim,
        :submitted,
        eligibility_attributes: {teacher_reference_number: "1234567"},
        bank_sort_code: "111213",
        bank_account_number: "12345678",
        building_society_roll_number: nil,
        policy: Policies::EarlyCareerPayments).reload
    }

    let(:dfe_signin_user) { create(:dfe_signin_user) }

    context "given valid claim attributes and valid amendment attributes" do
      let(:claim_attributes) do
        {
          eligibility_attributes: {teacher_reference_number: "7654321"},
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
        expect(claim.eligibility.teacher_reference_number).to eq("7654321")
        expect(claim.bank_account_number).to eq("87654321")
      end
    end

    context "given valid claim attributes and missing amendment notes" do
      let(:claim_attributes) do
        {
          eligibility_attributes: {teacher_reference_number: "7654321"},
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

        expect(claim.eligibility.teacher_reference_number).to eq("7654321")
        expect(claim.bank_account_number).to eq("87654321")

        expect(claim.reload.amendments).to be_empty
        expect(claim.eligibility.teacher_reference_number).to eq("1234567")
        expect(claim.bank_account_number).to eq("12345678")

        expect(amendment.errors.attribute_names).to eq([:notes])
      end
    end

    context "given invalid claim attributes and valid amendment attributes" do
      let(:claim_attributes) do
        {
          eligibility_attributes: {teacher_reference_number: "765432"},
          bank_account_number: "87654321"
        }
      end
      let(:amendment_attributes) do
        {
          notes: "This is a change",
          created_by: dfe_signin_user
        }
      end

      it "assigns the new values to the claim but does not persist them, and returns a non-persisted amendment, with the errors from the claim copied to the amendment's errors" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment).to_not be_persisted
        expect(amendment.created_by).to eq(dfe_signin_user)

        expect(claim.eligibility.teacher_reference_number).to eq("765432")
        expect(claim.bank_account_number).to eq("87654321")

        expect(claim.reload.amendments).to be_empty
        expect(claim.eligibility.teacher_reference_number).to eq("1234567")
        expect(claim.bank_account_number).to eq("12345678")

        expect(amendment.errors.attribute_names).to match_array([:"eligibility.teacher_reference_number"])
      end
    end

    context "given invalid claim attributes (blank trn) and valid amendment attributes" do
      let(:claim_attributes) do
        {
          eligibility_attributes: {teacher_reference_number: ""},
          bank_account_number: "87654321"
        }
      end
      let(:amendment_attributes) do
        {
          notes: "This is a change",
          created_by: dfe_signin_user
        }
      end

      it "assigns the new values to the claim but does not persist them, and returns a non-persisted amendment, with the errors from the claim copied to the amendment's errors" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment).to_not be_persisted
        expect(amendment.created_by).to eq(dfe_signin_user)

        expect(claim.eligibility.teacher_reference_number).to eq("")
        expect(claim.bank_account_number).to eq("87654321")

        expect(claim.reload.amendments).to be_empty
        expect(claim.eligibility.teacher_reference_number).to eq("1234567")
        expect(claim.bank_account_number).to eq("12345678")

        expect(amendment.errors.attribute_names).to match_array([:"eligibility.teacher_reference_number"])
      end
    end

    context "given invalid claim attributes and missing amendment notes" do
      let(:claim_attributes) do
        {
          eligibility_attributes: {teacher_reference_number: "765432"},
          bank_account_number: "87654321"
        }
      end
      let(:amendment_attributes) do
        {
          created_by: dfe_signin_user
        }
      end

      it "assigns the new values to the claim but does not persist them, and returns a non-persisted amendment which has errors, with the errors from the claim copied to the amendment's errors" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment).to_not be_persisted
        expect(amendment.created_by).to eq(dfe_signin_user)

        expect(claim.eligibility.teacher_reference_number).to eq("765432")
        expect(claim.bank_account_number).to eq("87654321")

        expect(claim.reload.amendments).to be_empty
        expect(claim.eligibility.teacher_reference_number).to eq("1234567")
        expect(claim.bank_account_number).to eq("12345678")

        expect(amendment.errors.attribute_names).to match_array([:notes, :"eligibility.teacher_reference_number"])
      end
    end

    context "given claim attributes which are all the same as the current values" do
      let(:claim_attributes) do
        {
          eligibility_attributes: {teacher_reference_number: claim.eligibility.teacher_reference_number}
        }
      end
      let(:amendment_attributes) do
        {
          notes: "This is a change",
          created_by: dfe_signin_user
        }
      end

      it "returns a non-persisted amendment which has errors on claim_changes" do
        amendment = described_class.amend_claim(claim.reload, claim_attributes, amendment_attributes)

        expect(amendment).to_not be_persisted
        expect(claim.reload.amendments).to be_empty

        expect(amendment.errors.attribute_names).to eq([:claim_changes])
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

      it "stores the normalised value in the amendment's claim_changes" do
        amendment = described_class.amend_claim(claim.reload, claim_attributes, amendment_attributes)

        expect(amendment.claim_changes).to eq("bank_sort_code" => ["111213", "010203"])
      end
    end

    context "when amending the claim's eligibility attributes" do
      context "with a Student Loans (TSLR) claim" do
        let(:claim) do
          create(:claim, :submitted, eligibility: build(:student_loans_eligibility, :eligible, award_amount: 1000))
        end

        let(:claim_attributes) do
          {
            eligibility_attributes: {award_amount: 555}
          }
        end
        let(:amendment_attributes) do
          {
            notes: "This is a change",
            created_by: dfe_signin_user
          }
        end

        it "stores the value in the amendment's claim_changes" do
          amendment = described_class.amend_claim(claim.reload, claim_attributes, amendment_attributes)

          expect(amendment.claim_changes).to eq("award_amount" => [1000, 555])
        end
      end

      context "when the claim would no longer be valid in the submit context" do
        let(:claim) { create(:claim, :submitted, policy: Policies::StudentLoans) }
        let(:ineligible_school) { create(:school, :student_loans_ineligible) }

        let(:claim_attributes) do
          {
            eligibility_attributes: {
              award_amount: 555
            }
          }
        end
        let(:amendment_attributes) do
          {
            notes: "This is a change",
            created_by: dfe_signin_user
          }
        end

        before do
          claim.eligibility.claim_school = ineligible_school
          claim.eligibility.save!
        end

        subject(:amendment) { described_class.amend_claim(claim, claim_attributes, amendment_attributes) }

        it "reports no errors" do
          expect(amendment.errors).to be_empty
        end
      end

      context "with a Early Career Payments claim" do
        let(:note) do
          <<~NOTE_TEXT
            Teaching at Oulder Hill Community School and Language College.
            GIAS reported as non-uplift school for the original claim as part of the October, 2021 payroll.
            Teacher was paid only £5,000.00.
            This is the claim and payment for the uplift of £2,500.00
          NOTE_TEXT
        end
        let(:eligibility) do
          build(:early_career_payments_eligibility, :eligible, award_amount: 7_500)
        end
        let(:claim) do
          create(:claim, :submitted, policy: Policies::EarlyCareerPayments, eligibility: eligibility)
        end
        let(:claim_attributes) do
          {
            eligibility_attributes: {
              award_amount: 2_500
            }
          }
        end
        let(:amendment_attributes) do
          {
            notes: note,
            created_by: dfe_signin_user
          }
        end

        it "stores the value in the amendment's claim_changes" do
          amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

          expect(amendment.claim_changes).to eq("award_amount" => [7_500, 2_500])
        end
      end
    end

    context "when updating a value from nil to an empty string" do
      let(:claim_attributes) do
        {
          eligibility_attributes: {teacher_reference_number: "7654321"},
          building_society_roll_number: ""
        }
      end
      let(:amendment_attributes) do
        {
          notes: "This is a change",
          created_by: dfe_signin_user
        }
      end

      it "does not mark the value as changed in the amendment's claim_changes" do
        amendment = described_class.amend_claim(claim, claim_attributes, amendment_attributes)

        expect(amendment.claim_changes).to eq("teacher_reference_number" => ["1234567", "7654321"])
      end
    end
  end

  describe ".undo_decision" do
    subject(:amendment) { described_class.undo_decision(decision, notes: "Here are some notes", created_by: dfe_signin_user) }

    let(:dfe_signin_user) { create(:dfe_signin_user) }
    let(:claim) { create(:claim, :approved) }
    let(:decision) { claim.reload.latest_decision }

    shared_examples "undoing a decision" do
      it "returns an Amendment record", :aggregate_failures do
        expect(amendment).to be_a(described_class)
        expect(amendment).to be_persisted
      end

      it "stores the claim changes on the amendment", :aggregate_failures do
        expect(amendment.claim).to eq(claim)
        expect(amendment.claim_changes).to eq({
          decision: [
            "approved",
            "undecided"
          ]
        })
      end

      it "undoes the decision" do
        expect { amendment }.to change { decision.undone }.from(false).to(true)
      end
    end

    context "when a decision exists for the claim" do
      let(:claim) { create(:claim, :approved) }

      include_examples "undoing a decision"
    end

    context "when QA has been completed for the claim" do
      let(:claim) { create(:claim, :approved, :qa_completed) }

      include_examples "undoing a decision"

      it "unsets the QA date on the claim" do
        expect { amendment }.to change { claim.reload.qa_completed_at }.from(claim.qa_completed_at).to(nil)
      end
    end

    context "when the claim has already been paid" do
      before do
        create(:payment, claims: [claim])
      end

      it "returns an unpersisted Amendment record with errors and does not update the decision" do
        expect(amendment).to_not be_persisted
        expect(amendment.errors).to_not be_empty
        expect(amendment.errors.messages[:base]).to include("This claim cannot have its decision undone")

        expect(decision.reload.undone).to eq(false)
      end
    end

    context "when a note has not been included" do
      let(:amendment) { Amendment.undo_decision(decision, notes: "", created_by: dfe_signin_user) }

      it "returns an unpersisted Amendment record with errors and does not update the decision" do
        expect(amendment).to_not be_persisted
        expect(amendment.errors).to_not be_empty
        expect(amendment.errors.messages[:notes]).to include("Enter a message to explain why you are making this amendment")

        expect(decision.reload.result).to eq("approved")
        expect(decision.undone).to eq(false)
      end
    end
  end
end
