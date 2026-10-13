module Dqt
  class Route < Object
    def name
      routeToProfessionalStatusType.name
    end

    def type
      routeToProfessionalStatusType.professionalStatusType.underscore.humanize
    end

    def holds?
      status == "Holds"
    end

    # returns a symbol or nil
    # :postgraduate_itt, :undergraduate_itt, :assessment_only, :overseas_recognition
    def qualification
      name = routeToProfessionalStatusType.name&.downcase
      group = Dqt::Matchers::General::QUALIFICATION_MATCHING_TYPE.find do |_,v|
        v.include?(name)
      end

      return if group.nil?

      group[0]
    end

    # date of when training started
    def start_date
      date_reader(trainingStartDate)
    end

    # returns an array
    # a route can have multiple subjects
    # trainingSubjects => [{"name" => "mathematics", "reference" => "100403"}]
    def subjects
      trainingSubjects.map { |s| Subject.new(s) }
    end

    def subjects_formatted_s
      subjects.map{ |s| "#{s.name} (#{s.reference})" }.join(", ")
    end

    def holds_from
      date_reader(holdsFrom)
    end
  end
end
