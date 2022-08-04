require "rails_helper"

# this is for while PRODUCTION DqT is only sending through the following response
# Under the DqT Proxy (Azure solution) a response looked like:
# response[:"ittSubject#{n}Code"]
#
# Under the DqT API (non-Azure solution) a response for ITT is as follows:
# "initial_teacher_training": {
#         "programme_start_date": "2021-06-27T00:00:00Z",
#         "programme_end_date": "2021-07-04T00:00:00Z",
#         "programme_type": "Overseas Trained Teacher Programme",
#         "result": "Pass",
#         "subject1": "applied biology",
#         "subject2": "applied chemistry",
#         "subject3": "applied computing",
#         "qualification": "BA (Hons)",
#         "state": 0,
#         "state_name": "Active"
#     }

# When the DqT API is sending through a response for ITT as below then this whole spec can be deleted
# "initial_teacher_training": {
#     "programme_start_date": "2021-06-27T00:00:00Z",
#     "programme_end_date": "2021-07-04T00:00:00Z",
#     "programme_type": "Overseas Trained Teacher Programme",
#     "result": "Pass",
#     "subject1": "applied biology",
#     "subject1_code": "100343",
#     "subject2": "applied chemistry",
#     "subject2_code": "101038",
#     "subject3": "applied computing",
#     "subject3_code": "100358",
#     "qualification": "BA (Hons)",
#     "state": 0,
#     "state_name": "Active"
# }

RSpec.describe EarlyCareerPayments::DqtRecord do
  subject(:dqt_record) do
    described_class.new(
      record,
      claim
    )
  end

  let(:claim) do
    build_stubbed(
      :claim,
      academic_year: claim_academic_year,
      eligibility: eligibility
    )
  end

  let(:eligibility) do
    build(
      :early_career_payments_eligibility,
      :eligible,
      eligible_itt_subject: eligible_itt_subject
    )
  end

  let(:eligible_itt_subject) { :mathematics }

  let(:record) do
    OpenStruct.new(
      {
        degree_codes: record_degree_codes,
        itt_subjects: record_itt_subjects,
        itt_subject_codes: record_itt_subject_codes,
        itt_start_date: record_itt_date,
        qts_award_date: record_qts_date,
        qualification_name: record_qualification_name
      }
    )
  end

  describe "#eligible?" do
    subject(:eligible?) { dqt_record.eligible? }

    [
      {
        claim_academic_year: AcademicYear.new(2021),
        record_degree_codes: [],
        record_itt_subjects: ["mathematics"],
        record_itt_subject_codes: ["G100"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2018"),
        record_qualification_name: "BA",
        eligible_itt_subject: :mathematics
      },

      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: [],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages
      },

      {
        claim_academic_year: AcademicYear.new(2022),
        record_degree_codes: [],
        record_itt_subjects: ["French language"],
        record_itt_subject_codes: ["F300"],
        record_itt_date: Date.parse("1/9/2017"),
        record_qts_date: Date.parse("1/9/2020"),
        record_qualification_name: "BA",
        eligible_itt_subject: :foreign_languages
      }
    ].each do |context|
      context "when claim academic year #{context[:claim_academic_year]}" do
        let(:claim_academic_year) { context[:claim_academic_year] }

        context "when record degree codes #{context[:record_degree_codes]}" do
          let(:record_degree_codes) { context[:record_degree_codes] }

          context "when record ITT subjects #{context[:record_itt_subjects]}" do
            let(:record_itt_subjects) { context[:record_itt_subjects] }
            let(:eligible_itt_subject) { context[:eligible_itt_subject] }

            context "when record ITT subject codes #{context[:record_itt_subject_codes]}" do
              let(:record_itt_subject_codes) { context[:record_itt_subject_codes] }

              context "when record QTS date #{context[:record_qts_date]}" do
                let(:record_qts_date) { context[:record_qts_date] }

                context "when record ITT date #{context[:record_itt_date]}" do
                  let(:record_itt_date) { context[:record_itt_date] }

                  context "when record qualification name #{context[:record_qualification_name]}" do
                    let(:record_qualification_name) { context[:record_qualification_name] }

                    it { is_expected.to eql true }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
