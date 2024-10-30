module AutomatedChecks
  module ClaimVerifiers
    module EarlyYearsPayments
      class Identity < AutomatedChecks::ClaimVerifiers::Identity
        TASK_NAME = "identity_confirmation".freeze

        def intialize(claim:, admin_user: nil)
          @claim = claim
          @admin_user = admin_user
        end

        def perform
          return unless claim.eligibility.practitioner_journey_completed?
          return unless awaiting_task?(TASK_NAME)

          if one_login_idv_match?
            create_task(match: nil, passed: true)
          elsif one_login_idv_partial_match?
            create_task(match: :any, passed: nil)

            create_note(
              body: <<-HTML
              [GOV UK One Login Name] - Names partially match:
              <pre>
                Provider: "#{claim.eligibility.practitioner_entered_full_name}"
                GOV.UK One Login: "#{claim.onelogin_idv_full_name}"
              </pre>
              HTML
            )
          elsif claim.one_login_idv_match?
            create_task(match: nil, passed: false)

            create_note(
              body: <<-HTML
              [GOV UK One Login Name] - Names do not match:
              <pre>
                Provider: "#{claim.eligibility.practitioner_entered_full_name}"
                GOV.UK One Login: "#{claim.onelogin_idv_full_name}"
              </pre>
              HTML
            )
          else
            create_task(match: :none, passed: false)

            create_note(
              body: <<-HTML
              [GOV UK One Login] - IDV mismatch:
              <pre>
                GOV.UK One Login Name: "#{claim.onelogin_idv_full_name}"
                GOV.UK One Login DOB: "#{claim.onelogin_idv_date_of_birth}"
              </pre>
              HTML
            )
          end
        end

        private

        attr_accessor :claim, :admin_user

        def one_login_idv_match?
          return false unless claim.one_login_idv_match?

          claim.eligibility.practitioner_and_provider_entered_names_match?
        end

        def one_login_idv_partial_match?
          return false unless claim.one_login_idv_match?

          claim.eligibility.practitioner_and_provider_entered_names_partial_match?
        end
      end
    end
  end
end
