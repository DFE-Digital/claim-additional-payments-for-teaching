require "rails_helper"
require Rails.root.join("db", "data", "20190917122531_populate_student_loans_employments")

RSpec.describe PopulateStudentLoansEmployments do
  let(:populate_student_loans_employments) { described_class.new }

  describe "#up" do
    let(:eligibility) { claim.eligibility }
    let!(:claim) do
      create(
        :claim,
        :submittable,
        eligibility: build(
          :student_loans_eligibility,
          claim_school: schools(:penistone_grammar_school),
          physics_taught: true,
          taught_eligible_subjects: true,
          student_loan_repayment_amount: 100
        )
      )
    end

    it "creates a new employment record for the claims" do
      expect {
        populate_student_loans_employments.up
      }.to change { eligibility.employments.count }.by(1)

      expect(eligibility.reload.employments.first.physics_taught).to eql true
      expect(eligibility.employments.first.taught_eligible_subjects).to eql true
      expect(eligibility.employments.first.school).to eql schools(:penistone_grammar_school)
      expect(eligibility.employments.first.student_loan_repayment_amount).to eql 100
    end

    context "when the claim already has an employment" do
      let!(:claim) do
        create(
          :claim,
          :submittable,
          eligibility: build(
            :student_loans_eligibility,
            employments: [build(:student_loans_employment)]
          )
        )
      end

      it "doesn't migrate the data" do
        expect {
          populate_student_loans_employments.up
        }.to change { eligibility.employments.count }.by(0)
      end
    end

    context "when the claim is incomplete and doesn’t have a claim school" do
      let!(:claim) do
        create(
          :claim,
          :submittable,
          eligibility: build(
            :student_loans_eligibility,
            claim_school: nil
          )
        )
      end

      it "doesn't migrate the data" do
        expect {
          populate_student_loans_employments.up
        }.to change { eligibility.employments.count }.by(0)
      end
    end
  end

  describe "#down" do
    let!(:claim) do
      create(
        :claim,
        :submittable,
        eligibility: build(
          :student_loans_eligibility,
          employments: [build(:student_loans_employment)]
        )
      )
    end

    it "removes the employment record" do
      expect {
        populate_student_loans_employments.down
      }.to change { claim.eligibility.employments.count }.from(1).to(0)
    end
  end
end
