module Dqt
  class Teacher < Object
    def date_of_birth
      date_reader(dateOfBirth)
    end

    def first_name
      string_reader(firstName)
    end

    def surname
      string_reader(lastName)
    end

    def national_insurance_number
      string_reader(nationalInsuranceNumber)
    end

    def teacher_reference_number
      string_reader(trn)
    end

    def induction_start_date
      date_reader(induction&.startDate)
    end

    def induction_completion_date
      date_reader(induction&.completedDate)
    end

    def induction_status
      string_reader(induction&.status)
    end

    def qts_award_date
      date_reader(qts&.holdsFrom)
    end

    def itt_subject_codes
      return [] if routesToProfessionalStatuses.blank?

      subjects = routesToProfessionalStatuses.map do |route|
        route&.trainingSubjects
      end.flatten.compact

      subjects.map do |subject|
        subject&.reference
      end.compact
    end

    def itt_subjects
      return [] if routesToProfessionalStatuses.blank?

      subjects = routesToProfessionalStatuses.map do |route|
        route&.trainingSubjects
      end.flatten.compact

      subjects.map do |subject|
        subject&.name
      end.compact
    end

    # Returns the most recent route start date if multiple routes
    def itt_start_date
      return if routesToProfessionalStatuses.blank?

      most_recent_route = routesToProfessionalStatuses
        .reject { |r| r.trainingStartDate.blank? }
        .max_by { |r| r.trainingStartDate }

      date_reader(most_recent_route&.trainingStartDate)
    end

    # Returns the most recent qualification name
    def qualification_name
      return if routesToProfessionalStatuses.blank?

      most_recent_route = routesToProfessionalStatuses
        .reject { |r| r.trainingStartDate.blank? }
        .max_by { |r| r.holdsFrom }

      string_reader(most_recent_route&.routeToProfessionalStatusType&.name)
    end

    def degree_codes
      DqtHigherEducationQualification.where(
        teacher_reference_number: teacher_reference_number,
        date_of_birth: date_of_birth
      ).pluck(:subject_code)
    end

    def degree_names
      DqtHigherEducationQualification.where(
        teacher_reference_number: teacher_reference_number,
        date_of_birth: date_of_birth
      ).pluck(:description)
    end

    def active_alert?
      return false if alerts.blank?

      alerts
        .reject { |a| a.endDate.present? }
        .any?
    end
  end
end
