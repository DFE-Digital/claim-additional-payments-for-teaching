require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Test::TrsImporter do
  describe "#call" do
    context "when production" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "raises an error" do
        expect { subject.call }.to raise_error(RuntimeError)
      end
    end

    context "when credentials missing" do
      before do
        allow(ENV).to receive(:[]).with("DQT_API_URL").and_return(nil)
        allow(ENV).to receive(:[]).with("DQT_API_KEY").and_return(nil)
        allow(ENV).to receive(:[]).with("DQT_BASE_URL").and_return(nil)
      end

      it "raises an error" do
        expect { subject.call }.to raise_error(RuntimeError)
      end
    end

    let(:mock_resource) do
      instance_double(
        Dqt::Teacher,
        first_name: "Bob",
        surname: "Smith",
        date_of_birth: Date.new(1970, 1, 1),
        national_insurance_number: "BC234567D",
        email_address: "bob.smith@example.com",
        induction_start_date: Date.new(2012, 1, 1),
        induction_completion_date: Date.new(2013, 1, 1),
        induction_status: "???",
        qts_award_date: Date.new(2014, 1, 1),
        itt_subject_codes: [],
        itt_subjects: [],
        itt_start_date: Date.new(2015, 1, 1),
        qualification_name: "???",
        degree_codes: [],
        degree_names: [],
        active_alert?: false
      )
    end

    let(:mock_teacher) do
      instance_double(
        Dqt::TeacherResource,
        find: mock_resource
      )
    end

    let(:mock_client) do
      instance_double(
        Dqt::Client,
        teacher: mock_teacher
      )
    end

    before do
      allow(Dqt::Client).to receive(:new).and_return(mock_client)

      tempfile = Tempfile.create
      tempfile.write File.read(Policies::TargetedRetentionIncentivePayments::Test::UserPersona::FILE)
      tempfile.rewind

      stub_const("Policies::TargetedRetentionIncentivePayments::Test::UserPersona::FILE", tempfile.path)
    end

    it "updates csv" do
      subject.call

      csv = CSV.parse(File.read(Policies::TargetedRetentionIncentivePayments::Test::UserPersona::FILE), headers: true)

      expect(csv[0]["trs_first_name"]).to eql("Bob")
      expect(csv[0]["trs_last_name"]).to eql("Smith")
      expect(csv[0]["trs_date_of_birth"]).to eql("1970-01-01")
      expect(csv[0]["trs_national_insurance_number"]).to eql("BC234567D")
      expect(csv[0]["trs_email_address"]).to eql("bob.smith@example.com")
      expect(csv[0]["trs_induction_start_date"]).to eql("2012-01-01")
      expect(csv[0]["trs_induction_completion_date"]).to eql("2013-01-01")
      expect(csv[0]["trs_induction_status"]).to eql("???")
      expect(csv[0]["trs_qts_award_date"]).to eql("2014-01-01")
      expect(csv[0]["trs_itt_subject_codes"]).to eql("[]")
      expect(csv[0]["trs_itt_subjects"]).to eql("[]")
      expect(csv[0]["trs_itt_start_date"]).to eql("2015-01-01")
      expect(csv[0]["trs_qualification_name"]).to eql("???")
      expect(csv[0]["trs_degree_codes"]).to eql("[]")
      expect(csv[0]["trs_degree_names"]).to eql("[]")
      expect(csv[0]["trs_active_alert"]).to eql("false")
    end

    context "when record not found in TRS" do
      before do
        allow(mock_teacher).to receive(:find).and_return(nil)
      end

      it "raises an error" do
        expect { subject.call }.to raise_error(RuntimeError)
      end
    end
  end
end
