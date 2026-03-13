require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Test::UserPersona do
  describe "::all" do
    subject { described_class.all }

    it "returns an array of user personas defined in the CSV file" do
      expect(subject).to be_a(Array)
      expect(subject.count).to eq(14)
      expect(subject).to all(be_a(described_class))
    end
  end

  describe "::import!" do
    before do
      allow(Policies::TargetedRetentionIncentivePayments::Test::SchoolImporter).to receive(:run)
      allow(Policies::TargetedRetentionIncentivePayments::Test::StriAwardsGenerator).to receive(:import!)
      allow(Policies::TargetedRetentionIncentivePayments::Test::TeachersPensionsServiceGenerator).to receive(:import!)
      allow(Policies::TargetedRetentionIncentivePayments::Test::SchoolWorkforceCensusGenerator).to receive(:import!)
    end

    it "calls various importers" do
      described_class.import!

      expect(Policies::TargetedRetentionIncentivePayments::Test::SchoolImporter).to have_received(:run)
      expect(Policies::TargetedRetentionIncentivePayments::Test::StriAwardsGenerator).to have_received(:import!)
      expect(Policies::TargetedRetentionIncentivePayments::Test::TeachersPensionsServiceGenerator).to have_received(:import!)
      expect(Policies::TargetedRetentionIncentivePayments::Test::SchoolWorkforceCensusGenerator).to have_received(:import!)
    end
  end

  describe "#initialize" do
    subject { described_class.new(csv_row) }

    let(:csv_row) do
      {
        "school_name" => "Test School",
        "first_name" => "John",
        "last_name" => "Smith",
        "date_of_birth" => "01/01/1990",
        "national_insurance_number" => "AB123456C",
        "itt_subject_claimed" => "Mathematics",
        "itt_year" => "2024/2025",
        "teacher_reference_number" => "1234567",
        "teaching_subject" => "Maths",
        "expected_result" => "Eligible"
      }
    end

    it "maps the school name" do
      expect(subject.school_name).to eq("Test School")
    end

    it "maps the teacher reference number" do
      expect(subject.teacher_reference_number).to eq("1234567")
    end

    it "maps the first name" do
      expect(subject.first_name).to eq("John")
    end

    it "maps the last name" do
      expect(subject.last_name).to eq("Smith")
    end

    it "maps the date of birth" do
      expect(subject.date_of_birth).to eq("01/01/1990")
    end

    it "maps the national insurance number" do
      expect(subject.national_insurance_number).to eq("AB123456C")
    end

    it "maps the ITT year as an AcademicYear" do
      expect(subject.itt_year).to eq(AcademicYear.new("2024/2025"))
    end
  end

  describe "#to_csv_row" do
    subject { described_class.new(csv_row) }

    let(:csv_row) do
      {
        "claim_year" => "2025",
        "expected_result" => "Eligible",
        "notes" => "some notes",
        "school_name" => "Test School",
        "supply_teacher" => "no",
        "full_term_contract" => "yes",
        "employed_directly_by_school" => "yes",
        "subject_to_poor_performance_measures" => "no",
        "itt_year" => "2024/2025",
        "more_than_50_of_hours_teaching_eligible_subjects" => "yes",
        "teaching_subject" => "Maths",
        "itt_subject_claimed" => "Mathematics",
        "degree_subject" => "English",
        "trainee" => "no",
        "first_name" => "John",
        "last_name" => "Smith",
        "teacher_reference_number" => "1234567",
        "date_of_birth" => "01/01/1990",
        "national_insurance_number" => "AB123456C",
        "trs_first_name" => "Bob",
        "trs_last_name" => "Doe",
        "trs_date_of_birth" => "02/02/1970",
        "trs_national_insurance_number" => "AB123456D",
        "trs_email_address" => "bob.doe@example.com",
        "trs_induction_start_date" => "01/01/2010",
        "trs_induction_completion_date" => "01/01/2011",
        "trs_induction_status" => "???",
        "trs_qts_award_date" => "01/01/2013",
        "trs_itt_subject_codes" => "???",
        "trs_itt_subjects" => "???",
        "trs_itt_start_date" => "01/01/2012",
        "trs_qualification_name" => "???",
        "trs_degree_codes" => "???",
        "trs_degree_names" => "???",
        "trs_active_alert" => "no"
      }
    end

    it "converts current record to csv row" do
      expect(subject.to_csv_row).to eql(csv_row.values)
    end
  end

  describe "TRS data methods" do
    subject { described_class.new(csv_row) }

    let(:csv_row) do
      {
        "school_name" => "Test School",
        "first_name" => "John",
        "last_name" => "Smith",
        "date_of_birth" => "01/01/1990",
        "national_insurance_number" => "AB123456C",
        "itt_subject_claimed" => "Mathematics",
        "itt_year" => "2024/2025",
        "teacher_reference_number" => "1234567",
        "teaching_subject" => "Maths",
        "expected_result" => "Eligible"
      }
    end

    describe "#qts_date" do
      it "returns start of autumn term 3 years ago" do
        expect(subject.qts_date).to eq(AcademicYear.for(Date.today - 3.years).start_of_autumn_term)
      end
    end

    describe "#route_type" do
      it "returns undergraduate_itt" do
        expect(subject.route_type).to eq(:undergraduate_itt)
      end
    end

    describe "#induction_status" do
      it "returns Pass" do
        expect(subject.induction_status).to eq("Pass")
      end
    end

    describe "#itt_start_date" do
      it "returns start of autumn term for ITT year" do
        expect(subject.itt_start_date).to eq(AcademicYear.new("2024/2025").start_of_autumn_term)
      end
    end

    describe "#itt_subject" do
      context "when ITT subject is eligible" do
        it "returns the matching TRS subject" do
          expect(subject.itt_subject).to be_present
          expect(subject.itt_subject).not_to eq("Random ineligible ITT subject")
        end
      end

      context "when ITT subject is not eligible" do
        let(:csv_row) do
          {
            "school_name" => "Test School",
            "first_name" => "John",
            "last_name" => "Smith",
            "date_of_birth" => "01/01/1990",
            "national_insurance_number" => "AB123456C",
            "itt_subject_claimed" => "Art",
            "itt_year" => "2024/2025",
            "teacher_reference_number" => "1234567",
            "teaching_subject" => "Art",
            "expected_result" => "Ineligible"
          }
        end

        it "returns a random ineligible subject" do
          expect(subject.itt_subject).to eq("Random ineligible ITT subject")
        end
      end
    end

    describe "#itt_qualification_type" do
      it "returns a valid qualification type for the route" do
        expect(subject.itt_qualification_type).to be_present
      end
    end

    describe "#active_alert?" do
      it "returns false" do
        expect(subject.active_alert?).to eq(false)
      end
    end
  end
end
