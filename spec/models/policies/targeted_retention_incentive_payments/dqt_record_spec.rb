require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::DqtRecord do
  before { create(:journey_configuration, :targeted_retention_incentive_payments, current_academic_year: claim_year) }

  subject(:dqt_record) { described_class.new(record, claim) }

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

  let(:claim) do
    OpenStruct.new(
      {
        qualification: qualification,
        itt_academic_year: itt_academic_year,
        eligible_itt_subject: eligible_itt_subject
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

  describe "#eligible_degree_code?" do
    subject(:result) { dqt_record.eligible_degree_code? }

    context "with a valid code" do
      let(:degree_codes) { [described_class::ELIGIBLE_CODES.sample] }
      it { is_expected.to be true }
    end

    context "with an invalid code" do
      let(:degree_codes) { ["invalid"] }
      it { is_expected.to be false }
    end

    context "with a valid and invalid code" do
      let(:degree_codes) { ["invalid", described_class::ELIGIBLE_CODES.sample] }
      it { is_expected.to be true }
    end

    context "with no code" do
      let(:degree_codes) { [] }
      it { is_expected.to be false }
    end
  end

  describe "#eligible_itt_subject_for_claim" do
    let(:eligible_subjects) { [:computing] }

    before do
      allow(Policies::TargetedRetentionIncentivePayments).to receive(:fixed_subject_symbols)
        .and_return(eligible_subjects)
    end

    let(:record) { OpenStruct.new(itt_subjects:) }
    let(:claim_academic_year) { AcademicYear.new(2023) }

    context "when the record returns a valid subject" do
      let(:itt_subjects) { ["computer science"] }

      it "returns the valid subject" do
        expect(dqt_record.eligible_itt_subject_for_claim).to eq(:computing)
      end
    end

    context "when the record returns multiple valid subjects" do
      let(:itt_subjects) { ["Applied Mathematics", "Chemical Physics"] }
      let(:eligible_subjects) { [:physics, :mathematics, :computing] }

      it "returns the first valid subject" do
        expect(dqt_record.eligible_itt_subject_for_claim).to eq(:mathematics)
      end
    end

    context "when the record returns an invalid subject" do
      let(:itt_subjects) { ["test"] }

      it "returns none_of_the_above" do
        expect(dqt_record.eligible_itt_subject_for_claim).to eq(:none_of_the_above)
      end
    end

    context "when the record returns valid and invalid subjects" do
      let(:itt_subjects) { ["invalid", "mathematics", "test", "physics"] }

      it "returns the first valid subject" do
        expect(dqt_record.eligible_itt_subject_for_claim).to eq(:mathematics)
      end
    end

    context "when the record returns empty" do
      let(:itt_subjects) { [] }

      it "returns the first valid subject" do
        expect(dqt_record.eligible_itt_subject_for_claim).to be_nil
      end
    end
  end

  describe "#itt_academic_year_for_claim" do
    before do
      allow(Policies::TargetedRetentionIncentivePayments).to(
        receive(:selectable_itt_years_for_claim_year).and_return(eligible_years)
      )
    end

    let(:record) do
      OpenStruct.new(
        qualification_name: "BA",
        qts_award_date:
      )
    end

    let(:year) { 2023 }
    let(:claim_year) { AcademicYear.new(year) }

    let(:eligible_years) { (AcademicYear.new(year - 5)...AcademicYear.new(year)).to_a }

    context "when the record returns an eligible date" do
      let(:qts_award_date) { Date.new(year, 1, 1) }

      it "returns the academic year" do
        expect(dqt_record.itt_academic_year_for_claim).to eq(AcademicYear.for(qts_award_date))
      end
    end

    context "when the record returns an ineligible date" do
      let(:qts_award_date) { Date.new(year - 10, 12, 1) }

      it "returns a blank academic year" do
        expect(dqt_record.itt_academic_year_for_claim).to eq(AcademicYear.new)
      end
    end

    context "when the record returns nil" do
      let(:qts_award_date) { nil }

      it "returns nil" do
        expect(dqt_record.itt_academic_year_for_claim).to be_nil
      end
    end
  end

  describe "#has_no_data_for_claim?" do
    context "when one or more required data are present" do
      before { allow(dqt_record).to receive(:eligible_itt_subject_for_claim).and_return("test") }

      it { is_expected.not_to be_has_no_data_for_claim }
    end

    context "when all required data are not present" do
      before do
        allow(dqt_record).to receive(:eligible_itt_subject_for_claim).and_return(nil)
        allow(dqt_record).to receive(:itt_academic_year_for_claim).and_return(nil)
        allow(dqt_record).to receive(:route_into_teaching).and_return(nil)
        allow(dqt_record).to receive(:eligible_degree_code?).and_return(nil)
      end

      it { is_expected.to be_has_no_data_for_claim }
    end
  end
end
