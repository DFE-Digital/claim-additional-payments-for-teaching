require "rails_helper"

RSpec.describe "Admin matching claims task" do
  context "when a new claim is submitted" do
    context "when the claim is not a duplicate" do
      before do
        claim = submit_a_claim

        sign_in_as_service_operator

        visit admin_claim_tasks_path(claim)
      end

      it "doesn't add the matching claims task" do
        within ".app-task-list" do
          expect(page).not_to have_content "Matching details"
        end
      end

      it "doesn't show the matching claims warning" do
        expect(page).not_to have_content(
          "Multiple claims with matching details have been made"
        )
      end
    end

    context "when the claim is a duplicate" do
      context "when the other claim has been decided" do
        it "adds a task to the new claim" do
          create(
            :claim,
            :approved,
            policy: Policies::TargetedRetentionIncentivePayments,
            email_address: "seymour.skinner@springfield-elementary.edu"
          )

          new_claim = submit_a_claim

          sign_in_as_service_operator

          visit admin_claim_tasks_path(new_claim)

          within ".app-task-list" do
            expect(page).to have_content "Matching details"
          end
        end

        it "doesn't change the tasks on the other claim" do
          existing_claim = create(
            :claim,
            :approved,
            policy: Policies::TargetedRetentionIncentivePayments,
            email_address: "seymour.skinner@springfield-elementary.edu"
          )

          submit_a_claim

          sign_in_as_service_operator

          visit admin_claim_tasks_path(existing_claim)

          within ".app-task-list" do
            expect(page).not_to have_content "Matching details"
          end
        end

        it "shows a warning on both claims" do
          existing_claim = create(
            :claim,
            :approved,
            policy: Policies::TargetedRetentionIncentivePayments,
            email_address: "seymour.skinner@springfield-elementary.edu"
          )

          new_claim = submit_a_claim

          sign_in_as_service_operator

          visit admin_claim_tasks_path(new_claim)

          expect(page).to have_content(
            "Multiple claims with matching details have been made"
          )

          visit admin_claim_tasks_path(existing_claim)

          expect(page).to have_content(
            "Multiple claims with matching details have been made"
          )
        end
      end

      context "when the other claim has not been decided" do
        context "when the other claim doens't have a matching details task" do
          it "adds the matching details task to both claims" do
            existing_claim = create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "seymour.skinner@springfield-elementary.edu"
            )

            new_claim = submit_a_claim

            sign_in_as_service_operator

            visit admin_claim_tasks_path(new_claim)

            within ".app-task-list" do
              expect(page).to have_content "Matching details"
            end

            visit admin_claim_tasks_path(existing_claim)

            within ".app-task-list" do
              expect(page).to have_content "Matching details"
            end
          end

          it "shows a warning on both claims" do
            existing_claim = create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "seymour.skinner@springfield-elementary.edu"
            )

            new_claim = submit_a_claim

            sign_in_as_service_operator

            visit admin_claim_tasks_path(new_claim)

            expect(page).to have_content(
              "Multiple claims with matching details have been made"
            )

            visit admin_claim_tasks_path(existing_claim)

            expect(page).to have_content(
              "Multiple claims with matching details have been made"
            )
          end
        end

        context "when the other claim has a completed matching details task" do
          it "adds a task to the new claim" do
            existing_claim = create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "seymour.skinner@springfield-elementary.edu"
            )

            create(
              :task,
              name: "matching_details",
              claim: existing_claim,
              passed: true
            )

            new_claim = submit_a_claim

            sign_in_as_service_operator

            visit admin_claim_tasks_path(new_claim)

            within ".app-task-list" do
              expect(page).to have_content "Matching details"
            end
          end

          it "doesn't change the tasks on the other claim" do
            existing_claim = create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "seymour.skinner@springfield-elementary.edu"
            )

            create(
              :task,
              name: "matching_details",
              claim: existing_claim,
              passed: true
            )

            submit_a_claim

            sign_in_as_service_operator

            visit admin_claim_tasks_path(existing_claim)

            within ".app-task-list" do
              expect(page).to have_content "Matching details"
              expect(page).to have_content(
                "Review matching details from other claims Passed"
              )
            end
          end

          it "shows a warning on both claims" do
            existing_claim = create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "seymour.skinner@springfield-elementary.edu"
            )

            create(
              :task,
              name: "matching_details",
              claim: existing_claim,
              passed: true
            )

            new_claim = submit_a_claim

            sign_in_as_service_operator

            visit admin_claim_tasks_path(new_claim)

            expect(page).to have_content(
              "Multiple claims with matching details have been made"
            )

            visit admin_claim_tasks_path(existing_claim)

            expect(page).to have_content(
              "Multiple claims with matching details have been made"
            )
          end
        end
      end
    end
  end

  context "when a claim is amended" do
    context "when a duplicate claim is amended" do
      context "when it is still a duplicate" do
        it "shows the matching details task on both claims" do
          amended_claim = create(
            :claim,
            :submitted,
            policy: Policies::TargetedRetentionIncentivePayments,
            email_address: "seymour.skinner@springfield-elementary.edu"
          )

          other_claim = submit_a_claim

          sign_in_as_service_operator

          visit new_admin_claim_amendment_path(amended_claim)

          fill_in "Postcode", with: "TE57 1NG"
          fill_in "Change notes", with: "Updated postcode"

          click_on "Amend claim"

          visit admin_claim_tasks_path(other_claim)

          within ".app-task-list" do
            expect(page).to have_content "Matching details"
          end

          visit admin_claim_tasks_path(other_claim)

          within ".app-task-list" do
            expect(page).to have_content "Matching details"
          end
        end

        it "shows a warning on both claims" do
          amended_claim = create(
            :claim,
            :submitted,
            policy: Policies::TargetedRetentionIncentivePayments,
            email_address: "seymour.skinner@springfield-elementary.edu"
          )

          other_claim = submit_a_claim

          sign_in_as_service_operator

          visit new_admin_claim_amendment_path(amended_claim)

          fill_in "Postcode", with: "TE57 1NG"
          fill_in "Change notes", with: "Updated postcode"

          click_on "Amend claim"

          visit admin_claim_tasks_path(other_claim)

          expect(page).to have_content(
            "Multiple claims with matching details have been made"
          )

          visit admin_claim_tasks_path(other_claim)

          expect(page).to have_content(
            "Multiple claims with matching details have been made"
          )
        end
      end

      context "when it is no longer a duplicate" do
        context "when the matching details task has been completed on the other claim" do
          let(:amended_claim) do
            create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "seymour.skinner@springfield-elementary.edu"
            )
          end

          let(:other_claim) do
            submit_a_claim
          end

          before do
            amended_claim

            other_claim

            sign_in_as_service_operator

            # Complete task
            visit admin_claim_tasks_path(other_claim)

            click_on "Review matching details from other claims"

            choose "Yes"

            click_on "Save and continue"

            # Amend claim
            visit new_admin_claim_amendment_path(amended_claim)

            fill_in(
              "Email address",
              with: "edna.krabappel@springfield-elementary.edu"
            )

            fill_in "Change notes", with: "Updated email address"

            click_on "Amend claim"
          end

          it "removes the matching details task from the amended claim" do
            visit admin_claim_tasks_path(amended_claim)

            within ".app-task-list" do
              expect(page).not_to have_content "Matching details"
            end
          end

          it "doesn't remove the matching details task on the other claim" do
            visit admin_claim_tasks_path(other_claim)

            within ".app-task-list" do
              expect(page).to have_content "Matching details"
            end
          end

          it "doesn't show a warning on either claim" do
            visit admin_claim_tasks_path(amended_claim)

            expect(page).not_to have_content(
              "Multiple claims with matching details have been made"
            )

            visit admin_claim_tasks_path(other_claim)

            expect(page).not_to have_content(
              "Multiple claims with matching details have been made"
            )
          end
        end

        context "when the matching claims task has not been completed" do
          let(:amended_claim) do
            create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "seymour.skinner@springfield-elementary.edu"
            )
          end

          let(:other_claim) do
            submit_a_claim
          end

          before do
            amended_claim

            other_claim

            sign_in_as_service_operator

            # Amend claim
            visit new_admin_claim_amendment_path(amended_claim)

            fill_in(
              "Email address",
              with: "edna.krabappel@springfield-elementary.edu"
            )

            fill_in "Change notes", with: "Updated postcode"

            click_on "Amend claim"
          end

          it "removes the matching details task on both claims" do
            visit admin_claim_tasks_path(amended_claim)

            within ".app-task-list" do
              expect(page).not_to have_content "Matching details"
            end

            visit admin_claim_tasks_path(other_claim)

            within ".app-task-list" do
              expect(page).not_to have_content "Matching details"
            end
          end

          it "doesn't show a warning on either claim" do
            visit admin_claim_tasks_path(amended_claim)

            expect(page).not_to have_content(
              "Multiple claims with matching details have been made"
            )

            visit admin_claim_tasks_path(other_claim)

            expect(page).not_to have_content(
              "Multiple claims with matching details have been made"
            )
          end
        end

        context "when the other claim has other duplciates" do
          let(:amended_claim) do
            create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "seymour.skinner@springfield-elementary.edu",
              national_insurance_number: "AB222222C"
            )
          end

          let(:other_duplicate) do
            create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "elizabeth.hoover@springfield-elementary.edu",
              national_insurance_number: "AB222222C"
            )
          end

          let(:new_claim) do
            submit_a_claim
          end

          before do
            amended_claim

            other_duplicate

            new_claim

            sign_in_as_service_operator

            # Amend claim
            visit new_admin_claim_amendment_path(amended_claim)

            fill_in(
              "Email address",
              with: "edna.krabappel@springfield-elementary.edu"
            )

            fill_in "Change notes", with: "Updated postcode"

            click_on "Amend claim"
          end

          it "removes the matching claims task from the new claim" do
            visit admin_claim_tasks_path(new_claim)

            within ".app-task-list" do
              expect(page).not_to have_content "Matching details"
            end
          end

          it "doesn't remove the matching claims task from the other claim" do
            visit admin_claim_tasks_path(other_duplicate)

            within ".app-task-list" do
              expect(page).to have_content "Matching details"
            end
          end

          it "doesn't remove the matching claims task from the other duplciate" do
            visit admin_claim_tasks_path(other_duplicate)

            within ".app-task-list" do
              expect(page).to have_content "Matching details"
            end
          end

          it "shows the warning on the other claim and duplicate but not the new claim" do
            visit admin_claim_tasks_path(new_claim)

            expect(page).not_to have_content(
              "Multiple claims with matching details have been made"
            )

            visit admin_claim_tasks_path(other_duplicate)

            expect(page).to have_content(
              "Multiple claims with matching details have been made"
            )

            visit admin_claim_tasks_path(other_duplicate)

            expect(page).to have_content(
              "Multiple claims with matching details have been made"
            )
          end
        end
      end
    end

    context "when a non duplicate claim is amended" do
      context "when it is still not a duplicate" do
        let(:amended_claim) do
          create(
            :claim,
            :submitted,
            policy: Policies::TargetedRetentionIncentivePayments,
            email_address: "edna-krabappel@springfield-elementary.edu"
          )
        end

        let(:other_claim) do
          submit_a_claim
        end

        before do
          amended_claim

          other_claim

          sign_in_as_service_operator

          # Amend claim
          visit new_admin_claim_amendment_path(amended_claim)

          fill_in("Postcode", with: "TE57 1NG")

          fill_in "Change notes", with: "Updated postcode"

          click_on "Amend claim"
        end

        it "doesn't add a matching details task" do
          visit admin_claim_tasks_path(amended_claim)

          within ".app-task-list" do
            expect(page).not_to have_content "Matching details"
          end

          visit admin_claim_tasks_path(other_claim)

          within ".app-task-list" do
            expect(page).not_to have_content "Matching details"
          end
        end

        it "doesn't show a warning" do
          visit admin_claim_tasks_path(amended_claim)

          expect(page).not_to have_content(
            "Multiple claims with matching details have been made"
          )

          visit admin_claim_tasks_path(other_claim)

          expect(page).not_to have_content(
            "Multiple claims with matching details have been made"
          )
        end
      end

      context "when it is now a duplicate" do
        context "when the other claim has been decided" do
          let(:amended_claim) do
            create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "edna-krabappel@springfield-elementary.edu"
            )
          end

          let(:decided_claim) do
            submit_a_claim
          end

          before do
            amended_claim

            decided_claim

            sign_in_as_service_operator

            # Decide claim
            visit admin_claim_tasks_path(decided_claim)

            click_on "Approve or reject this claim"

            # click on approve
            choose "Approve"

            click_on "Confirm decision"

            # Amend claim
            visit new_admin_claim_amendment_path(amended_claim)

            fill_in(
              "Email address",
              with: "seymour.skinner@springfield-elementary.edu"
            )

            fill_in "Change notes", with: "Updated email address"

            click_on "Amend claim"
          end

          it "adds a matching details task to the amended claim" do
            visit admin_claim_tasks_path(amended_claim)

            within ".app-task-list" do
              expect(page).to have_content "Matching details"
            end
          end

          it "doesn't add a new matching details task to the decided claim" do
            visit admin_claim_tasks_path(decided_claim)

            within ".app-task-list" do
              expect(page).not_to have_content "Matching details"
              expect(page).not_to have_content(
                "Review matching details from other claims Passed"
              )
            end
          end

          it "shows the warning on both claims" do
            visit admin_claim_tasks_path(amended_claim)

            expect(page).to have_content(
              "Multiple claims with matching details have been made"
            )

            visit admin_claim_tasks_path(decided_claim)

            expect(page).to have_content(
              "Multiple claims with matching details have been made"
            )
          end
        end

        context "when the other claim has not been decided" do
          let(:amended_claim) do
            create(
              :claim,
              :submitted,
              policy: Policies::TargetedRetentionIncentivePayments,
              email_address: "edna-krabappel@springfield-elementary.edu"
            )
          end

          let(:other_claim) do
            submit_a_claim
          end

          before do
            amended_claim

            other_claim

            sign_in_as_service_operator

            # Amend claim
            visit new_admin_claim_amendment_path(amended_claim)

            fill_in(
              "Email address",
              with: "seymour.skinner@springfield-elementary.edu"
            )

            fill_in "Change notes", with: "Updated email address"

            click_on "Amend claim"
          end

          it "adds the matching details task to both claims" do
            visit admin_claim_tasks_path(amended_claim)

            within ".app-task-list" do
              expect(page).to have_content "Matching details"
            end

            visit admin_claim_tasks_path(other_claim)

            within ".app-task-list" do
              expect(page).to have_content "Matching details"
            end
          end

          it "shows a warning on both claims" do
            visit admin_claim_tasks_path(amended_claim)

            expect(page).to have_content(
              "Multiple claims with matching details have been made"
            )

            visit admin_claim_tasks_path(other_claim)

            expect(page).to have_content(
              "Multiple claims with matching details have been made"
            )
          end
        end
      end
    end

    context "when a claim is reopened" do
      context "when a duplicate claim has been submitted in the interim" do
        let(:reopened_claim) do
          create(
            :claim,
            :submitted,
            policy: Policies::TargetedRetentionIncentivePayments,
            email_address: "seymour.skinner@springfield-elementary.edu"
          )
        end

        let(:duplicate_claim) do
          submit_a_claim
        end

        before do
          reopened_claim

          create(:decision, :rejected, claim: reopened_claim)

          duplicate_claim

          sign_in_as_service_operator

          visit new_admin_claim_amendment_path(reopened_claim)
          click_link "Undo decision"
          fill_in "Change notes", with: "test"
          click_button "Undo rejection"
        end

        it "shows the matching details task on both claims" do
          visit admin_claim_tasks_path(duplicate_claim)

          within ".app-task-list" do
            expect(page).to have_content "Matching details"
          end

          visit admin_claim_tasks_path(reopened_claim)

          within ".app-task-list" do
            expect(page).to have_content "Matching details"
          end
        end

        it "show the matching details warning on both claim" do
          visit admin_claim_tasks_path(reopened_claim)

          expect(page).to have_content(
            "Multiple claims with matching details have been made"
          )

          visit admin_claim_tasks_path(duplicate_claim)

          expect(page).to have_content(
            "Multiple claims with matching details have been made"
          )
        end
      end
    end
  end

  def submit_a_claim
    create(
      :journey_configuration,
      :further_education_payments
    )

    session = create(
      :further_education_payments_session,
      answers: attributes_for(
        :further_education_payments_answers,
        :submittable,
        email_address: "seymour.skinner@springfield-elementary.edu"
      )
    )

    form = Journeys::FurtherEducationPayments::CheckYourAnswersForm.new(
      journey_session: session,
      journey: Journeys::FurtherEducationPayments,
      params: ActionController::Parameters.new(
        claim: {
          claimant_declaration: true
        }
      )
    )

    perform_enqueued_jobs do
      expect(form.save).to be(true)
    end

    Claim.find_by!(journey_session: session)
  end
end
