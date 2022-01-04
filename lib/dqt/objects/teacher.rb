module Dqt
  class Teacher < Object
    def date_of_birth
      date_reader(dob)
    end

    def first_name
      string_reader(name) do |string|
        string.split.first
      end
    end

    def surname
      string_reader(name) do |string|
        string.split.last
      end
    end

    def qts_award_date
      date_reader(qualified_teacher_status&.qts_date)
    end

    def itt_subject_codes
      (1..3).filter_map do |n|
        string_reader(itt&.send("subject#{n}"))
      end
    end

    def itt_start_date
      date_reader(itt.presence&.programme_start_date)
    end

    def qualification_name
      string_reader(itt&.qualification)
    end

    def degree_codes
      []
    end

    def national_insurance_number
      string_reader(ni_number)
    end

    def teacher_reference_number
      string_reader(trn)
    end

    def itt
      initial_teacher_training
    end

    def active_alert?
      boolean_reader(active_alert)
    end
  end
end
