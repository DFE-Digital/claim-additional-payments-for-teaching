require "rails_helper"

describe EarlyCareerPaymentsHelper do
  let(:claim) { build(:claim, policy: policy, eligibility: eligibility, academic_year: academic_year) }
  let(:academic_year) { AcademicYear.new(2021) }
  let(:eligibility) { build(:early_career_payments_eligibility) }

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
end
