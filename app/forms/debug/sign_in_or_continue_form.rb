module Debug
  class SignInOrContinueForm < SignInOrContinueForm
    attribute :dqt_active_alert, :boolean
    attribute :dqt_qts_name, :string
    attribute :dqt_qts_date, :date
    attribute :dqt_induction_start_date, :date
    attribute :dqt_induction_completion_date, :date
    attribute :dqt_induction_status, :string
    attribute :dqt_itt_programme_start_date, :date
    attribute :dqt_itt_programme_end_date, :date
    attribute :dqt_itt_programme_type, :string
    attribute :dqt_itt_result, :string
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

    def dqt_induction_status_options
      [
        Form::Option.new(id: "Pass", name: "Pass"),
        Form::Option.new(id: "Fail", name: "Fail")
      ]
    end

    def dqt_itt_result_options
      [
        Form::Option.new(id: "Pass", name: "Pass"),
        Form::Option.new(id: "Fail", name: "Fail")
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
      journey_session.answers.dqt_teacher_status = {
        trn: teacher_id_user_info.trn,
        ni_number: teacher_id_user_info.ni_number,
        name: "#{teacher_id_user_info.given_name} #{teacher_id_user_info.family_name}",
        dob: teacher_id_user_info.birthdate,
        active_alert: dqt_active_alert,
        qualified_teacher_status: {
          name: dqt_qts_name,
          qts_date: dqt_qts_date&.iso8601
        },
        induction: {
          start_date: dqt_induction_start_date&.iso8601,
          completion_date: dqt_induction_completion_date&.iso8601,
          status: dqt_induction_status
        },
        initial_teacher_training: {
          programme_start_date: dqt_itt_programme_start_date&.iso8601,
          programme_end_date: dqt_itt_programme_end_date&.iso8601,
          result: dqt_itt_result,
          qualification: dqt_qualification,
          subject1_name: dqt_itt_subject_1_name,
          subject1_code: dqt_itt_subject_1_code,
          subject2_name: dqt_itt_subject_2_name,
          subject2_code: dqt_itt_subject_2_code,
          subject3_name: dqt_itt_subject_3_name,
          subject3_code: dqt_itt_subject_3_code
        }
      }

      journey_session.save!
    end

    def i18n_form_namespace
      self.class.superclass.name.demodulize.gsub("Form", "").underscore
    end
  end
end
