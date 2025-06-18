module Journeys
  class AnswersStudentLoansDetailsUpdater
    def self.call(journey_session)
      instance = new(journey_session)
      instance.save!
    end

    def initialize(journey_session)
      @journey_session = journey_session
    end

    def save!
      # When the claim hasn't been submitted yet, we need a way of knowing if
      # the student loan details on the claim were found using the SLC data we
      # held before submission; after submission, the
      # `submitted_using_slc_data` value must not change
      journey_session.answers.assign_attributes(
        has_student_loan: student_loans_data.has_student_loan?,
        student_loan_plan: student_loans_data.student_loan_plan,
        submitted_using_slc_data: student_loans_data.found_data?
      )

      journey_session.save!
    rescue => e
      # If something goes wrong, log the error and continue
      Rollbar.error(e)
      Sentry.capture_exception(e)
    end

    private

    attr_reader :journey_session

    delegate :answers, to: :journey_session

    def student_loans_data
      @student_loans_data ||= StudentLoansDataPresenter.new(
        national_insurance_number: answers.national_insurance_number,
        date_of_birth: answers.date_of_birth
      )
    end
  end
end
