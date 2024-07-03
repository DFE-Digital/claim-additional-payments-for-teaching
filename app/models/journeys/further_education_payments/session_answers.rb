module Journeys
  module FurtherEducationPayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :teaching_responsibilities, :boolean
      attribute :provision_search, :string
      attribute :school_id, :string # GUID
      attribute :contract_type, :string
      attribute :teaching_hours_per_week, :string
      attribute :further_education_teaching_start_year, :string
      attribute :subjects_taught, default: []
      attribute :teaching_qualification, :string
      attribute :subject_to_formal_performance_action, :boolean
      attribute :subject_to_disciplinary_action, :boolean
      attribute :half_teaching_hours, :boolean

      def school
        @school ||= School.find(school_id)
      end
    end
  end
end
