require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::DqtRecord do
  before { create(:policy_configuration, :additional_payments, current_academic_year: claim_year) }

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

  let(:claim_year) { AcademicYear.new(2022) }

  let(:eligible_itt_subject) { :mathematics }
  let(:qualification) { :postgraduate_itt }
  let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }

  let(:record) do
    OpenStruct.new(
      {
        degree_codes: degree_codes,
        itt_subjects: itt_subjects,
        itt_subject_codes: itt_subject_codes,
        itt_start_date: itt_start_date,
        qts_award_date: qts_award_date,
        qualification_name: qualification_name
      }
    )
  end

  let(:itt_subjects) { ["mathematics"] }
  let(:itt_subject_codes) { [] }
  let(:degree_codes) { [] }
  let(:itt_start_date) { Date.parse("1/9/2019") }
  let(:qts_award_date) { itt_start_date.end_of_month }
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

    shared_examples :itt_start_date_pg_allowance do |itt_calendar_year, previous_itt_year = (itt_calendar_year - 1)|
      context "with ITT start date before the 18th of August #{itt_calendar_year}" do
        let(:itt_start_date) { Date.new(itt_calendar_year, 8, 17) }

        context "when the user selected ITT start year previous to #{itt_calendar_year} (that is: #{previous_itt_year})" do
          let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(previous_itt_year)) }
          let(:eligible_scenario?) { previous_itt_year >= claim_year.start_year - 5 }

          it { eligible_scenario? ? is_expected.to(be_eligible) : is_expected.not_to(be_eligible) }
        end

        context "when the user selected ITT start year same as #{itt_calendar_year}" do
          let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(itt_calendar_year)) }

          it { is_expected.not_to be_eligible }
        end
      end

      context "with ITT start date on or after the 18th of August #{itt_calendar_year}" do
        let(:itt_start_date) { Date.new(itt_calendar_year, 8, 18) }

        context "when the user selected ITT start year previous to #{itt_calendar_year} (that is: #{previous_itt_year})" do
          let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(previous_itt_year)) }

          it { is_expected.not_to be_eligible }
        end

        context "when the user selected ITT start year same as #{itt_calendar_year}" do
          let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(itt_calendar_year)) }

          it { is_expected.to be_eligible }
        end
      end

      context "with ITT start date on or after the 1st of September #{itt_calendar_year}" do
        let(:itt_start_date) { Date.new(itt_calendar_year, 9, 1) }

        context "when the user selected ITT start year previous to #{itt_calendar_year} (that is: #{previous_itt_year})" do
          let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(previous_itt_year)) }

          it { is_expected.not_to be_eligible }
        end

        context "when the user selected ITT start year same as #{itt_calendar_year}" do
          let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(itt_calendar_year)) }

          it { is_expected.to be_eligible }
        end
      end
    end

    context "when the ITT start date falls close to the beginning of a new academic year for the PG route" do
      let(:qualification) { :postgraduate_itt }

      [AcademicYear.new(2023), AcademicYear.new(2024)].each do |current_year|
        context "with claim year #{current_year}" do
          let(:claim_year) { current_year }

          (current_year - 5...current_year).each do |itt_year|
            include_examples :itt_start_date_pg_allowance, itt_year.start_year
          end
        end
      end
    end
  end
end
