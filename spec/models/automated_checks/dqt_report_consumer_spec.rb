require "rails_helper"

RSpec.describe AutomatedChecks::DQTReportConsumer do
  let(:dqt_report_consumer) { described_class.new(file, admin_user) }
  let(:csv) do
    <<~CSV
      dfeta text1,dfeta text2,dfeta trn,fullname,birthdate,dfeta ninumber,dfeta qtsdate,dfeta he hesubject1idname,dfeta he hesubject2idname,dfeta he hesubject3idname,HESubject1Value,HESubject2Value,HESubject3Value,dfeta subject1idname,dfeta subject2idname,dfeta subject3idname,ITTSub1Value,ITTSub2Value,ITTSub3Value
      1234567,#{claim.reference},1234567,Fred Smith,23/8/1990,QQ123456C,#{qts_date},Mathematics,,,#{postgraduate_degree_code},,,Mathematics,,,#{itt_subject_code},,
    CSV
  end
  let(:file) do
    tempfile = Tempfile.new
    tempfile.write(csv)
    tempfile.rewind
    tempfile
  end
  let(:admin_user) { build(:dfe_signin_user) }
  let(:claim) do
    create(:claim, :submitted, academic_year: "2019/2020", policy: policy, date_of_birth: date_of_birth)
  end
  let(:policy) { StudentLoans }
  let(:itt_subject_code) { "" }
  let(:postgraduate_degree_code) { "" }
  let(:qts_date) { "20/10/2015" }
  let(:date_of_birth) { Date.new(1990, 8, 23) }

  describe "#ingest" do
    context "when the QTS date is after the cut-off date" do
      let(:qts_date) { "20/10/2015" }

      context "and the claim is a Student Loans claim" do
        let(:policy) { StudentLoans }

        it "completes the qualification task for the associated claim" do
          expect { dqt_report_consumer.ingest }.to change { claim.tasks.count }.by(1)
        end
      end

      context "and the claim is a Maths and Physics claim" do
        let(:policy) { MathsAndPhysics }

        context "and the ITT subject or post-graduate degree is Maths or Physics" do
          let(:itt_subject_code) { "G100" }
          let(:postgraduate_degree_code) { "G100" }

          it "completes the qualification task for the associated claim" do
            expect { dqt_report_consumer.ingest }.to change { claim.tasks.count }.by(1)
          end
        end

        context "and the ITT subject or post-graduate degree is neither Maths or Physics" do
          let(:itt_subject_code) { "J100" }
          let(:postgraduate_degree_code) { "X100" }

          it "does nothing" do
            expect { dqt_report_consumer.ingest }.to change { claim.tasks.count }.by(0)
          end
        end
      end
    end

    context "when the QTS date is before the cut-off date" do
      let(:qts_date) { "20/4/1990" }

      it "does nothing" do
        expect { dqt_report_consumer.ingest }.to change { claim.tasks.count }.by(0)
      end
    end

    context "when the DQT record doesn’t match the data we have in the claim" do
      let(:date_of_birth) { Date.new(1895, 10, 1) }

      it "does nothing" do
        expect { dqt_report_consumer.ingest }.to change { claim.tasks.count }.by(0)
      end
    end

    context "when there is no DQT record" do
      let(:qts_date) { "" }

      it "does nothing" do
        expect { dqt_report_consumer.ingest }.to change { claim.tasks.count }.by(0)
      end
    end

    context "when the claim already has a decision" do
      it "does nothing" do
        create(:decision, :approved, claim: claim)
        expect { dqt_report_consumer.ingest }.to change { claim.tasks.count }.by(0)
      end
    end

    context "when there is already a qualification check for the claim" do
      it "does nothing" do
        create(:task, name: "qualifications", claim: claim)
        expect { dqt_report_consumer.ingest }.to change { claim.tasks.count }.by(0)
      end
    end
  end
end
