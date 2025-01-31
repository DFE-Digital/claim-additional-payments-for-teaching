module AutomatedChecks
  module ClaimVerifiers
    module EarlyYearsPayments
      class Identity < AutomatedChecks::ClaimVerifiers::Identity
        def perform
          return unless claim.eligibility.practitioner_journey_completed?
          return unless awaiting_task?(TASK_NAME)

          if one_login_idv_match?
            create_task(match: nil, passed: true)
          elsif one_login_idv_partial_match?
            create_task(match: :any, passed: nil)

            create_note(body: note_body("Names partially match"))
          elsif claim.one_login_idv_match?
            create_task(match: nil, passed: false)

            create_note(body: note_body("Names do not match"))
          else
            create_task(match: :none, passed: false)

            create_note(body: note_body("IDV mismatch"))
          end
        end

        private

        def one_login_idv_match?
          return false unless claim.one_login_idv_match?

          claim.eligibility.practitioner_and_provider_entered_names_match?
        end

        def one_login_idv_partial_match?
          return false unless claim.one_login_idv_match?

          claim.eligibility.practitioner_and_provider_entered_names_partial_match?
        end

        def note_body(match)
          provider_entered_name = claim.eligibility.practitioner_name
          govuk_one_login_name = claim.onelogin_idv_full_name
          claimant_entered_dob = claim.date_of_birth
          gov_uk_one_login_dob = claim.onelogin_idv_date_of_birth

          name_colour = if provider_entered_name.downcase == govuk_one_login_name.downcase
            "green"
          else
            "red"
          end

          dob_colour = if claimant_entered_dob == gov_uk_one_login_dob
            "green"
          else
            "red"
          end

          <<-HTML.strip_heredoc
          [GOV UK One Login] - #{match}:
          <pre>
            Provider-entered name: <span class="#{name_colour}">"#{provider_entered_name}"</span>
            GOV.UK One Login Name: <span class="#{name_colour}">"#{govuk_one_login_name}"</span>
            Claimant-entered DOB: <span class="#{dob_colour}">"#{claimant_entered_dob}"</span>
            GOV.UK One Login DOB: <span class="#{dob_colour}">"#{gov_uk_one_login_dob}"</span>
          </pre>
          HTML
        end
      end
    end
  end
end
