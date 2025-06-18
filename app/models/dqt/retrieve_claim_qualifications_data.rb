module Dqt
  class RetrieveClaimQualificationsData
    def self.call(session)
      new(session).save_qualifications_result
    end

    def initialize(session)
      @session = session
    end

    def save_qualifications_result
      return if @session.answers.dqt_teacher_status

      begin
        # {} would indicate nothing was found in DQT but also truthy to prevent further requests
        @session.answers.dqt_teacher_status = response || {}
      rescue => e
        # Something went wrong with the DQT call, just assume no result returned and continue
        Rollbar.error(e)
        Sentry.capture_exception(e)

        @session.answers.dqt_teacher_status = {}
      end

      @session.save!
    end

    private

    def response
      Dqt::Client.new.teacher.find_raw(
        @session.answers.teacher_reference_number,
        birthdate: @session.answers.date_of_birth.to_s,
        nino: @session.answers.national_insurance_number
      )
    end
  end
end
