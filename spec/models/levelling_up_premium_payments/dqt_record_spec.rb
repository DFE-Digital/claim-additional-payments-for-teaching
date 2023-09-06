require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::DqtRecord do
  before { create(:policy_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }

  subject(:dqt_record) do
    described_class.new(
      record,
      claim
    )
  end

  let(:claim) do
    build(
      :claim,
      policy: LevellingUpPremiumPayments,
      academic_year: AcademicYear.new(2022),
      eligibility: eligibility
    )
  end

  let(:eligibility) do
    build(
      :levelling_up_premium_payments_eligibility,
      :eligible,
      eligible_itt_subject: eligible_itt_subject,
      qualification: qualification,
      itt_academic_year: itt_academic_year
    )
  end

  let(:eligible_itt_subject) { :mathematics }
  let(:qualification) { :postgraduate_itt }
  let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }

  let(:record) do
    OpenStruct.new(
      {
        degree_codes: degree_codes,
        itt_subjects: itt_subjects,
        itt_subject_codes: itt_subject_codes,
        itt_start_date: Date.parse("1/9/2019"),
        qts_award_date: qts_award_date,
        qualification_name: qualification_name
      }
    )
  end

  let(:itt_subjects) { ["mathematics"] }
  let(:itt_subject_codes) { [] }
  let(:degree_codes) { [] }
  let(:qts_award_date) { Date.parse("30/9/2019") }
  let(:qualification_name) { "Postgraduate Certificate in Education" }

  describe "#eligible?" do
    context "without ITT subject code" do
      let(:itt_subject_codes) { [] }

      context "without ITT subject name" do
        let(:itt_subjects) { [] }

        it { is_expected.not_to be_eligible }
      end

      context "with an invalid ITT subject name" do
        let(:itt_subjects) { ["biology"] }

        it { is_expected.not_to be_eligible }
      end

      context "with a valid ITT subject name" do
        let(:itt_subjects) { ["mathematics"] }

        it { is_expected.to be_eligible }

        context "with an invalid degree code" do
          let(:degree_codes) { ["X100"] }

          it { is_expected.to be_eligible }
        end

        context "with a valid degree code" do
          let(:degree_codes) { ["I100"] }

          it { is_expected.to be_eligible }
        end
      end

      context "with any valid ITT subject name" do
        let(:itt_subjects) { ["mathematics", "biology"] }

        it { is_expected.to be_eligible }
      end
    end

    context "with an invalid ITT subject code" do
      let(:itt_subject_codes) { ["B100"] }

      context "without ITT subject name" do
        let(:itt_subjects) { [] }

        it { is_expected.not_to be_eligible }
      end

      context "with an invalid ITT subject name" do
        let(:itt_subjects) { ["biology"] }

        it { is_expected.not_to be_eligible }
      end

      context "with a valid ITT subject name" do
        let(:itt_subjects) { ["mathematics"] }

        it { is_expected.not_to be_eligible }

        context "with an invalid degree code" do
          let(:degree_codes) { ["X100"] }

          it { is_expected.not_to be_eligible }
        end

        context "with a valid degree code" do
          let(:degree_codes) { ["I100"] }

          it { is_expected.to be_eligible }
        end
      end

      context "with any valid ITT subject name" do
        let(:itt_subjects) { ["mathematics", "biology"] }

        it { is_expected.not_to be_eligible }
      end
    end

    context "with valid ITT code" do
      let(:itt_subject_codes) { ["G100"] }

      it { is_expected.to be_eligible }
    end

    context "with valid degree code" do
      let(:degree_codes) { ["I100"] }

      it { is_expected.to be_eligible }
    end

    context "with invalid ITT and valid degree codes" do
      let(:itt_subject_codes) { ["123"] }
      let(:degree_codes) { ["I100"] }

      it { is_expected.to be_eligible }
    end

    context "with valid ITT and degree codes" do
      let(:itt_subject_codes) { ["G100"] }
      let(:degree_codes) { ["I100"] }

      it { is_expected.to be_eligible }

      context "when the selected subject doesn't match" do
        let(:eligible_itt_subject) { :physics }

        it { is_expected.not_to be_eligible }
      end

      context "when the selected qualification doesn't match" do
        let(:qualification) { :undergraduate_itt }

        it { is_expected.not_to be_eligible }
      end

      context "when the selected year doesn't match" do
        let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }

        it { is_expected.not_to be_eligible }
      end

      context "when the subject is 'None of the above'" do
        let(:eligible_itt_subject) { :none_of_the_above }

        context "when the claimant has a valid ITT subject" do
          it { is_expected.not_to be_eligible }
        end

        context "when the claimant doesn't have a valid ITT subject" do
          let(:itt_subjects) { ["law"] }

          it { is_expected.to be_eligible }
        end
      end
    end

    context "when QTS award date is before ITT start date" do
      let(:itt_subject_codes) { ["G100"] }
      let(:qts_award_date) { Date.parse("30/8/2019") }

      it { is_expected.not_to be_eligible }

      context "when route into teaching is different than postgrad" do
        let(:qualification) { :undergraduate_itt }
        let(:qualification_name) { "BA" }
        let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2018)) }

        it { is_expected.to be_eligible }
      end
    end
  end
end
