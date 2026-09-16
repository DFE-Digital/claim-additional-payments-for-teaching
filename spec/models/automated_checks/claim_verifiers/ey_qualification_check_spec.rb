require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::EyQualificationCheck do
  subject { described_class.new(claim: claim) }

  let(:claim) do
    create(
      :claim, :submitted,
      policy: Policies::EarlyYearsPayments,
      date_of_birth: Date.new(1990, 1, 15),
      postcode: "SW1A 1AA",
      national_insurance_number: "AB123456C",
      email_address: "teacher@example.com",
      first_name: "John",
      surname: "Smith",
      dqt_teacher_status:
    )
  end

  let(:dqt_teacher_status) do
    {
      "routesToProfessionalStatuses" => [
        {
          "routeToProfessionalStatusId" => "some-guid",
          "routeToProfessionalStatusType" => {
            "routeToProfessionalStatusTypeId" => "some-guid",
            "name" => "EYTS ITT Migrated",
            "professionalStatusType" => "EarlyYearsTeacherStatus"
          },
          "status" => "Holds",
          "holdsFrom" => "2014-02-13",
          "trainingStartDate" => "2013-09-13",
          "trainingEndDate" => "2014-02-13"
        },
        {
          "routeToProfessionalStatusId" => "some-guid",
          "routeToProfessionalStatusType" => {
            "routeToProfessionalStatusTypeId" => "some-guid",
            "name" => "HEI",
            "professionalStatusType" => "QualifiedTeacherStatus"
          },
          "status" => "Failed",
          "holdsFrom" => nil,
          "trainingStartDate" => "2008-09-13",
          "trainingEndDate" => "2011-06-13"
        }
      ],
      "alerts" => [],
      "qtlsStatus" => "None"
    }
  end

  describe "#perform" do
    context "when a task already exists" do
      before { create(:task, name: described_class::TASK_NAME, claim: claim) }

      it "does not create a new task" do
        expect { subject.perform }.not_to change { claim.tasks.count }
      end
    end

    it "creates a task" do
      expect { subject.perform }.to change { claim.tasks.count }.by(1)
    end

    it "creates a note containing qualifications" do
      expect { subject.perform }.to change { claim.notes.count }

      note = Note.last

      expect(note.body.split("\n")[0]).to eql("[DQT Qualifications]")
      expect(note.body.split("\n")[1]).to eql("<pre>")
      expect(note.body.split("\n")[2]).to eql("Qualification name: EYTS ITT Migrated")
      expect(note.body.split("\n")[3]).to eql("Qualification status: Holds")
      expect(note.body.split("\n")[4]).to eql("Qualification start date: 2013-09-13")
      expect(note.body.split("\n")[5]).to eql("Qualification award date: 2014-02-13")
      expect(note.body.split("\n")[6]).to eql("</pre>")
      expect(note.body.split("\n")[7]).to eql("<pre>")
      expect(note.body.split("\n")[8]).to eql("Qualification name: HEI")
      expect(note.body.split("\n")[9]).to eql("Qualification status: Failed")
      expect(note.body.split("\n")[10]).to eql("Qualification start date: 2008-09-13")
      expect(note.body.split("\n")[11]).to eql("Qualification award date: ")
      expect(note.body.split("\n")[12]).to eql("</pre>")
    end
  end
end
