module Debug
  class StriBypassJob < ApplicationJob
    def perform(
      journey_session:,
      has_national_insurance_number:,
      national_insurance_number:,
      ineligible_options:
    )
      national_insurance_number_to_store = if has_national_insurance_number
        national_insurance_number
      end

      ineligible_start_year = ineligible_options.reject(&:blank?).include?("ineligible-start-year")
      ineligible_subject = ineligible_options.reject(&:blank?).include?("ineligible-subject")
      ineligible_qualification = ineligible_options.reject(&:blank?).include?("ineligible-qualification")

      training_subjects = if ineligible_subject
        [{
          name: "ineligible subject",
          reference: "999999"
        }]
      else
        [{
          name: "applied computing",
          reference: "100358"
        }]
      end

      route_name = if ineligible_qualification
        "Ineligible qualification route"
      else
        "Assessment Only"
      end

      holds_from = if ineligible_start_year
        "2000-01-01"
      else
        "2026-01-01"
      end

      journey_session.answers.update!(
        trs_data: {
          qts: {
            routes: [{
              routeToProfessionalStatusType: {
                name: route_name,
                professionalStatusType: "QualifiedTeacherStatus",
                routeToProfessionalStatusTypeId: "57b86cef-98e2-4962-a74a-d47c7a34b838"
              }
            }],
            holdsFrom: holds_from
          },
          trn: "3013822",
          eyts: {
            routes: [{
              routeToProfessionalStatusType: {
                name: "Early Years Teacher Degree Apprenticeship",
                professionalStatusType: "EarlyYearsTeacherStatus",
                routeToProfessionalStatusTypeId: "11b66de5-4670-4c82-86aa-20e42df723b7"
              }
            }],
            holdsFrom: holds_from
          },
          alerts: [],
          lastName: "John",
          firstName: "Doe",
          induction: {
            status: "Exempt",
            startDate: nil,
            completedDate: nil,
            exemptionReasons: []
          },
          middleName: "",
          qtlsStatus: "None",
          dateOfBirth: "1960-01-01",
          emailAddress: nil,
          nationalInsuranceNumber: national_insurance_number_to_store,
          routesToProfessionalStatuses: [{
            status: "Holds",
            holdsFrom: holds_from,
            degreeType: nil,
            trainingCountry: nil,
            trainingEndDate: nil,
            trainingProvider: nil,
            trainingSubjects: training_subjects,
            trainingStartDate: "2024-09-01",
            inductionExemption: {
              isExempt: false,
              exemptionReasons: []
            },
            trainingAgeSpecialism: nil,
            routeToProfessionalStatusId: "3a4ecf1a-0b9d-487c-b71d-4965b289aaed",
            routeToProfessionalStatusType: {
              name: route_name,
              professionalStatusType: "QualifiedTeacherStatus",
              routeToProfessionalStatusTypeId: "57b86cef-98e2-4962-a74a-d47c7a34b838"
            }
          }, {
            status: "Holds",
            holdsFrom: holds_from,
            degreeType: {
              name: "BA Education",
              degreeTypeId: "84e541d5-d55a-4d44-bc52-983322c1453f"
            },
            trainingCountry: {
              name: "England",
              reference: "GB-ENG"
            },
            trainingEndDate: "2026-01-01",
            trainingProvider: {
              name: "University of Nottingham",
              ukprn: "10007154"
            },
            trainingSubjects: training_subjects,
            trainingStartDate: "2025-12-21",
            inductionExemption: {
              isExempt: false,
              exemptionReasons: []
            },
            trainingAgeSpecialism: {
              type: "KeyStage1"
            },
            routeToProfessionalStatusId: "c01916b8-88c1-48c4-82f8-5920600ee694",
            routeToProfessionalStatusType: {
              name: "Early Years Teacher Degree Apprenticeship",
              professionalStatusType: "EarlyYearsTeacherStatus",
              routeToProfessionalStatusTypeId: "11b66de5-4670-4c82-86aa-20e42df723b7"
            }
          }]
        },
        trs_data_fetched_at: Time.zone.now
      )
    end
  end
end
