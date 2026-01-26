require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Test::UserPersona do
  describe ".all" do
    subject { described_class.all }

    it "returns an array of user personas defined in the CSV file" do
      expect(subject).to be_a(Array)
      expect(subject.count).to eq(14)
      expect(subject).to all(be_a(described_class))
    end
  end

  describe "#initialize" do
    subject { described_class.new(csv_row) }

    let(:csv_row) do
      {
        "School name" => "Test School",
        "First name" => "John",
        "Last name" => "Smith",
        "Date of birth" => "01/01/1990",
        "NINO" => "AB123456C",
        "ITT subject claimed" => "Mathematics",
        "ITT year" => "2024/2025",
        "TRN" => "1234567",
        "Teaching subject" => "Maths",
        "Expected result" => "Eligible"
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

  describe "TRS data methods" do
    subject { described_class.new(csv_row) }

    let(:csv_row) do
      {
        "School name" => "Test School",
        "First name" => "John",
        "Last name" => "Smith",
        "Date of birth" => "01/01/1990",
        "NINO" => "AB123456C",
        "ITT subject claimed" => "Mathematics",
        "ITT year" => "2024/2025",
        "TRN" => "1234567",
        "Teaching subject" => "Maths",
        "Expected result" => "Eligible"
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
            "School name" => "Test School",
            "First name" => "John",
            "Last name" => "Smith",
            "Date of birth" => "01/01/1990",
            "NINO" => "AB123456C",
            "ITT subject claimed" => "Art",
            "ITT year" => "2024/2025",
            "TRN" => "1234567",
            "Teaching subject" => "Art",
            "Expected result" => "Ineligible"
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
