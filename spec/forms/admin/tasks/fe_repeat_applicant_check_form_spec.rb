require "rails_helper"

RSpec.describe Admin::Tasks::FeRepeatApplicantCheckForm, type: :model do
  subject { described_class.new(claim:, passed:) }

  let(:academic_year) { AcademicYear.new(2025) }

  let(:claim) do
    create(
      :claim,
      :further_education,
      eligibility:,
      academic_year:
    )
  end

  let(:eligibility) do
    build(
      :further_education_payments_eligibility,
      flagged_as_mismatch_on_teaching_start_year: true
    )
  end

  let(:admin_user) { create(:dfe_signin_user) }

  describe "#validations" do
    describe "#passed when no option selected" do
      let(:passed) { nil }

      it "returns correct error message" do
        subject.valid?
        expect(subject.errors[:passed]).to eql(["Select yes if applicant check performed and passed"])
      end
    end
  end

  describe "#save" do
    context "when answer is Yes" do
      let(:passed) { true }

      it do
        expect(subject.save).to be true
        expect(subject.task.passed).to be true
        expect(subject.task.manual).to be true
        expect(claim.eligibility.reload.repeat_applicant_check_passed).to be true
      end
    end

    context "when answer is No" do
      let(:passed) { false }

      it do
        expect(subject.save).to be true
        expect(subject.task.passed).to be false
        expect(subject.task.manual).to be true
        expect(claim.eligibility.reload.repeat_applicant_check_passed).to be false
      end
    end
  end
end
