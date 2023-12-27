module Dqt
  class RetrieveClaimQualificationsData
    def self.call(claim)
      new(claim).save_qualifications_result
    end

    def initialize(claim)
      @claim = claim
    end

    def save_qualifications_result
      return if @claim.dqt_teacher_status

      begin
        # {} would indicate nothing was found in DQT but also truthy to prevent further requests
        @claim.update(dqt_teacher_status: response || {})
      rescue
        # Something went wrong with the DQT call, just assume no result returned and continue
        Rollbar.error(e)
        @claim.update(dqt_teacher_status: {})
      end
    end

    private

    def response
      Dqt::Client.new.teacher.find_raw(
        @claim.teacher_reference_number,
        birthdate: @claim.date_of_birth.to_s,
        nino: @claim.national_insurance_number
      )
    end
  end
end
