module Debug
  class FetchNinoBypassJob < ApplicationJob
    def perform(journey_session:, has_national_insurance_number:, national_insurance_number:)
      national_insurance_number_to_store = if has_national_insurance_number
        national_insurance_number
      end

      journey_session.answers.update!(
        trs_national_insurance_number: national_insurance_number_to_store,
        trs_national_insurance_number_completed_at: Time.zone.now
      )
    end
  end
end
