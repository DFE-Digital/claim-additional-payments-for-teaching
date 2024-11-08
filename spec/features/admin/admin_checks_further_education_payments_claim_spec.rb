require "rails_helper"

RSpec.feature "Admin checks an Further Education Payments claim" do
  it_behaves_like "Admin Checks", Policies::FurtherEducationPayments

  describe "further education specific checks" do
    before do
      sign_in_as_service_operator
    end

    context "when the claim has a claimant and provider with the same name" do
      it "requires the admin to check for provider fraud" do
        claim = create(
          :claim,
          :submitted,
          first_name: "Walter",
          middle_name: "Seymour",
          surname: "Skinner",
          email_address: "w.s.skinner@example.com",
          policy: Policies::FurtherEducationPayments,
          eligibility_attributes: {
            verification: {
              verifier: {
                first_name: "Walter",
                last_name: "Skinner",
                email: "w.s.skinner@springfield-elementary.edu"
              }
            }
          }
        )

        visit admin_claim_tasks_path(claim)

        expect(page).to have_content("Check the provider details")

        click_on "Check the provider details"

        expect(page).to have_content(
          "Is the claim still valid even though the claimant and provider have matching details?"
        )
      end
    end

    context "when the claim has a claimant and provider with the same email" do
      it "requires the admin to check for provider fraud" do
        claim = create(
          :claim,
          :submitted,
          first_name: "Armin",
          surname: "Tamzarian",
          email_address: "w.s.skinner@springfield-elementary.edu",
          policy: Policies::FurtherEducationPayments,
          eligibility_attributes: {
            verification: {
              verifier: {
                first_name: "Walter",
                last_name: "Skinner",
                email: "w.s.skinner@springfield-elementary.edu"
              }
            }
          }
        )

        visit admin_claim_tasks_path(claim)

        expect(page).to have_content("Check the provider details")

        click_on "Check the provider details"

        expect(page).to have_content(
          "Is the claim still valid even though the claimant and provider have matching details?"
        )
      end
    end

    context "when the claim has a claimant and provider with different details" do
      it "doesn't require the admin check for provider fraud" do
        claim = create(
          :claim,
          :submitted,
          first_name: "Edna",
          surname: "Krabappel",
          email_address: "e.krabappel@springfield-elementary.edu",
          policy: Policies::FurtherEducationPayments,
          eligibility_attributes: {
            verification: {
              verifier: {
                first_name: "Walter",
                last_name: "Skinner",
                email: "w.s.skinner@springfield-elementary.edu"
              }
            }
          }
        )

        visit admin_claim_tasks_path(claim)

        expect(page).not_to have_content("Check the provider details")
      end
    end
  end
end
