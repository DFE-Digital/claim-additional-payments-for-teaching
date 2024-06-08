require "rails_helper"

describe AdditionalPaymentsHelper do
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
    before { create(:journey_configuration, :additional_payments) }
    let(:ecp_claim) { create(:claim, :first_lup_claim_year, policy: Policies::EarlyCareerPayments, eligibility: ecp_eligibility) }
    let(:lup_claim) { create(:claim, :first_lup_claim_year, policy: Policies::LevellingUpPremiumPayments, eligibility: lup_eligibility) }
    let(:qualification) { nil }

    let(:shim) do
      Journeys::AdditionalPaymentsForTeaching::ClaimJourneySessionShim.new(
        journey_session: journey_session,
        current_claim: current_claim
      )
    end

    let(:journey_session) do
      create(:additional_payments_session, answers: answers)
    end

    let(:current_claim) do
      CurrentClaim.new(claims: [ecp_claim, lup_claim])
    end

    subject do
      helper.eligible_itt_subject_translation(
        shim.answers,
        JourneySubjectEligibilityChecker.selectable_subject_symbols(shim.answers)
      )
    end

    context "trainee teacher" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :trainee_teacher) }

      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_eligible,
          :trainee_teacher
        )
      end

      it { is_expected.to eq("Which subject are you currently doing your initial teacher training (ITT) in?") }
    end

    context "qualified teacher" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_eligible,
          itt_academic_year: itt_year,
          qualification: qualification
        )
      end

      context "one option" do
        let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }

        context "undergraduate" do
          let(:qualification) { :undergraduate_itt }

          it { is_expected.to eq("Did you do your undergraduate initial teacher training (ITT) in mathematics?") }
        end

        context "postgraduate" do
          let(:qualification) { :postgraduate_itt }

          it { is_expected.to eq("Did you do your postgraduate initial teacher training (ITT) in mathematics?") }
        end

        context "overseas" do
          let(:qualification) { :overseas_recognition }

          it { is_expected.to eq("Did you do your teaching qualification in mathematics?") }
        end

        context "assessment" do
          let(:qualification) { :assessment_only }

          it { is_expected.to eq("Did you do your assessment in mathematics?") }
        end
      end

      context "multiple options" do
        let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }

        context "undergraduate" do
          let(:qualification) { :undergraduate_itt }

          it { is_expected.to eq("Which subject did you do your undergraduate initial teacher training (ITT) in?") }
        end

        context "postgraduate" do
          let(:qualification) { :postgraduate_itt }

          it { is_expected.to eq("Which subject did you do your postgraduate initial teacher training (ITT) in?") }
        end

        context "overseas" do
          let(:qualification) { :overseas_recognition }

          it { is_expected.to eq("Which subject did you do your teaching qualification in?") }
        end

        context "assessment" do
          let(:qualification) { :assessment_only }

          it { is_expected.to eq("Which subject did you do your assessment in?") }
        end
      end
    end
  end
end
