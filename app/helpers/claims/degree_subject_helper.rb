module Claims
  module DegreeSubjectHelper
    def dqt_degree_subjects_playback(claim)
      claim.dqt_teacher_record.degree_names.map do |subject|
        (subject.downcase == subject) ? subject.titleize : subject
      end.join(", ")
    end
  end
end
