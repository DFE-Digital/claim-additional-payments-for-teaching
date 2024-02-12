require "rails_helper"

RSpec.describe TeachersPensionsService do
  let(:la_code) { 123 }
  let(:establishment_number) { 4567 }
  let(:claim) { build(:claim, created_at: Time.zone.now) }
  let(:local_authority) { create(:local_authority, code: la_code) }
  let(:school) { create(:school, local_authority:, establishment_number:) }
  let(:la_urn) { local_authority.code }
  let(:school_urn) { school.establishment_number }
  let(:teacher_reference_number) { claim.teacher_reference_number }
  let(:start_date) { end_date - 1.week }

  describe ".has_recent_tps_school?" do
    subject(:has_recent_tps_school) { described_class.has_recent_tps_school?(claim) }

    context "when there is a matching TPS record" do
      let(:end_date) { Time.zone.now - 1.day }
      let!(:tps_record) { create(:teachers_pensions_service, teacher_reference_number:, la_urn:, school_urn:, start_date:, end_date:) }

      it { is_expected.to be true }
    end

    context "when there is no matching TPS record" do
      it { is_expected.to be false }
    end
  end

  describe ".recent_tps_school" do
    subject(:recent_tps_school) { described_class.recent_tps_school(claim) }

    context "when there is a TPS record matching the TRN" do
      let!(:closed_school) { create(:school, :closed, local_authority:, establishment_number:) }
      let!(:tps_record) { create(:teachers_pensions_service, teacher_reference_number:, la_urn:, school_urn:, start_date:, end_date:) }

      context "when the end date is within the permitted window" do
        let(:end_date) { Time.zone.now - 1.day }
        let(:start_date) { end_date - 1.week }

        context "when a school matches the LA URN and School URN" do
          it { is_expected.to eq(school) }

          context "when there is more than one TPS record" do
            let(:old_school) { create(:school) }
            let!(:old_tps_record) { create(:teachers_pensions_service, teacher_reference_number:, la_urn: old_school.local_authority.code, school_urn: old_school.establishment_number, start_date: Time.zone.now - 2.weeks, end_date: Time.zone.now - 1.week) }

            it { is_expected.to eq(school) }
          end
        end

        context "when no school matches" do
          let(:la_urn) { 890 }
          it { is_expected.to be_nil }
        end

        context "when the School URN is nil" do
          let(:school_urn) { nil }
          it { is_expected.to be_nil }
        end
      end

      context "when the end date is beyond the permitted window" do
        let(:end_date) { (Time.zone.now - described_class::RECENT_TPS_FULL_MONTHS).beginning_of_month - 1.day }
        it { is_expected.to be_nil }
      end
    end
  end

  describe ".tps_school_for_student_loan_in_previous_financial_year" do
    let(:previous_academic_year) { AcademicYear.current - 1 }
    let!(:eligible_school) { create(:school, :student_loans_eligible) }
    let!(:eligible_school2) { create(:school, :student_loans_eligible) }
    let!(:ineligible_school) { create(:school, :student_loans_ineligible) }
    let!(:ineligible_school2) { create(:school, :student_loans_ineligible) }
    let(:trn) { "1234567" }
    let(:claim) { create(:claim, teacher_reference_number: trn) }

    context "previous financial year has eligible school and ineligible school" do
      it "returns most recent eligible school" do
        # least recent eligible
        beginning_of_month = Date.new(previous_academic_year.start_year, 9, 1)
        end_of_month = Date.new(previous_academic_year.start_year, 9, 30)
        create(:teachers_pensions_service, teacher_reference_number: trn, start_date: beginning_of_month, end_date: end_of_month, school_urn: eligible_school.establishment_number, la_urn: eligible_school.local_authority.code)

        # most recent eligible
        beginning_of_month = Date.new(previous_academic_year.start_year, 10, 1)
        end_of_month = Date.new(previous_academic_year.start_year, 10, 31)
        create(:teachers_pensions_service, teacher_reference_number: trn, start_date: beginning_of_month, end_date: end_of_month, school_urn: eligible_school2.establishment_number, la_urn: eligible_school2.local_authority.code)

        # most most recent, but ineligible
        beginning_of_month = Date.new(previous_academic_year.start_year, 11, 1)
        end_of_month = Date.new(previous_academic_year.start_year, 11, 30)
        create(:teachers_pensions_service, teacher_reference_number: trn, start_date: beginning_of_month, end_date: end_of_month, school_urn: ineligible_school.establishment_number, la_urn: ineligible_school.local_authority.code)

        expect(described_class.tps_school_for_student_loan_in_previous_financial_year(claim)).to eq eligible_school2
      end
    end

    context "previous financial year has ineligible schools only" do
      it "returns the most recent one" do
        # least recent ineligible
        beginning_of_month = Date.new(previous_academic_year.start_year, 9, 1)
        end_of_month = Date.new(previous_academic_year.start_year, 9, 30)
        create(:teachers_pensions_service, teacher_reference_number: trn, start_date: beginning_of_month, end_date: end_of_month, school_urn: ineligible_school.establishment_number, la_urn: ineligible_school.local_authority.code)

        # most recent ineligible
        beginning_of_month = Date.new(previous_academic_year.start_year, 10, 1)
        end_of_month = Date.new(previous_academic_year.start_year, 10, 31)
        create(:teachers_pensions_service, teacher_reference_number: trn, start_date: beginning_of_month, end_date: end_of_month, school_urn: ineligible_school2.establishment_number, la_urn: ineligible_school2.local_authority.code)

        expect(described_class.tps_school_for_student_loan_in_previous_financial_year(claim)).to eq ineligible_school2
      end
    end

    context "previous financial year no tps records" do
      it "returns nil" do
        expect(described_class.tps_school_for_student_loan_in_previous_financial_year(claim)).to be_nil
      end
    end
  end
end
