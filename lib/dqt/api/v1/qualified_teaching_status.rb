module Dqt
  class Api
    class V1
      class QualifiedTeachingStatus
        def initialize(client:)
          self.client = client
        end

        def show(params:)
          mapped_params = {
            trn: params[:teacher_reference_number],
            niNumber: params[:national_insurance_number]
          }

          response = client.get(path: "/api/qualified-teachers/qualified-teaching-status", params: mapped_params)

          # API returns multiple items but we only ever use the first one. Decided to create a consistent interface here for automated checks rather than spend time creating an abstract interface.
          first_item = response[:data].first

          {
            teacher_reference_number: first_item[:trn],
            first_name: first_item[:name].split.first,
            surname: first_item[:name].split.last,
            date_of_birth: DateTime.parse(first_item[:doB]),
            degree_codes: [],
            national_insurance_number: first_item[:niNumber],
            qts_date: DateTime.parse(first_item[:qtsAwardDate]),
            itt_subject_codes: [
              first_item[:ittSubject1Code],
              first_item[:ittSubject2Code],
              first_item[:ittSubject3Code]
            ],
            active_alert: true
          }
        end

        private

        attr_accessor :client
      end
    end
  end
end
