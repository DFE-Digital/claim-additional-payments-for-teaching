module Journeys
  module FurtherEducationPayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :teaching_responsibilities, :boolean
      attribute :provision_search, :string
      attribute :school_id, :string # GUID
      attribute :subjects_taught, default: []
      attribute :half_teaching_hours, :boolean
    end
  end
end
