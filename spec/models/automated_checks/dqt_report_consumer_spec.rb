require "rails_helper"

RSpec.describe AutomatedChecks::DqtReportConsumer do
  let(:dqt_report_consumer) { described_class.new(file, admin_user) }
  let(:file) { example_dqt_report_csv }
  let(:admin_user) { build(:dfe_signin_user) }
  let!(:claim_with_eligible_dqt_record) { claim_from_example_dqt_report(:eligible_claim_with_matching_data) }
  let!(:eligible_claim_with_non_matching_birthdate) { claim_from_example_dqt_report(:eligible_claim_with_non_matching_birthdate) }
  let!(:eligible_claim_with_non_matching_surname) { claim_from_example_dqt_report(:eligible_claim_with_non_matching_surname) }
  let!(:claim_without_dqt_record) { claim_from_example_dqt_report(:claim_without_dqt_record) }
  let!(:claim_with_ineligible_dqt_record) { claim_from_example_dqt_report(:claim_with_ineligible_dqt_record) }
  let!(:claim_with_decision) { claim_from_example_dqt_report(:claim_with_decision) }
  let!(:claim_with_qualification_task) { claim_from_example_dqt_report(:claim_with_qualification_task) }
  let!(:existing_qualification_task) { claim_with_qualification_task.tasks.find_by!(name: "qualifications") }
  let!(:unverified_claim_with_matching_identity_data) { claim_from_example_dqt_report(:unverified_claim_with_matching_identity_data) }

  describe "#ingest" do
    before { dqt_report_consumer.ingest }

    it "sets attributes that report the number of tasks automatically completed and the number of claims checked" do
      expect(dqt_report_consumer.completed_tasks).to eq(5)
      expect(dqt_report_consumer.total_claims_checked).to eq(7)
    end

    it "creates a qualification task for claims that are eligible" do
      new_qualication_task = claim_with_eligible_dqt_record.tasks.find_by!(name: "qualifications")
      expect(new_qualication_task.passed).to eq(true)
      expect(new_qualication_task.manual).to eq(false)
      expect(new_qualication_task.created_by).to eq(admin_user)

      new_qualication_task = eligible_claim_with_non_matching_birthdate.tasks.find_by!(name: "qualifications")
      expect(new_qualication_task.passed).to eq(true)
      expect(new_qualication_task.manual).to eq(false)
      expect(new_qualication_task.created_by).to eq(admin_user)

      new_qualication_task = eligible_claim_with_non_matching_surname.tasks.find_by!(name: "qualifications")
      expect(new_qualication_task.passed).to eq(true)
      expect(new_qualication_task.manual).to eq(false)
      expect(new_qualication_task.created_by).to eq(admin_user)
    end

    it "creates an identity_confirmation task for claims where the surname and DOB in the record matches the claim" do
      new_id_confirmation_task = claim_with_eligible_dqt_record.tasks.find_by!(name: "identity_confirmation")
      expect(new_id_confirmation_task.passed).to eq(true)
      expect(new_id_confirmation_task.manual).to eq(false)
      expect(new_id_confirmation_task.created_by).to eq(admin_user)
    end

    it "doesn‘t create an identity_confirmation task for claims that are unverified" do
      qualification_task = unverified_claim_with_matching_identity_data.tasks.find_by!(name: "qualifications")
      expect(qualification_task.passed).to eq(true)

      expect(unverified_claim_with_matching_identity_data.tasks.find_by(name: "identity_confirmation")).to be_nil
    end

    it "doesn't create an identity_confirmation task if either the surname or DOB does not match" do
      expect(eligible_claim_with_non_matching_birthdate.tasks.find_by(name: "identity_confirmation")).to be_nil
      expect(eligible_claim_with_non_matching_surname.tasks.find_by(name: "identity_confirmation")).to be_nil
    end

    it "doesn’t create a qualification task when the claim already has a decision" do
      expect(claim_with_decision.tasks.find_by(name: "qualifications")).to be_nil
    end

    it "doesn’t create a qualification task when the claim already has one" do
      expect(claim_with_qualification_task.tasks.find_by(name: "qualifications")).to eql(existing_qualification_task)
    end
  end

  context "when given a malformed CSV file" do
    let(:file) do
      tempfile = Tempfile.new
      tempfile.write("Malformed CSV\"")
      tempfile.rewind
      tempfile
    end

    it "reports an appropriate error mesage" do
      expect(dqt_report_consumer.errors).to eql(["The selected file must be a CSV"])
    end
  end

  context "when given a CSV without the expected headers" do
    let(:file) do
      tempfile = Tempfile.new
      tempfile.write("dfeta text1,dfeta text2,dfeta trn,dfeta qtsdate,fullname,birthdate\n")
      tempfile.rewind
      tempfile
    end

    it "reports the misssing columns in the error message" do
      expect(dqt_report_consumer.errors).to eql(["The selected file is missing some expected columns: dfeta ninumber, HESubject1Value, HESubject2Value, HESubject3Value, ITTSub1Value, ITTSub2Value, ITTSub3Value"])
    end
  end
end
