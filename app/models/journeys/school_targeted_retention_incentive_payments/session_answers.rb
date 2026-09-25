module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :award_amount, :decimal, pii: false
      attribute :half_contracted_hours, :boolean, pii: false

      attribute :teacher_auth_teacher_reference_number, :string, pii: true
      attribute :teacher_auth_email, :string, pii: true
      attribute :teacher_auth_verified_name, :string, pii: true
      attribute :teacher_auth_verified_date_of_birth, :date, pii: true
      attribute :teacher_auth_one_login_uid, :string, pii: true
      attribute :teacher_auth_completed_at, :datetime, pii: false

      attribute :trs_data, pii: true
      attribute :trs_data_fetched_at, :datetime, pii: false

      attribute :national_insurance_number_correct, :boolean, pii: false
      attribute :national_insurance_number, :string, pii: true

      def policy
        Policies::TargetedRetentionIncentivePayments
      end

      def national_insurance_number_to_display
        if national_insurance_number_correct
          trs_data["nationalInsuranceNumber"]
        else
          national_insurance_number
        end
      end

      def qualifications_from_trs_data
        trs_data["routesToProfessionalStatuses"].select do |route|
          route["status"] == "Holds"
        end.map do |route|
          OpenStruct.new(
            name: route["routeToProfessionalStatusType"]["name"],
            professional_status: route["routeToProfessionalStatusType"]["professionalStatusType"].underscore.humanize.titleize,
            valid_from: Date.parse(route["holdsFrom"]),
            subjects: route["trainingSubjects"].map { |subject| "#{subject["name"]} (#{subject["reference"]})" }
          )
        end
      end
    end
  end
end
