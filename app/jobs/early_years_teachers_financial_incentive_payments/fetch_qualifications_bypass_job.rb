require "csv"

module EarlyYearsTeachersFinancialIncentivePayments
  class FetchQualificationsBypassJob < ApplicationJob
    def perform(journey_session)
      return if journey_session.answers.trs_data_fetched_at.present?

      journey_session.answers.assign_attributes(
        trs_data: {
          qts: {
            holdsFrom: "2026-01-01",
            routes: [
              {
                routeToProfessionalStatusType: {
                  name: "QTLS and SET Membership",
                  professionalStatusType: "QualifiedTeacherStatus",
                  routeToProfessionalStatusTypeId: "be6eaf8c-92dd-4eff-aad3-1c89c4bec18c"
                }
              }
            ]
          },
          trn: "1234567",
          eyts: nil,
          lastName: "Doe",
          firstName: "Jane",
          middleName: "",
          qtlsStatus: "Active",
          dateOfBirth: "1990-01-01",
          emailAddress: nil,
          nationalInsuranceNumber: nil
        },
        trs_data_fetched_at: Time.zone.now
      )

      journey_session.save!
    end
  end
end
