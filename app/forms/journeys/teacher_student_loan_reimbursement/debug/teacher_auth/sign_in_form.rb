module Journeys
  module TeacherStudentLoanReimbursement
    module Debug
      module TeacherAuth
        class SignInForm < ::Debug::TeacherAuth::SignInForm
          def self.form_key
            "sign-in"
          end

          attribute :first_name, :string
          attribute :middle_name, :string
          attribute :last_name, :string
          attribute :date_of_birth, :date
          attribute :email, :string
          attribute :trn, :string
          attribute :sub, :string
          attribute :qts_award_date, :date
          attribute :national_insurance_number, :string

          validates :first_name, presence: true
          validates :last_name, presence: true
          validates :date_of_birth, presence: true
          validates :email, presence: true
          validates :trn, presence: true
          validates :sub, presence: true
          validates :qts_award_date, presence: true

          # Base form makes it tricky to do this nicely
          after_initialize do
            year = permitted_params["date_of_birth(1i)"].to_i
            month = permitted_params["date_of_birth(2i)"].to_i
            day = permitted_params["date_of_birth(3i)"].to_i
            date_of_birth = begin
              Date.new(year, month, day)
            rescue
              nil
            end
            self.date_of_birth = date_of_birth if date_of_birth

            year = permitted_params["qts_award_date(1i)"].to_i
            month = permitted_params["qts_award_date(2i)"].to_i
            day = permitted_params["qts_award_date(3i)"].to_i
            qts_award_date = begin
              Date.new(year, month, day)
            rescue
              nil
            end
            self.qts_award_date = qts_award_date if qts_award_date
          end

          def default_qts_award_date
            Policies::StudentLoans::POLICY_START_YEAR.start_of_autumn_term
          end

          def default_first_name
            default_verified_name.split(" ").first
          end

          def default_middle_name
            default_verified_name.split(" ").excluding(
              default_first_name,
              default_last_name
            ).presence&.join(" ")
          end

          def default_last_name
            default_verified_name.split(" ").last
          end

          def default_date_of_birth
            default_verified_date_of_birth
          end

          def default_national_insurance_number
            [
              ("A".."Z").to_a.sample(2).flatten +
                (0..9).to_a.sample(6).flatten +
                [("A".."D").to_a.sample]
            ].join
          end

          def save
            return false unless valid?

            journey_session.answers.update!(
              teacher_auth_teacher_reference_number: trn,
              teacher_auth_email: email,
              teacher_auth_verified_name: teacher_auth_verified_name,
              teacher_auth_verified_date_of_birth: date_of_birth,
              teacher_auth_one_login_uid: sub,
              teacher_auth_completed_at: Time.zone.now,
              identity_confirmed_with_onelogin: true,
              onelogin_idv_at: Time.zone.now,
              details_check: true,
              teacher_reference_number: trn,
              trs_data_fetched_at: nil,
              **details_requested_from_api_call
            )
          end

          private

          # These details will be pulled from the TRS /v3/person end point
          def details_requested_from_api_call
            {
              dqt_teacher_status: {
                qts: {
                  holdsFrom: qts_award_date.iso8601
                }
              },
              first_name: first_name,
              middle_name: middle_name,
              surname: last_name,
              national_insurance_number: national_insurance_number,
              date_of_birth: date_of_birth
            }
          end

          def teacher_auth_verified_name
            [first_name, middle_name, last_name].join(" ")
          end
        end
      end
    end
  end
end
