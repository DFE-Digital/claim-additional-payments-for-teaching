require "rails_helper"

RSpec.describe AutomatedChecks::DQTReportConsumer do
  let(:dqt_report_consumer) { described_class.new(file, admin_user) }
  let(:file) { example_dqt_report_csv }
  let(:admin_user) { build(:dfe_signin_user) }
  let!(:claim_with_eligible_dqt_record) { claim_from_example_dqt_report(:eligible_claim_with_matching_data) }
  let!(:claim_without_dqt_record) { claim_from_example_dqt_report(:claim_without_dqt_record) }
  let!(:claim_with_ineligible_dqt_record) { claim_from_example_dqt_report(:claim_with_ineligible_dqt_record) }
  let!(:claim_with_decision) { claim_from_example_dqt_report(:claim_with_decision) }
  let!(:claim_with_qualification_task) { claim_from_example_dqt_report(:claim_with_qualification_task) }
  let!(:existing_qualification_task) { claim_with_qualification_task.tasks.find_by!(name: "qualifications") }

  describe "#ingest" do
    it "creates a qualification task for claims that are eligible" do
      dqt_report_consumer.ingest

      new_qualication_task = claim_with_eligible_dqt_record.tasks.find_by!(name: "qualifications")
      expect(dqt_report_consumer.completed_tasks).to eq(1)
      expect(dqt_report_consumer.total_records).to eq(7)
      expect(new_qualication_task.passed).to eq(true)
      expect(new_qualication_task.manual).to eq(false)
      expect(new_qualication_task.created_by).to eq(admin_user)
    end

    it "doesn’t create a qualification task when the claim already has a decision" do
      dqt_report_consumer.ingest

      expect(claim_with_decision.tasks.find_by(name: "qualifications")).to be_nil
    end

    it "doesn’t create a qualification task when the claim already has one" do
      dqt_report_consumer.ingest

      expect(claim_with_qualification_task.tasks.find_by(name: "qualifications")).to eql(existing_qualification_task)
    end

    context "when a malformed CSV is uploaded" do
      let(:file) do
        tempfile = Tempfile.new
        tempfile.write("Malformed CSV\"")
        tempfile.rewind
        tempfile
      end

      it "doesn’t do anything and sets an error" do
        expect(dqt_report_consumer.ingest).to be_falsey
        expect(dqt_report_consumer.errors).to eql(["The selected file must be a CSV"])
      end
    end

    context "when the CSV doesn’t have all the expected headers" do
      let(:file) do
        tempfile = Tempfile.new
        tempfile.write("dfeta text1,dfeta text2,dfeta trn,dfeta qtsdate,fullname,birthdate\n")
        tempfile.rewind
        tempfile
      end

      it "doesn’t do anything and sets an error" do
        expect(dqt_report_consumer.ingest).to be_falsey
        expect(dqt_report_consumer.errors).to eql(["The selected file is missing some expected columns: dfeta ninumber, HESubject1Value, HESubject2Value, HESubject3Value, ITTSub1Value, ITTSub2Value, ITTSub3Value"])
      end
    end
  end
end
