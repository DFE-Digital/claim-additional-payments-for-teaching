require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::QualificationDetailsForm, type: :model do
  let(:teacher_reference_number_str) { "1234567" }
  let(:date_of_birth_str) { "1980-01-02" }

  let(:journey_session) do
    create(
      :targeted_retention_incentive_payments_session,
      answers: {
        details_check: true,
        dqt_teacher_status: {
          trn: teacher_reference_number_str,
          dateOfBirth: date_of_birth_str,
          qts: {
            holdsFrom: "2024-01-01"
          },
          routesToProfessionalStatuses: [
            {
              holdsFrom: "2024-01-01",
              trainingSubjects: [
                {
                  name: "mathematics",
                  reference: "G100"
                }
              ],
              trainingStartDate: "2023-01-09",
              trainingEndDate: nil,
              routeToProfessionalStatusType: {
                name: "BA (Hons)"
              }
            }
          ]
        }
      }
    )
  end

  let(:params) do
    {}
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::TargetedRetentionIncentivePayments,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  describe "validations" do
    subject { form }

    it do
      is_expected.not_to(
        allow_value(nil).for(:qualifications_details_check).with_message(
          "Select yes if your qualification details are correct"
        )
      )
    end
  end

  describe "#save" do
    context "when qualification details match what is expected" do
      let(:params) do
        {
          qualifications_details_check: true
        }
      end

      let(:dqt_higher_education_qualification) do
        create(
          :dqt_higher_education_qualification,
          teacher_reference_number: teacher_reference_number_str,
          date_of_birth: Date.parse(date_of_birth_str),
          subject_code: "G100",
          description: "mathematics2"
        )
      end

      before do
        dqt_higher_education_qualification
      end

      it "sets the qualification answers from the dqt data" do
        expect { form.save }.to(
          change { journey_session.reload.answers.qualifications_details_check }
          .from(nil).to(true)
          .and(
            change { journey_session.answers.qualification }
            .from(nil).to("undergraduate_itt")
          ).and(
            change { journey_session.answers.itt_academic_year }
            .from(nil).to(AcademicYear.new(2023))
          ).and(
            change { journey_session.answers.eligible_degree_subject }
            .from(nil).to(true)
          ).and(
            change { journey_session.answers.eligible_itt_subject }
            .from(nil).to("mathematics")
          )
        )
      end
    end

    context "when qualification details do not match what is expected" do
      let(:params) do
        {
          qualifications_details_check: false
        }
      end

      before do
        journey_session.answers.assign_attributes(
          qualification: "undergraduate_itt",
          itt_academic_year: AcademicYear.new(2023),
          eligible_degree_subject: true,
          eligible_itt_subject: "mathematics"
        )

        journey_session.save!
      end

      it "sets the qualification answers to nil" do
        expect { form.save }.to(
          change { journey_session.reload.answers.qualifications_details_check }
          .from(nil).to(false)
          .and(
            change { journey_session.answers.qualification }
            .from("undergraduate_itt").to(nil)
          ).and(
            change { journey_session.answers.itt_academic_year }
            .from(AcademicYear.new(2023)).to(nil)
          ).and(
            change { journey_session.answers.eligible_degree_subject }
            .from(true).to(nil)
          ).and(
            change { journey_session.answers.eligible_itt_subject }
            .from("mathematics").to(nil)
          )
        )
      end
    end
  end
end
