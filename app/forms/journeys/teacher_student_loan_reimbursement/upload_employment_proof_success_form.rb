# frozen_string_literal: true

module Journeys
  module TeacherStudentLoanReimbursement
    class UploadEmploymentProofSuccessForm < Form
      def save
        true
      end

      def completed?
        journey_session.steps.include?("upload-employment-proof-success")
      end
    end
  end
end
