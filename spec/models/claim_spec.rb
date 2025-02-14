require "rails_helper"

RSpec.describe Claim, type: :model do
  describe "scopes" do
    describe "::require_in_progress_update_emails" do
      let(:claim_1) { create(:claim, policy: Policies::StudentLoans) }
      let(:claim_2) { create(:claim, policy: Policies::EarlyYearsPayments) }

      it "includes correct claims" do
        expect(Claim.require_in_progress_update_emails).to include(claim_1)
        expect(Claim.require_in_progress_update_emails).not_to include(claim_2)
      end
    end

    describe "::by_policy" do
      context "with Policies::EarlyCareerPayments" do
        let(:claim_1) { create(:claim, policy: Policies::StudentLoans) }
        let(:claim_2) { create(:claim, policy: Policies::EarlyCareerPayments) }
        let(:claim_3) { create(:claim, policy: Policies::TargetedRetentionIncentivePayments) }

        it do
          expect(Claim.by_policy(Policies::EarlyCareerPayments)).to contain_exactly(claim_2)
        end
      end

      context "with Policies::StudentLoans" do
        let(:claim_1) { create(:claim, policy: Policies::StudentLoans) }
        let(:claim_2) { create(:claim, policy: Policies::StudentLoans) }
        let(:claim_3) { create(:claim, policy: Policies::EarlyCareerPayments) }
        let(:claim_4) { create(:claim, policy: Policies::TargetedRetentionIncentivePayments) }

        it do
          expect(Claim.by_policy(Policies::StudentLoans)).to contain_exactly(claim_1, claim_2)
        end
      end

      context "with TargetedRetentionIncentivePayments" do
        let(:claim_1) { create(:claim, policy: Policies::StudentLoans) }
        let(:claim_2) { create(:claim, policy: Policies::EarlyCareerPayments) }
        let(:claim_3) { create(:claim, policy: Policies::TargetedRetentionIncentivePayments) }

        it do
          expect(Claim.by_policy(Policies::TargetedRetentionIncentivePayments)).to contain_exactly(claim_3)
        end
      end
    end

    describe "::with_same_claimant" do
      let(:claim_1) { create(:claim, national_insurance_number: "AB123456A") }
      let(:claim_2) { create(:claim, national_insurance_number: "AB123456A") }
      let(:claim_3) { create(:claim, national_insurance_number: "CD123456A") }

      subject { Claim.with_same_claimant(claim_1) }

      it { is_expected.to contain_exactly(claim_2) }
    end
  end

  it "validates academic years are formated like '2020/2021'" do
    expect(build(:claim, academic_year: "2022/2023")).to be_valid
    expect(build(:claim, academic_year: "2020-2021")).not_to be_valid
  end

  context "that has a teacher_reference_number" do
    it "validates the length of the teacher reference number" do
      expect(build(:claim, eligibility_attributes: {teacher_reference_number: "1/2/3/4/5/6/7"}).eligibility).to be_valid
      expect(build(:claim, eligibility_attributes: {teacher_reference_number: "1/2/3/4/5"}).eligibility).not_to be_valid
      expect(build(:claim, eligibility_attributes: {teacher_reference_number: "12/345678"}).eligibility).not_to be_valid
    end
  end

  context "that has bank details" do
    let(:claim) { build(:claim, policy: Policies::EarlyCareerPayments) }

    context "on save" do
      it "strips out white space and the “-” character from bank_account_number and bank_sort_code" do
        claim = build(:claim, bank_sort_code: "12 34 56", bank_account_number: "12-34-56-78")
        claim.save!

        expect(claim.bank_sort_code).to eql("123456")
        expect(claim.bank_account_number).to eql("12345678")
      end

      it "strips spaces from and upcases the National Insurance number" do
        claim = build(:claim, national_insurance_number: "qq 34 56 78 c")
        claim.save!

        expect(claim.national_insurance_number).to eq("QQ345678C")
      end
    end
  end

  context "that has a student loan plan" do
    it "validates the plan" do
      expect(build(:claim, student_loan_plan: StudentLoan::PLAN_1)).to be_valid
      expect(build(:claim, student_loan_plan: nil)).to be_valid

      expect(build(:claim, student_loan_plan: "plan_42")).not_to be_valid
    end
  end

  context "with early-career payments policy eligibility" do
    let(:claim) { build(:claim, policy: Policies::EarlyCareerPayments) }

    it "validates eligibility" do
      expect(claim).not_to be_valid(:amendment)
      expect(claim.errors.map(&:message)).to contain_exactly(
        "Enter your teacher reference number",
        "Enter a sort code",
        "Enter an account number"
      )
    end
  end

  context "when saving in the “student-loan” validation context" do
    it "validates has_student_loan" do
      expect(build(:claim, student_loan_plan: nil, has_student_loan: nil)).to be_valid(:"student-loan")
      expect(build(:claim, student_loan_plan: StudentLoan::PLAN_1, has_student_loan: true)).to be_valid(:"student-loan")
      expect(build(:claim, student_loan_plan: StudentLoan::PLAN_1, has_student_loan: false)).to be_valid(:"student-loan")
    end
  end

  context "when saving in the “submit” validation context" do
    it "validates the claim is in a submittable state" do
      expect(build(:claim)).not_to be_valid(:submit)
      expect(build(:claim, :submittable)).to be_valid(:submit)
    end
  end

  describe "#teacher_reference_number" do
    let(:claim) { build(:claim, eligibility_attributes: {teacher_reference_number: teacher_reference_number}) }

    context "when the teacher reference number is stored and contains non digits" do
      let(:teacher_reference_number) { "12\\23 /232 " }
      it "strips out the non digits" do
        claim.save!
        expect(claim.eligibility.teacher_reference_number).to eql("1223232")
      end
    end

    context "before the teacher reference number is stored" do
      let(:teacher_reference_number) { "12/34567" }
      it "is not modified" do
        expect(claim.eligibility.teacher_reference_number).to eql("12/34567")
      end
    end
  end

  describe "#national_insurance_number" do
    it "saves with white space stripped out" do
      claim = create(:claim, national_insurance_number: "QQ 12 34 56 C")

      expect(claim.national_insurance_number).to eql("QQ123456C")
    end
  end

  describe "#policy" do
    it "returns the claim’s policy namespace" do
      expect(Claim.new(eligibility: Policies::StudentLoans::Eligibility.new).policy).to eq Policies::StudentLoans
    end

    it "returns nil if no eligibility is set" do
      expect(Claim.new.policy).to be_nil
    end
  end

  describe "#school" do
    let(:school) { build(:school) }

    it "returns the current_school of the claim eligiblity" do
      claim = Claim.new(eligibility: Policies::StudentLoans::Eligibility.new(current_school: school))
      expect(claim.school).to eq school
    end

    it "returns nil if no eligibility is set" do
      expect(Claim.new.school).to be_nil
    end
  end

  describe "scopes" do
    let!(:submitted_claims) { create_list(:claim, 5, :submitted) }
    let!(:approved_claims) { create_list(:claim, 5, :approved) }
    let!(:rejected_claims) { create_list(:claim, 5, :rejected) }

    let!(:approved_then_rejected_claim) { create(:claim, :submitted) }
    let!(:rejected_then_approved_claim) { create(:claim, :submitted) }
    let!(:approved_then_decision_undone_claim) { create(:claim, :submitted) }
    let!(:rejected_then_decision_undone_claim) { create(:claim, :submitted) }

    # This doesn't feel great, but works - is this the best way?
    before do
      create(:decision, :approved, :undone, claim: approved_then_rejected_claim)
      create(:decision, :rejected, claim: approved_then_rejected_claim)

      create(:decision, :rejected, :undone, claim: rejected_then_approved_claim)
      create(:decision, :approved, claim: rejected_then_approved_claim)

      create(:decision, :approved, :undone, claim: approved_then_decision_undone_claim)

      create(:decision, :rejected, :undone, claim: rejected_then_decision_undone_claim)
    end

    describe "awaiting_decision" do
      it "returns submitted claims awaiting a decision" do
        expect(Claim.awaiting_decision).to match_array(submitted_claims + [approved_then_decision_undone_claim] + [rejected_then_decision_undone_claim])
      end
    end

    describe "approved" do
      it "returns approved claims" do
        expect(Claim.approved).to match_array(approved_claims + [rejected_then_approved_claim])
      end
    end

    describe "rejected" do
      it "returns rejected claims" do
        expect(Claim.rejected).to match_array(rejected_claims + [approved_then_rejected_claim])
      end
    end
  end

  describe ".awaiting_task" do
    let!(:claim_with_employment_task) { create(:claim, :submitted, tasks: [build(:task, name: "employment")]) }
    let!(:claim_with_qualification_task) { create(:claim, :submitted, tasks: [build(:task, name: "qualifications")]) }
    let!(:claim_with_no_tasks) { create(:claim, :submitted, tasks: []) }
    let!(:claim_with_decision) { create(:claim, :approved, tasks: [build(:task, name: "employment")]) }

    it "returns claims without a decision and without a given task" do
      expect(Claim.awaiting_task("qualifications")).to match_array([claim_with_employment_task, claim_with_no_tasks])
      expect(Claim.awaiting_task("employment")).to match_array([claim_with_qualification_task, claim_with_no_tasks])
    end
  end

  describe "by_academic_year" do
    let(:academic_year_2019) { AcademicYear.new("2019") }
    let(:academic_year_2020) { AcademicYear.new("2020") }

    let!(:academic_year_2019_claims) { create_list(:claim, 5, academic_year: academic_year_2019) }
    let!(:academic_year_2020_claims) { create_list(:claim, 5, academic_year: academic_year_2020) }

    it "returns claims for a specific academic year" do
      expect(Claim.by_academic_year(academic_year_2019.dup)).to match_array(academic_year_2019_claims)
      expect(Claim.by_academic_year(academic_year_2020.dup)).to match_array(academic_year_2020_claims)
    end
  end

  describe "#submittable?" do
    context "with student loans policy eligibility" do
      let(:policy) { Policies::StudentLoans }

      context "when submittable" do
        subject(:claim) { build(:claim, :submittable, policy:) }

        it { is_expected.to be_submittable }
      end

      context "when submitted" do
        subject(:claim) { build(:claim, :submitted, policy:) }

        it { is_expected.not_to be_submittable }
      end
    end

    context "with early-career payments policy eligibility" do
      let(:policy) { Policies::EarlyCareerPayments }

      context "when submittable" do
        subject(:claim) { build(:claim, :submittable, policy:) }

        it { is_expected.to be_submittable }
      end

      context "when using the mobile number from Teacher ID" do
        subject(:claim) { build(:claim, :submittable, using_mobile_number_from_tid: true, policy:) }

        it { is_expected.to be_submittable }
      end

      context "when submitted" do
        subject(:claim) { build(:claim, :submitted, policy:) }

        it { is_expected.not_to be_submittable }
      end
    end
  end

  describe "#approvable?" do
    it "returns true for a submitted claim with all required data present" do
      expect(build(:claim, :submitted).approvable?).to eq true
    end

    it "returns false for an unsubmitted claim" do
      expect(build(:claim, :submittable).approvable?).to eq false
    end

    it "returns false for a submitted claim that is missing a binary value for payroll_gender" do
      expect(build(:claim, :submitted, payroll_gender: :dont_know).approvable?).to eq false
    end

    it "returns true for a claim that already does not have a decision" do
      expect(build(:claim, :submitted).approvable?).to eq true
    end

    it "returns false when a claim has already been approved" do
      claim_with_decision = create(:claim, :submitted)
      expect(claim_with_decision.approvable?).to eq true
      create(:decision, claim: claim_with_decision, result: :approved)

      expect(claim_with_decision.approvable?).to eq false
    end

    it "returns false when a claim has already been rejected" do
      claim_with_decision = create(:claim, :submitted)
      create(:decision, :rejected, claim: claim_with_decision)

      expect(claim_with_decision.approvable?).to eq false
    end

    it "returns true for a claim that has already been approved and awaiting QA" do
      claim_with_decision = create(:claim, :submitted, :flagged_for_qa)
      create(:decision, :approved, claim: claim_with_decision)

      expect(claim_with_decision.approvable?).to eq true
    end

    it "returns true for a claim that has already been rejected and awaiting QA" do
      claim_with_decision = create(:claim, :submitted, :flagged_for_qa)
      create(:decision, :rejected, claim: claim_with_decision)

      expect(claim_with_decision.approvable?).to eq true
    end

    it "returns false for a claim that has already been approved and QA'd" do
      claim_with_decision = create(:claim, :submitted, :qa_completed)
      create(:decision, :approved, claim: claim_with_decision)

      expect(claim_with_decision.approvable?).to eq false
    end

    it "returns false for a claim that has already been rejected and QA'd" do
      claim_with_decision = create(:claim, :submitted, :qa_completed)
      create(:decision, :rejected, claim: claim_with_decision)

      expect(claim_with_decision.approvable?).to eq false
    end

    it "returns false when there exists another payrollable claim with the same national insurance number but with inconsistent attributes that would prevent us from running payroll" do
      national_insurance_number = generate(:national_insurance_number)
      create(:claim, :approved, national_insurance_number: national_insurance_number, date_of_birth: 20.years.ago)

      expect(create(:claim, :submitted, national_insurance_number: national_insurance_number, date_of_birth: 30.years.ago).approvable?).to eq false
    end

    it "returns false if the claim is flagged by a fraud check" do
      claim = create(:claim, :submitted, national_insurance_number: "QQ123456C")
      create(:risk_indicator, field: "national_insurance_number", value: "QQ123456C")

      expect(claim.approvable?).to eq false
    end

    context "when the claim is held" do
      subject(:claim) { create(:claim, :held) }
      it { is_expected.not_to be_approvable }
    end

    context "when policy specific conditions are met" do
      subject do
        create(
          :claim,
          :submitted,
          policy: Policies::EarlyYearsPayments
        )
      end

      it "is approvable" do
        allow(subject.policy).to receive(:approvable?).and_return(true)
        expect(subject).to be_approvable
      end
    end

    context "when policy specific conditions are not met" do
      subject do
        create(
          :claim,
          :submitted,
          policy: Policies::EarlyYearsPayments
        )
      end

      it "is not approvable" do
        allow(subject.policy).to receive(:approvable?).and_return(false)
        expect(subject).not_to be_approvable
      end
    end
  end

  describe "#rejectable?" do
    context "when the claim is held" do
      subject(:claim) { create(:claim, :held) }
      it { is_expected.not_to be_rejectable }
    end

    context "when the claim is not held" do
      subject(:claim) { create(:claim) }
      it { is_expected.to be_rejectable }
    end
  end

  describe "#flaggable_for_qa?" do
    subject { claim.flaggable_for_qa? }

    context "when a decision has not been made" do
      let(:claim) { create(:claim, :submitted) }

      it { is_expected.to eq(false) }
    end

    context "when the claim has been rejected" do
      let(:claim) { create(:claim, :rejected) }

      it { is_expected.to eq(false) }
    end

    context "when the claim has been approved" do
      let(:claim) { create(:claim, :approved) }

      context "when above the min QA threshold" do
        before do
          stub_const("Policies::#{claim.policy}::APPROVED_MIN_QA_THRESHOLD", 0)
        end

        it { is_expected.to eq(false) }
      end

      context "when below the min QA threshold" do
        before do
          stub_const("Policies::#{claim.policy}::APPROVED_MIN_QA_THRESHOLD", 100)
        end

        it { is_expected.to eq(true) }
      end
    end

    context "when the claim has been flagged for QA already" do
      let(:claim) { create(:claim, :approved, :flagged_for_qa) }

      it { is_expected.to eq(false) }
    end

    context "when a QA decision has been made already" do
      let(:claim) { create(:claim, :approved, :qa_completed) }

      it { is_expected.to eq(false) }
    end
  end

  describe "#qa_completed?" do
    subject { claim.qa_completed? }

    context "when the qa_completed_at is set" do
      let(:claim) { build_stubbed(:claim, :qa_completed) }

      it { is_expected.to eq(true) }
    end

    context "when the qa_completed_at is not set" do
      let(:claim) { build_stubbed(:claim, :flagged_for_qa) }

      it { is_expected.to eq(false) }
    end
  end

  describe "#awaiting_qa?" do
    subject { claim.awaiting_qa? }

    context "when the qa_required is false" do
      let(:claim) { build_stubbed(:claim, qa_required: false) }

      it { is_expected.to eq(false) }
    end

    context "when the qa_required is true" do
      context "when the qa_completed_at is not set" do
        let(:claim) { build_stubbed(:claim, qa_required: true, qa_completed_at: nil) }

        it { is_expected.to eq(true) }
      end

      context "when the qa_completed_at is set" do
        let(:claim) { build_stubbed(:claim, qa_required: true, qa_completed_at: Time.zone.now) }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe "#decision" do
    it "returns the latest decision on a claim" do
      claim = create(:claim, :submitted)
      create(:decision, result: "approved", claim: claim, created_at: 7.days.ago)
      create(:decision, :rejected, claim: claim, created_at: DateTime.now)

      expect(claim.latest_decision.result).to eq "rejected"
    end

    it "returns only decisions which haven't been undone" do
      claim = create(:claim, :submitted)
      create(:decision, :undone, :rejected, claim: claim)

      expect(claim.latest_decision).to be_nil
    end
  end

  describe "#payroll_gender_missing?" do
    it "returns true when the claimant doesn't know their payroll gender" do
      claim = build(:claim, payroll_gender: :dont_know)

      expect(claim.payroll_gender_missing?).to eq true
    end

    it "returns false when the payroll gender is one accepted by the payroll provider" do
      claim = build(:claim, payroll_gender: :female)

      expect(claim.payroll_gender_missing?).to eq false
    end
  end

  describe "#identity_verified?" do
    it "returns true if the claim has any GOV.UK Verify fields" do
      expect(Claim.new(govuk_verify_fields: ["payroll_gender"]).identity_verified?).to eq true
    end

    it "returns false if the claim doesn't have any GOV.UK Verify fields" do
      expect(Claim.new.identity_verified?).to eq false
      expect(Claim.new(govuk_verify_fields: []).identity_verified?).to eq false
    end
  end

  describe "#name_verified?" do
    it "returns true if the name is present in the list of GOV.UK Verify fields" do
      expect(Claim.new.name_verified?).to eq false
      expect(Claim.new(govuk_verify_fields: ["first_name"]).name_verified?).to eq true
    end
  end

  describe "#address_from_govuk_verify?" do
    it "returns true if any address attributes are in the list of GOV.UK Verify fields" do
      expect(Claim.new.address_from_govuk_verify?).to eq false
      expect(Claim.new(govuk_verify_fields: ["payroll_gender"]).address_from_govuk_verify?).to eq false

      expect(Claim.new(govuk_verify_fields: ["address_line_1"]).address_from_govuk_verify?).to eq true
      expect(Claim.new(govuk_verify_fields: ["address_line_1", "postcode"]).address_from_govuk_verify?).to eq true
    end
  end

  describe "#date_of_birth_verified?" do
    it "returns true if date_of_birth is in the list of GOV.UK Verify fields" do
      expect(Claim.new(govuk_verify_fields: ["date_of_birth"]).date_of_birth_verified?).to eq true
      expect(Claim.new(govuk_verify_fields: ["address_line_1"]).date_of_birth_verified?).to eq false
    end
  end

  describe "#payroll_gender_verified?" do
    it "returns true if payroll_gender is in the list of GOV.UK Verify fields" do
      expect(Claim.new(govuk_verify_fields: ["payroll_gender"]).payroll_gender_verified?).to eq true
      expect(Claim.new(govuk_verify_fields: ["address_line_1"]).payroll_gender_verified?).to eq false
    end
  end

  describe "#personal_data_removed?" do
    it "returns false if a claim has not had its personal data removed" do
      claim = create(:claim, :approved)
      expect(claim.personal_data_removed?).to eq false
    end

    it "returns true if a claim has the time personal data was removed recorded" do
      claim = create(:claim, :approved, personal_data_removed_at: Time.zone.now)
      expect(claim.personal_data_removed?).to eq true
    end
  end

  describe "#payrolled?" do
    it "returns false if a claim has not been added to payroll" do
      claim = create(:claim, :approved)
      expect(claim.payrolled?).to eq false
    end

    it "returns true if a claim has been added to payroll but is not yet paid" do
      claim = create(:claim, :approved)
      create(:payment, claims: [claim])
      expect(claim.payrolled?).to eq true
    end

    it "returns true if a claim has been scheduled for payment" do
      claim = create(:claim, :approved)
      create(:payment, :with_figures, claims: [claim])
      expect(claim.payrolled?).to eq true
    end
  end

  describe "#full_name" do
    it "joins the first name and surname together" do
      expect(Claim.new(first_name: "Isambard", surname: "Brunel").full_name).to eq "Isambard Brunel"
    end

    it "joins the first name and surname together with only one space when middle name is an empty string" do
      expect(Claim.new(first_name: "Isambard", middle_name: "", surname: "Brunel").full_name).to eq "Isambard Brunel"
    end

    it "joins the first name and surname together with only one space when middle name is a blank string" do
      expect(Claim.new(first_name: "Isambard", middle_name: " ", surname: "Brunel").full_name).to eq "Isambard Brunel"
    end

    it "includes a middle name when present" do
      expect(
        Claim.new(first_name: "Isambard", middle_name: "Kingdom", surname: "Brunel").full_name
      ).to eq "Isambard Kingdom Brunel"
    end
  end

  describe "#below_min_qa_threshold?" do
    let(:policy) { Policies::EarlyCareerPayments }
    let(:other_policy) { Policies::POLICIES.detect { |p| p != policy } }

    subject { build(:claim, policy: policy).below_min_qa_threshold? }

    context "when the APPROVED_MIN_QA_THRESHOLD is set to zero" do
      before do
        stub_const("Policies::#{policy}::APPROVED_MIN_QA_THRESHOLD", 0)
      end

      it { is_expected.to eq(false) }
    end

    context "when the APPROVED_MIN_QA_THRESHOLD is set to 10" do
      before do
        stub_const("Policies::#{policy}::APPROVED_MIN_QA_THRESHOLD", 10)
      end

      context "with no previously approved claims" do
        let!(:claims_for_other_policy) do
          create_list(
            :claim,
            1,
            :approved,
            :flagged_for_qa,
            policy: other_policy,
            academic_year: AcademicYear.current
          )
        end
        it { is_expected.to eq(true) }
      end

      context "with 1 previously approved claim (1 flagged for QA)" do
        let!(:claims_flagged_for_qa) do
          create_list(
            :claim,
            1,
            :approved,
            :flagged_for_qa,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end

        it { is_expected.to eq(false) }
      end

      context "with 2 previously approved claims (1 flagged for QA)" do
        let!(:claims_flagged_for_qa) do
          create_list(
            :claim,
            1,
            :approved,
            :flagged_for_qa,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end
        let!(:claims_not_flagged_for_qa) do
          create_list(
            :claim,
            1,
            :approved,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end

        it { is_expected.to eq(false) }
      end

      context "with 9 previously approved claims (1 flagged for QA)" do
        let!(:claims_flagged_for_qa) do
          create_list(
            :claim,
            1,
            :approved,
            :flagged_for_qa,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end

        let!(:claims_not_flagged_for_qa) do
          create_list(
            :claim,
            8,
            :approved,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end
        let!(:claims_for_other_policy) do
          create_list(
            :claim,
            1,
            :approved,
            :flagged_for_qa,
            policy: other_policy,
            academic_year: AcademicYear.current
          )
        end

        it { is_expected.to eq(false) }
      end

      context "with 10 previously approved claims (1 flagged for QA)" do
        let!(:claims_flagged_for_qa) do
          create_list(
            :claim,
            1,
            :approved,
            :flagged_for_qa,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end
        let!(:claims_not_flagged_for_qa) do
          create_list(
            :claim,
            9,
            :approved,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end
        let!(:claims_for_other_policy) do
          create_list(
            :claim,
            1,
            :approved,
            :flagged_for_qa,
            policy: other_policy,
            academic_year: AcademicYear.current
          )
        end

        it { is_expected.to eq(true) }
      end

      context "with 11 previously approved claims (2 flagged for QA)" do
        let!(:claims_flagged_for_qa) do
          create_list(
            :claim,
            2,
            :approved,
            :flagged_for_qa,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end
        let!(:claims_not_flagged_for_qa) do
          create_list(
            :claim,
            10,
            :approved,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end
        let!(:claims_for_other_policy) do
          create_list(
            :claim,
            2,
            :approved,
            policy: other_policy,
            academic_year: AcademicYear.current
          )
        end

        it { is_expected.to eq(false) }
      end

      context "with 21 previously approved claims (2 flagged for QA)" do
        let!(:claims_flagged_for_qa) do
          create_list(
            :claim,
            2,
            :approved,
            :flagged_for_qa,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end
        let!(:claims_not_flagged_for_qa) do
          create_list(
            :claim,
            19,
            :approved,
            policy: policy,
            academic_year: AcademicYear.current
          )
        end
        let!(:claims_for_other_policy) do
          create_list(
            :claim,
            19,
            :approved,
            policy: other_policy,
            academic_year: AcademicYear.current
          )
        end

        it { is_expected.to eq(true) }
      end
    end
  end

  describe ".payrollable" do
    subject { described_class.payrollable.order(:submitted_at) }

    let(:payroll_run) { create(:payroll_run, claims_counts: {Policies::StudentLoans => 1}) }
    let!(:submitted_claim) { create(:claim, :submitted) }
    let!(:first_unpayrolled_claim) { create(:claim, :approved) }
    let!(:second_unpayrolled_claim) { create(:claim, :approved) }
    let(:claim_awaiting_qa) { create(:claim, :approved, :flagged_for_qa) }
    let(:claim_with_qa_completed) { create(:claim, :approved, :qa_completed) }

    let!(:first_unpayrolled_claim) { create(:claim, :approved, submitted_at: 2.days.ago) }
    let!(:second_unpayrolled_claim) { create(:claim, :approved, submitted_at: 1.day.ago) }

    it "returns approved claims not associated with a payroll run and ordered by submission date" do
      is_expected.to eq([first_unpayrolled_claim, second_unpayrolled_claim])
    end

    it "excludes claims that are awaiting QA" do
      claim_awaiting_qa
      claim_with_qa_completed

      is_expected.to eq([first_unpayrolled_claim, second_unpayrolled_claim, claim_with_qa_completed])
    end
  end

  describe ".not_awaiting_qa" do
    subject { described_class.not_awaiting_qa }

    let!(:claim_approved) { create(:claim, :approved) }
    let!(:claim_awaiting_qa) { create(:claim, :approved, :flagged_for_qa) }
    let!(:claim_with_qa_completed) { create(:claim, :approved, :qa_completed) }

    it "returns approved claims that are approved and with QA completed" do
      is_expected.to match_array([claim_approved, claim_with_qa_completed])
    end
  end

  describe ".awaiting_qa" do
    subject { described_class.awaiting_qa }

    let!(:claim_approved) { create(:claim, :approved) }
    let!(:claim_awaiting_qa) { create(:claim, :approved, :flagged_for_qa) }
    let!(:claim_with_qa_completed) { create(:claim, :approved, :qa_completed) }

    it "returns approved claims that are awaiting QA" do
      is_expected.to match_array([claim_awaiting_qa])
    end
  end

  describe ".qa_required" do
    subject { described_class.qa_required }

    let!(:claim_approved) { create(:claim, :approved) }
    let!(:claim_awaiting_qa) { create(:claim, :approved, :flagged_for_qa) }
    let!(:claim_with_qa_completed) { create(:claim, :approved, :qa_completed) }

    it "returns approved claims that are flagged for QA" do
      is_expected.to match_array([claim_awaiting_qa, claim_with_qa_completed])
    end
  end

  describe ".auto_approved" do
    subject { described_class.auto_approved }

    let!(:claim_approved) { create(:claim, :approved) }
    let!(:claim_auto_approved) { create(:claim, :auto_approved) }
    let!(:another_claim_auto_approved) { create(:claim, :auto_approved) }

    it "returns claims that have been auto-approved" do
      is_expected.to match_array([claim_auto_approved, another_claim_auto_approved])
    end
  end

  describe "awaiting further education provider verification scopes" do
    let!(:claim_not_verified_provider_email_automatically_sent) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility_trait: :not_verified) }
    let!(:claim_not_verified_has_duplicates_provider_email_not_sent_has_other_note) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility_trait: :duplicate) }
    let!(:claim_not_verified_has_duplicates_provider_email_not_sent) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility_trait: :duplicate) }
    let!(:claim_not_verified_has_duplicates_provider_email_manually_sent) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility_trait: :duplicate) }
    let!(:claim_with_fe_provider_verification) { create(:claim, policy: Policies::FurtherEducationPayments, eligibility_trait: :verified) }
    let!(:non_fe_claim) { create(:claim, policy: Policies::StudentLoans) }

    before do
      create(:note, claim: claim_not_verified_has_duplicates_provider_email_manually_sent, label: "provider_verification")
      create(:note, claim: claim_not_verified_has_duplicates_provider_email_not_sent_has_other_note, label: "student_loan_plan")
    end

    describe ".awaiting_further_education_provider_verification" do
      subject { described_class.awaiting_further_education_provider_verification }

      it "returns claims that have not been verified by the provider, and have had a provider email sent" do
        is_expected.to match_array(
          [
            claim_not_verified_provider_email_automatically_sent,
            claim_not_verified_has_duplicates_provider_email_manually_sent
          ]
        )
      end
    end

    describe ".not_awaiting_further_education_provider_verification" do
      subject { described_class.not_awaiting_further_education_provider_verification }

      it "returns claims that have no FE eligiblity, or FE claims that have been verified by the provider, or non-verified claims where a provider email has not been sent" do
        is_expected.to match_array(
          [
            claim_not_verified_has_duplicates_provider_email_not_sent_has_other_note,
            claim_not_verified_has_duplicates_provider_email_not_sent,
            claim_with_fe_provider_verification,
            non_fe_claim
          ]
        )
      end
    end
  end

  describe "#amendable?" do
    it "returns false for a claim that hasn’t been submitted" do
      claim = build(:claim, :submittable)
      expect(claim.amendable?).to eq(false)
    end

    it "returns true for a submitted claim" do
      claim = build(:claim, :submitted)
      expect(claim.amendable?).to eq(true)
    end

    it "returns true for an approved claim" do
      claim = create(:claim, :approved)
      expect(claim.amendable?).to eq(true)
    end

    it "returns true for a rejected claim" do
      claim = create(:claim, :rejected)
      expect(claim.amendable?).to eq(true)
    end

    it "returns false for a payrolled claim" do
      claim = build(:claim, :approved)
      create(:payment, claims: [claim])

      expect(claim.amendable?).to eq(false)
    end

    it "returns false for a claim that’s had its personal data removed" do
      claim = build(:claim, :personal_data_removed)
      expect(claim.amendable?).to eq(false)
    end
  end

  describe "#decision_made?" do
    it "returns false for a claim that hasn’t been submitted" do
      claim = create(:claim, :submittable)
      expect(claim.decision_made?).to eq(false)
    end

    it "returns false for a claim that has been submitted but not decided" do
      claim = create(:claim, :submitted)
      expect(claim.decision_made?).to eq(false)
    end

    it "returns true for a claim that has been approved" do
      claim = create(:claim, :approved)
      expect(claim.decision_made?).to eq(true)
    end

    it "returns true for a claim that has been rejected" do
      claim = create(:claim, :rejected)
      expect(claim.decision_made?).to eq(true)
    end

    it "returns true for a claim that had a decison made, undone, then been approved" do
      claim = create(:claim, :submitted)
      create(:decision, :undone, :rejected, claim: claim)
      create(:decision, result: "approved", claim: claim)
      expect(claim.decision_made?).to eq(true)
    end

    it "returns true for a claim that had a decison made, undone, then been rejected" do
      claim = create(:claim, :submitted)
      create(:decision, :undone, result: "approved", claim: claim)
      create(:decision, :rejected, claim: claim)
      expect(claim.decision_made?).to eq(true)
    end

    it "returns false for a claim that had a decison made, then undone" do
      claim = create(:claim, :submitted)
      create(:decision, :undone, result: "approved", claim: claim)
      expect(claim.decision_made?).to eq(false)
    end
  end

  describe "#decision_undoable?" do
    it "returns false for a claim that hasn’t been submitted" do
      claim = create(:claim, :submittable)
      expect(claim.decision_undoable?).to eq(false)
    end

    it "returns false for a submitted but undecided claim" do
      claim = create(:claim, :submitted)
      expect(claim.decision_undoable?).to eq(false)
    end

    it "returns true for a rejected claim" do
      claim = create(:claim, :rejected)
      expect(claim.decision_undoable?).to eq(true)
    end

    it "returns false for a claim that had a decison made, then undone" do
      claim = create(:claim, :submitted)
      create(:decision, :undone, result: "approved", claim: claim)
      expect(claim.decision_made?).to eq(false)
    end

    it "returns true for an approved claim that isn’t payrolled" do
      claim = create(:claim, :approved)
      expect(claim.decision_undoable?).to eq(true)
    end

    it "returns false for a payrolled claim" do
      claim = create(:claim, :approved)
      create(:payment, claims: [claim])

      expect(claim.decision_undoable?).to eq(false)
    end

    it "returns false for a claim that’s had its personal data removed" do
      claim = create(:claim, :personal_data_removed)
      expect(claim.decision_undoable?).to eq(false)
    end
  end

  describe "#has_ecp_policy?" do
    let(:claim) { create(:claim, policy:) }

    context "with student loans policy" do
      let(:policy) { Policies::StudentLoans }

      it "returns false" do
        expect(claim.has_ecp_policy?).to eq(false)
      end
    end

    context "with early-career payments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it "returns true" do
        expect(claim.has_ecp_policy?).to eq(true)
      end
    end
  end

  describe "#has_tslr_policy?" do
    let(:claim) { create(:claim, policy:) }

    context "with student loans policy" do
      let(:policy) { Policies::StudentLoans }

      it "returns true" do
        expect(claim.has_tslr_policy?).to eq(true)
      end
    end

    context "with early-career payments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it "returns false" do
        expect(claim.has_tslr_policy?).to eq(false)
      end
    end
  end

  describe "#has_targeted_retention_incentive_policy?" do
    subject(:result) { claim.has_targeted_retention_incentive_policy? }
    let(:claim) { create(:claim, policy:) }

    context "with student loans policy" do
      let(:policy) { Policies::StudentLoans }

      it { is_expected.to be false }
    end

    context "with early-career payments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it { is_expected.to be false }
    end

    context "with levelling-up premium payments policy" do
      let(:policy) { Policies::TargetedRetentionIncentivePayments }

      it { is_expected.to be true }
    end
  end

  describe "#has_ecp_or_targeted_retention_incentive_policy?" do
    subject(:result) { claim.has_ecp_or_targeted_retention_incentive_policy? }
    let(:claim) { create(:claim, policy:) }

    context "with student loans policy" do
      let(:policy) { Policies::StudentLoans }

      it { is_expected.to be false }
    end

    context "with early-career payments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it { is_expected.to be true }
    end

    context "with levelling-up premium payments policy" do
      let(:policy) { Policies::TargetedRetentionIncentivePayments }

      it { is_expected.to be true }
    end
  end

  describe "#has_early_years_payments_policy?" do
    subject { claim.has_early_years_payments_policy? }
    let(:claim) { create(:claim, :submitted, policy:) }

    context "with early years payements policy" do
      let(:policy) { Policies::EarlyYearsPayments }

      it { is_expected.to be true }
    end

    context "with other policies:" do
      (Policies.all - [Policies::EarlyYearsPayments]).each do |policy|
        context policy do
          let(:policy) { policy }

          it { is_expected.to be false }
        end
      end
    end
  end

  describe "#important_notes" do
    subject(:important_notes) do
      claim.important_notes
    end

    let(:claim) { create(:claim, notes: notes) }

    context "without important notes" do
      let(:notes) { create_list(:note, 2, important: false) }

      it { is_expected.to be_empty }
    end

    context "with important notes" do
      let(:notes) { create_list(:note, 2, important: true) }

      it { is_expected.to match_array notes }
    end
  end

  describe "#destroy" do
    let(:claim) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments) }

    before do
      create(:note, claim: claim)
      create(:task, claim: claim)
      create(:amendment, claim: claim)
      create(:decision, :approved, claim: claim)
      create(:support_ticket, claim: claim)
    end

    it "destroys associated records" do
      claim.reload.destroy!
      expect(Policies::EarlyCareerPayments::Eligibility.count).to be_zero
      expect(Note.count).to be_zero
      expect(Task.count).to be_zero
      expect(Amendment.count).to be_zero
      expect(Decision.count).to be_zero
      expect(SupportTicket.count).to be_zero
    end
  end

  describe "#hold!" do
    let(:reason) { "test" }
    let(:user) { build(:dfe_signin_user) }

    before { claim.hold!(reason: reason, user: user) }

    context "when the claim is already held" do
      subject(:claim) { build(:claim, :held) }

      it { is_expected.to be_held }

      it "does not add a note" do
        expect(claim.notes).to be_empty
      end
    end

    context "when the claim cannot be held" do
      subject(:claim) { create(:claim, :approved) }

      it { is_expected.not_to be_held }
    end

    context "when the claim is not already held" do
      subject(:claim) { build(:claim) }

      it { is_expected.to be_held }

      it "adds a note" do
        expect(claim.notes.first.body).to eq "Claim put on hold: #{reason}"
        expect(claim.notes.first.created_by).to eq user
      end
    end
  end

  describe "#unhold!" do
    let(:user) { build(:dfe_signin_user) }

    before { claim.unhold!(user: user) }

    context "when the claim is held" do
      subject(:claim) { build(:claim, :held) }

      it { is_expected.not_to be_held }

      it "adds a note" do
        expect(claim.notes.first.body).to eq "Claim hold removed"
        expect(claim.notes.first.created_by).to eq user
      end
    end

    context "when the claim is not held" do
      subject(:claim) { build(:claim) }

      it { is_expected.not_to be_held }

      it "does not add a note" do
        expect(claim.notes).to be_empty
      end
    end
  end

  describe "#holdable?" do
    context "when the claim has no approval decision" do
      subject(:claim) { build(:claim, :submitted) }
      it { is_expected.to be_holdable }
    end

    context "when the claim has is approved" do
      subject(:claim) { build(:claim, :rejected) }
      it { is_expected.not_to be_holdable }
    end

    context "when the claim has is rejected" do
      subject(:claim) { build(:claim, :rejected) }
      it { is_expected.not_to be_holdable }
    end
  end

  describe "#must_manually_validate_bank_details?" do
    context "when bank details have been validated" do
      subject(:claim) { build(:claim, :bank_details_validated) }
      it { is_expected.not_to be_must_manually_validate_bank_details }
    end

    context "when bank details have not been validated" do
      subject(:claim) { build(:claim, :bank_details_not_validated) }
      it { is_expected.to be_must_manually_validate_bank_details }
    end
  end

  describe "#submitted_without_slc_data?" do
    context "when `submitted_using_slc_data` is `true`" do
      subject(:claim) { build(:claim, submitted_using_slc_data: true) }

      it { is_expected.not_to be_submitted_without_slc_data }
    end

    context "when `submitted_using_slc_data` is `false`" do
      subject(:claim) { build(:claim, submitted_using_slc_data: false) }

      it { is_expected.to be_submitted_without_slc_data }
    end

    # For 2024/2025 academic year onwards, only FE claims prior to the deployment of LUPEYALPHA-1010 have submitted_using_slc_data = nil
    context "when `submitted_using_slc_data` is `nil`" do
      subject(:claim) { build(:claim, submitted_using_slc_data: nil) }

      it { is_expected.to be_submitted_without_slc_data }
    end
  end

  describe "#has_dqt_record?" do
    let(:claim) { build(:claim, dqt_teacher_status:) }
    subject(:result) { claim.has_dqt_record? }

    context "when dqt_teacher_status value is nil" do
      let(:dqt_teacher_status) { nil }
      it { is_expected.to be false }
    end

    context "when dqt_teacher_status value is empty" do
      let(:dqt_teacher_status) { {} }
      it { is_expected.to be false }
    end

    context "when dqt_teacher_status value is not empty" do
      let(:dqt_teacher_status) { {"test" => "test"} }
      it { is_expected.to be true }
    end
  end

  describe "#dqt_teacher_record" do
    let(:claim) { build(:claim, dqt_teacher_status:) }
    subject(:result) { claim.dqt_teacher_record }

    context "when dqt_teacher_status value is nil" do
      let(:dqt_teacher_status) { nil }
      it { is_expected.to be nil }
    end

    context "when dqt_teacher_status value is empty" do
      let(:dqt_teacher_status) { {} }
      it { is_expected.to be nil }
    end

    context "when dqt_teacher_status value is not empty" do
      let(:dqt_teacher_status) { {"test" => "test"} }
      it { is_expected.to be_a(claim.policy::DqtRecord) }
    end
  end

  describe "#same_claimant?" do
    subject { claim.same_claimant?(other_claim) }

    let(:claim) { create(:claim, national_insurance_number: "AA12345A") }

    context "with the same claimant" do
      let(:other_claim) { create(:claim, national_insurance_number: "AA12345A") }

      it { is_expected.to be true }
    end

    context "with a different claimant" do
      let(:other_claim) { create(:claim, national_insurance_number: "BB12345B") }

      it { is_expected.to be false }
    end
  end

  describe "#awaiting_provider_verification?" do
    subject { claim.awaiting_provider_verification? }

    context "when the eligiblity is not verified" do
      context "when there are no duplicates" do
        let(:claim) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility_trait: :not_verified) }

        it { is_expected.to be true }
      end

      context "when there are duplicates" do
        let(:claim) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility_trait: :duplicate) }

        context "the provider email has not been sent" do
          it { is_expected.to be false }
        end

        context "when the provider email has been sent" do
          before { create(:note, claim: claim, label: "provider_verification") }

          it { is_expected.to be true }
        end
      end
    end

    context "when the eligiblity is verified" do
      let(:claim) { build(:claim, policy: Policies::FurtherEducationPayments, eligibility_trait: :verified) }

      it { is_expected.to be false }
    end

    context "when the eligiblity is not further education payments" do
      let(:claim) { build(:claim, policy: Policies::StudentLoans) }

      it { is_expected.to be false }
    end
  end

  describe "#decision_deadline_date" do
    let(:policy) { Policies.all.sample }
    let(:claim) { create(:claim, :eligible, :early_years_provider_submitted, policy:) }

    it "delegates to policy" do
      allow(policy).to receive(:decision_deadline_date)

      claim.decision_deadline_date

      expect(policy).to have_received(:decision_deadline_date).with(claim)
    end
  end

  describe "#one_login_idv_match?" do
    context "space in first name" do
      before do
        subject.onelogin_idv_full_name = "A B C"
        subject.first_name = "A B"
        subject.surname = "C"

        subject.onelogin_idv_date_of_birth = Date.today
        subject.date_of_birth = Date.today
      end

      it "matches" do
        expect(subject).to be_one_login_idv_match
      end
    end

    context "close match" do
      before do
        subject.onelogin_idv_full_name = "A B C"
        subject.first_name = "AA B"
        subject.surname = "C"

        subject.onelogin_idv_date_of_birth = Date.today
        subject.date_of_birth = Date.today
      end

      it "does not match" do
        expect(subject).not_to be_one_login_idv_match
      end
    end

    context "not a match" do
      before do
        subject.onelogin_idv_full_name = "A B"
        subject.first_name = "Z"
        subject.surname = "B"

        subject.onelogin_idv_date_of_birth = Date.today
        subject.date_of_birth = Date.today
      end

      it "does not match" do
        expect(subject).not_to be_one_login_idv_match
      end
    end
  end
end
