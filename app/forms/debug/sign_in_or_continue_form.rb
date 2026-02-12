module Debug
  class SignInOrContinueForm < SignInOrContinueForm
    attribute :dqt_active_alert, :boolean
    attribute :dqt_qts_date, :date
    attribute :dqt_induction_start_date, :date
    attribute :dqt_induction_completion_date, :date
    attribute :dqt_induction_status, :string
    attribute :dqt_itt_programme_start_date, :date
    attribute :dqt_itt_programme_end_date, :date
    attribute :dqt_qualification, :string
    attribute :dqt_itt_subject_1_name, :string
    attribute :dqt_itt_subject_1_code, :string
    attribute :dqt_itt_subject_2_name, :string
    attribute :dqt_itt_subject_2_code, :string
    attribute :dqt_itt_subject_3_name, :string
    attribute :dqt_itt_subject_3_code, :string

    def tid_bypassable?
      true
    end

    def dqt_bypassable?
      !ENV["ENVIRONMENT_NAME"].start_with?("review")
    end

    def dqt_induction_status_options
      [
        Form::Option.new(id: "Passed", name: "Passed"),
        Form::Option.new(id: "Failed", name: "Failed")
      ]
    end

    def dqt_grouped_qualification_options
      Dqt::Matchers::General::QUALIFICATION_MATCHING_TYPE
    end

    def dqt_grouped_itt_subject_name_options
      Dqt::Matchers::TargetedRetentionIncentivePayments::ELIGIBLE_ITT_SUBJECTS.merge(
        foreign_languages: [
          "German"
        ]
      )
    end

    def dqt_itt_subject_code_options
      Policies::TargetedRetentionIncentivePayments::DqtRecord::ELIGIBLE_CODES
    end

    private

    def retrieve_qualifications_data!
      # NOTE: We want to test real DQT calls in Review Apps
      if !dqt_bypassable?
        super
        return
      end

      dqt_teacher_status = {
        trn: teacher_id_user_info.trn,
        nationalInsuranceNumber: teacher_id_user_info.ni_number,
        firstName: teacher_id_user_info.given_name,
        lastName: teacher_id_user_info.family_name,
        dateOfBirth: teacher_id_user_info.birthdate,
        qts: {
          holdsFrom: dqt_qts_date
        },
        induction: {
          startDate: dqt_induction_start_date,
          completedDate: dqt_induction_completion_date,
          status: dqt_induction_status
        },
        routesToProfessionalStatuses: [],
        alerts: []
      }

      if dqt_active_alert
        alert = {
          startDate: Date.today.to_s,
          endDate: nil
        }

        dqt_teacher_status[:alerts] << alert
      end

      [
        [dqt_itt_subject_1_name, dqt_itt_subject_1_code],
        [dqt_itt_subject_2_name, dqt_itt_subject_2_code],
        [dqt_itt_subject_3_name, dqt_itt_subject_3_code]
      ].each do |name, code|
        next if name.blank? && code.blank?

        route = {
          holdsFrom: dqt_qts_date,
          trainingSubjects: [
            {
              name: name,
              reference: code
            }
          ],
          trainingStartDate: dqt_itt_programme_start_date,
          trainingEndDate: dqt_itt_programme_end_date,
          routeToProfessionalStatusType: {
            name: dqt_qualification
          }
        }

        dqt_teacher_status[:routesToProfessionalStatuses] << route
      end

      journey_session.answers.dqt_teacher_status = dqt_teacher_status

      journey_session.save!
    end

    def i18n_form_namespace
      self.class.superclass.name.demodulize.gsub("Form", "").underscore
    end
  end
end
