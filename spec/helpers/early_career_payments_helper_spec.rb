require "rails_helper"

describe EarlyCareerPaymentsHelper do
  let(:claim) { build(:claim, policy: policy, eligibility: eligibility, academic_year: academic_year) }
  let(:academic_year) { AcademicYear.new(2021) }
  let(:eligibility) { build(:early_career_payments_eligibility) }

  describe "#ineligible_heading" do
    context "A generic ineligible ECP claim" do
      let(:policy) { EarlyCareerPayments }

      it "generates the generic heading for an ineligible claim" do
        expect(helper.ineligible_heading(claim)).to include I18n.t("early_career_payments.ineligible.heading")
      end
    end

    context "An ineligible ECP claim based on poor performance" do
      let(:policy) { EarlyCareerPayments }
      let(:eligibility) { build(:early_career_payments_eligibility, subject_to_formal_performance_action: true) }

      it "generates the correct heading for an ineligible claim based on poor performance" do
        expect(helper.ineligible_heading(claim)).to include I18n.t("early_career_payments.ineligible.heading")
      end
    end

    context "An ineligible ECP claim based on an ineligible school" do
      let(:policy) { EarlyCareerPayments }
      let(:eligibility) { build(:early_career_payments_eligibility, current_school: School.find(ActiveRecord::FixtureSet.identify(:bradford_grammar_school, :uuid))) }

      it "generates the correct heading for an ineligible claim based on an ineligible school" do
        expect(helper.ineligible_heading(claim)).to include I18n.t("early_career_payments.ineligible.school_heading")
      end
    end
  end

  describe "#one_time_password_validity_duration" do
    context "with 'DRIFT' constant set" do
      it "reports '1 minute' when 60 (seconds)" do
        stub_const("OneTimePassword::Base::DRIFT", 60)

        expect(helper.one_time_password_validity_duration).to eq("1 minute")
      end

      it "reports '15 minutes' when 900 (seconds)" do
        stub_const("OneTimePassword::Base::DRIFT", 900)

        expect(helper.one_time_password_validity_duration).to eq("15 minutes")
      end
    end
  end

  describe "#eligible_itt_subject_translation" do
    let(:policy) { EarlyCareerPayments }

    context "trainee teacher in 2021" do
      let(:eligibility) do
        build(:early_career_payments_eligibility, nqt_in_academic_year_after_itt: false, qualification: :postgraduate_itt)
      end

      before do
        @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2021))
      end

      after do
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
      end

      it "generates the correct heading based on being a trainee teacher in 2021" do
        expect(helper.eligible_itt_subject_translation(claim)).to eq("Which subject are you currently doing your initial teacher training (ITT) in?")
      end
    end

    context "not trainee teacher" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible) }

      it "generates the correct heading" do
        expect(helper.eligible_itt_subject_translation(claim)).to eq("Which subject did you do your postgraduate initial teaching training (ITT) in?")
      end
    end
  end

  describe "#ineligible_eligibility_link" do
    context "A generic ineligible ECP claim" do
      let(:policy) { EarlyCareerPayments }

      it "generates the generic link for an ineligible claim" do
        expect(helper.guidance_eligibility_page_link(claim)).to include(EarlyCareerPayments.eligibility_page_url)
      end
    end

    context "An ineligible ECP claim based on being a supply teacher" do
      let(:policy) { EarlyCareerPayments }
      let(:eligibility) { build(:early_career_payments_eligibility, employed_as_supply_teacher: true, has_entire_term_contract: false) }

      it "generates the correct heading for an ineligible claim based on being a supply teacher" do
        expect(helper.guidance_eligibility_page_link(claim)).to include("#{EarlyCareerPayments.eligibility_page_url}#supply-private-school-and-sixth-form-college-teachers")
      end
    end

    describe "#graduate_itt?" do
      subject { helper.graduate_itt?(claim) }

      let(:policy) { EarlyCareerPayments }

      context "when the qualification is UG degree" do
        let(:eligibility) { build(:early_career_payments_eligibility, qualification: :undergraduate_itt) }

        it { is_expected.to be true }
      end

      context "when the qualification is PG degree" do
        let(:eligibility) { build(:early_career_payments_eligibility, qualification: :postgraduate_itt) }

        it { is_expected.to be true }
      end

      context "when the qualification is assessment only" do
        let(:eligibility) { build(:early_career_payments_eligibility, qualification: :assessment_only) }

        it { is_expected.to be false }
      end

      context "when the qualification is overseas recognition" do
        let(:eligibility) { build(:early_career_payments_eligibility, qualification: :overseas_recognition) }

        it { is_expected.to be false }
      end
    end

    describe "#qts?" do
      subject { helper.qts?(claim) }

      let(:policy) { EarlyCareerPayments }

      context "when the qualification is UG degree" do
        let(:eligibility) { build(:early_career_payments_eligibility, qualification: :undergraduate_itt) }

        it { is_expected.to be false }
      end

      context "when the qualification is PG degree" do
        let(:eligibility) { build(:early_career_payments_eligibility, qualification: :postgraduate_itt) }

        it { is_expected.to be false }
      end

      context "when the qualification is assessment only" do
        let(:eligibility) { build(:early_career_payments_eligibility, qualification: :assessment_only) }

        it { is_expected.to be true }
      end

      context "when the qualification is overseas recognition" do
        let(:eligibility) { build(:early_career_payments_eligibility, qualification: :overseas_recognition) }

        it { is_expected.to be true }
      end
    end

    describe "#qualification_name" do
      context "when qualification is 'postgraduate_itt' or 'undergraduate_itt'" do
        eligibility = EarlyCareerPayments::Eligibility.new(qualification: "postgraduate_itt")

        it "returns the qualification in the format '<qualification> initial teaching training'" do
          expect(qualification_name(eligibility.qualification)).to eq "postgraduate initial teaching training"
        end
      end

      context "when qualification is 'assessment_only'" do
        eligibility = EarlyCareerPayments::Eligibility.new(qualification: "assessment_only")

        it "returns the qualification in a humanized for that is lowercase" do
          expect(qualification_name(eligibility.qualification)).to eq "assessment only"
        end
      end

      context "when qualification is 'overseas recognition'" do
        eligibility = EarlyCareerPayments::Eligibility.new(qualification: "overseas_recognition")

        it "returns the qualification in a humanized for that is lowercase" do
          expect(qualification_name(eligibility.qualification)).to eq "overseas recognition qualification"
        end
      end
    end
  end
end
