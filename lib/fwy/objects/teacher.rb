module Fwy
  class Teacher < Object
    def date_of_birth
      dob.presence&.to_date
    end

    def first_name
      name.presence&.split&.first
    end

    def surname
      name.presence&.split&.split.last
    end

    def qts_date
      qualified_teacher_status.presence&.qts_date.presence&.to_date
    end

    def itt_subject_codes
      [
        itt&.subject1,
        itt&.subject2,
        itt&.subject3
      ]
    end

    def itt_date
      itt.presence&.programme_start_date.presence&.to_date
    end

    def qualification_name
      itt&.qualification
    end

    def degree_codes
      []
    end

    def national_insurance_number
      ni_number
    end
    
    def teacher_reference_number
      trn
    end
    
    def itt
      initial_teacher_training
    end
  end
end
