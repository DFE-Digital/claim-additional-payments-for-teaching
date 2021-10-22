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

      it "generates the correct heading based on being a traineer teacher in 2021" do
        expect(helper.eligible_itt_subject_translation(claim)).to eq("Which subject are you currently doing your postgraduate initial teacher training (ITT) in?")
      end
    end

    context "not traineer teacher" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible) }

      it "generates the correct heading" do
        expect(helper.eligible_itt_subject_translation(claim)).to eq("Which subject did you do your postgraduate initial teacher training (ITT) in?")
      end
    end
  end

  describe "ECP NQT wording" do
    let(:policy) { EarlyCareerPayments }
    let(:eligibility) { build(:early_career_payments_eligibility) }

    context "when policy configuration year is 2021/2022" do
      before do
        @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: academic_year)
      end

      after do
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
      end
      let(:academic_year) { AcademicYear.new(2021) }

      it "generates the correct h1 text" do
        expect(helper.nqt_h1_text(claim)).to eq("Have you started your first year as a newly qualified teacher?")
      end
      it "generates the correct hint text" do
        expect(helper.nqt_hint_text(claim)).to eq("This is sometimes referred to as your induction year and is the first year after you have gained your qualified teacher status (QTS).")
      end
    end

    context "when policy configuration year is 2022/2023" do
      before do
        @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: academic_year)
      end

      after do
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
      end
      let(:academic_year) { AcademicYear.new(2022) }

      it "generates the correct h1 text" do
        expect(helper.nqt_h1_text(claim)).to eq("Have you started your first year as a newly qualified teacher or early-career teacher?")
      end

      it "generates the correct hint text" do
        expect(helper.nqt_hint_text(claim)).to eq("This is sometimes referred to as your induction period and is the first year after you have gained your qualified teacher status (QTS).")
      end
    end

    context "when policy configuration year is 2023/2024 or 2024/2025" do
      before do
        @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: academic_year)
      end

      after do
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
      end
      let(:academic_year) { AcademicYear.new(2023) }

      it "generates the correct h1 text" do
        expect(helper.nqt_h1_text(claim)).to eq("Have you completed your first year as a newly qualified teacher or early-career teacher?")
      end

      it "generates the correct hint text" do
        expect(helper.nqt_hint_text(claim)).to eq("This is sometimes referred to as your induction period and is the first year after you have gained your qualified teacher status (QTS).")
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
  end
end
