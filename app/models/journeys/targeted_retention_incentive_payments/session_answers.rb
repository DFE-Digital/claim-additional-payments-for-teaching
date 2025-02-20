module Journeys
  module TargetedRetentionIncentivePayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :employed_as_supply_teacher, :boolean, pii: false
      attribute :subject_to_formal_performance_action, :boolean, pii: false
      attribute :subject_to_disciplinary_action, :boolean, pii: false
      attribute :itt_academic_year, AcademicYear::Type.new, pii: false
      attribute :teaching_subject_now, :boolean, pii: false
      attribute :eligible_itt_subject, :string, pii: false
    end
  end
end
