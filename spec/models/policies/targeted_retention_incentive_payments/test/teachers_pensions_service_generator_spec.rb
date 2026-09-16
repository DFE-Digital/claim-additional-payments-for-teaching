require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Test::TeachersPensionsServiceGenerator do
  let(:current_year) do
    AcademicYear.current.start_year
  end

  let!(:eligible_school) do
    create(
      :school,
      name: "Eligible school"
    )
  end

  let!(:ineligible_school) do
    create(
      :school,
      name: "Ineligible school"
    )
  end

  before do
    stub_const(
      "Policies::TargetedRetentionIncentivePayments::Test::UserPersona::FILE",
      file_fixture("targeted_retention_incentive_payments_personas.csv")
    )

    create(:journey_configuration, :student_loans)
  end

  describe "::import!" do
    it "persists test TPS data" do
      expect {
        perform_enqueued_jobs do
          described_class.import!
        end
      }.to change(TeachersPensionsService, :count).by(14)
    end
  end

  describe "#data" do
    it "includes all personas" do
      expect(subject.data.size).to eql 14
    end
  end

  describe "#to_csv" do
    it "generates correct headers" do
      expect(described_class.to_csv.headers).to eql(described_class::HEADERS)
    end

    it "returns correct output" do
      expected = <<STRING.gsub(/^\s+/, "")
       3013047,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013048,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013049,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013050,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013051,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013052,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1002,#{ineligible_school.establishment_number},
       3013053,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013054,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013055,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013056,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013057,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013058,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013059,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013060,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
STRING

      expect(subject.to_csv.to_s).to end_with(expected)
    end
  end

  describe "#to_file" do
    it "writes csv to disk" do
      expected = <<STRING.gsub(/^\s+/, "")
       Teacher reference number,NINO,Start Date,End Date,Employer ID,LA URN,School URN
       3013047,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013048,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013049,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013050,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013051,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013052,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1002,#{ineligible_school.establishment_number},
       3013053,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013054,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013055,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013056,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013057,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013058,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013059,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
       3013060,#{current_year}-04-05 00:00:00 +0100,#{current_year - 1}-04-06 00:00:00 +0100,,1001,#{eligible_school.establishment_number},
STRING

      file = described_class.to_file

      expect(file.read).to eql(expected)
    end
  end
end
