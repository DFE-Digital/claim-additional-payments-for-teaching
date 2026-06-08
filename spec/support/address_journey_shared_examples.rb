require "rails_helper"

# Shared address entry/editing assertions for the claimant journeys.
#
# Every journey drives the claimant to the postcode search page and then runs
# the same set of postcode-search/manual-entry/change-address expectations. The
# only differences between journeys are:
#
#   * how the claimant is driven to the postcode search page and on to the
#     check-your-answers page (provided by the including spec as the
#     `complete_journey_upto_postcode_search` and
#     `complete_journey_from_address_to_check_answers` helper methods), and
#   * the wording of the "Change" link on the check-your-answers page and the
#     heading of the page that link returns to (passed in as options).
#
# Usage:
#
#   it_behaves_like "an address journey",
#     change_address_link: "Change home address",
#     check_answers_heading: "Confirm your details and complete your claim"
#
RSpec.shared_examples "an address journey" do |options|
  change_address_link = options.fetch(:change_address_link)
  check_answers_heading = options.fetch(:check_answers_heading)

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache
  end

  before do
    allow(OrdnanceSurvey).to receive(:configuration).and_return(
      double(
        client: double(
          base_url: "https://api.os.uk",
          params: {"key" => "ABC123"}
        )
      )
    )
  end

  describe "address entry" do
    context "when searching by postcode" do
      context "when postcode search returns no results" do
        before do
          stub_request(
            :get,
            "https://api.os.uk/search/places/v1/postcode?key=ABC123&postcode=TE572NG"
          )
            .to_return(
              status: 200,
              body: {
                results: []
              }.to_json,
              headers: {"Content-Type" => "application/json"}
            )

          stub_request(
            :get,
            "https://api.os.uk/search/places/v1/postcode?key=ABC123&postcode=TE571NG"
          )
            .to_return(
              status: 200,
              body: {
                results: [
                  {
                    DPA: {
                      ADDRESS: "123, Main Street, Springfield, TE57 1NG",
                      BUILDING_NUMBER: "123",
                      THOROUGHFARE_NAME: "Main Street",
                      POST_TOWN: "Springfield",
                      POSTCODE: "TE57 1NG"
                    }
                  }
                ]
              }.to_json,
              headers: {"Content-Type" => "application/json"}
            )
        end

        context "when the user searches again with a new postcode" do
          it "saves the correct address" do
            complete_journey_upto_postcode_search

            fill_in "Postcode", with: "TE57 2NG"
            click_on "Search"
            expect(page).to have_text "We have not been able to find your address."

            click_on "Change"
            fill_in "Postcode", with: "TE57 1NG"
            click_on "Search"
            choose "123, Main Street, Springfield, TE57 1NG"
            click_on "Continue"

            complete_journey_from_address_to_check_answers

            expect(page).to have_text "123, Main Street, Springfield, TE57 1NG"
          end
        end

        context "when the user then chooses to enter their address manually" do
          it "saves the manually entered address" do
            complete_journey_upto_postcode_search

            fill_in "Postcode", with: "TE57 2NG"
            click_on "Search"
            expect(page).to have_text "We have not been able to find your address."

            click_on "Enter your address manually"

            expect(page).to have_text "What is your address?"
            fill_in "House number or name", with: "Flat 1"
            fill_in "Building and street", with: "Fake Street"
            fill_in "Town or city", with: "Springfield"
            fill_in "County", with: "Springfieldshire"
            fill_in "Postcode", with: "TE57 2NG"
            click_on "Continue"

            complete_journey_from_address_to_check_answers

            expect(page).to have_text(
              "Flat 1, Fake Street, Springfield, Springfieldshire, TE57 2NG"
            )
          end
        end
      end

      context "when postcode search returns results" do
        before do
          stub_request(
            :get,
            "https://api.os.uk/search/places/v1/postcode?key=ABC123&postcode=TE571NG"
          )
            .to_return(
              status: 200,
              body: {
                results: [
                  {
                    DPA: {
                      ADDRESS: "123, Main Street, Springfield, TE57 1NG",
                      BUILDING_NUMBER: "123",
                      THOROUGHFARE_NAME: "Main Street",
                      POST_TOWN: "Springfield",
                      POSTCODE: "TE57 1NG"
                    }
                  }
                ]
              }.to_json,
              headers: {"Content-Type" => "application/json"}
            )
        end

        context "when the user selects an address and continues" do
          it "saves the selected address" do
            complete_journey_upto_postcode_search

            fill_in "Postcode", with: "TE57 1NG"
            click_on "Search"

            choose "123, Main Street, Springfield, TE57 1NG"
            click_on "Continue"

            complete_journey_from_address_to_check_answers

            expect(page).to have_text "123, Main Street, Springfield, TE57 1NG"
          end
        end

        context "when the user says none of the addresses are correct" do
          it "allows the user to manually enter their address" do
            complete_journey_upto_postcode_search

            fill_in "Postcode", with: "TE57 1NG"
            click_on "Search"

            click_on "I can’t find my address in the list"

            expect(page).to have_text "What is your address?"
            fill_in "House number or name", with: "Flat 1"
            fill_in "Building and street", with: "Fake Street"
            fill_in "Town or city", with: "Springfield"
            fill_in "Postcode", with: "TE57 1NG"
            click_on "Continue"

            complete_journey_from_address_to_check_answers

            expect(page).to have_text "Flat 1, Fake Street, Springfield, TE57 1NG"
          end
        end
      end

      context "when postcode search returns an error" do
        before do
          stub_request(
            :get,
            "https://api.os.uk/search/places/v1/postcode?key=ABC123&postcode=TE571NG"
          )
            .to_return(
              status: 500,
              body: ""
            )
        end

        it "allows the user to manually enter their address" do
          complete_journey_upto_postcode_search

          fill_in "Postcode", with: "TE57 1NG"
          click_on "Search"

          # On an API error we drop the claimant straight onto the manual
          # address page with a notice rather than the postcode results.
          expect(page).to have_text "What is your address?"
          expect(page).to have_text "Please enter your address manually"

          fill_in "House number or name", with: "Flat 1"
          fill_in "Building and street", with: "Fake Street"
          fill_in "Town or city", with: "Springfield"
          fill_in "Postcode", with: "TE57 1NG"
          click_on "Continue"

          complete_journey_from_address_to_check_answers

          expect(page).to have_text "Flat 1, Fake Street, Springfield, TE57 1NG"
        end
      end
    end

    context "when entering address manually" do
      it "allows the user to skip entering their postcode and manually enter their address" do
        complete_journey_upto_postcode_search

        click_on "Enter your address manually"

        expect(page).to have_text "What is your address?"
        fill_in "House number or name", with: "Flat 1"
        fill_in "Building and street", with: "Fake Street"
        fill_in "Town or city", with: "Springfield"
        fill_in "Postcode", with: "TE57 1NG"
        click_on "Continue"

        complete_journey_from_address_to_check_answers

        expect(page).to have_text "Flat 1, Fake Street, Springfield, TE57 1NG"
      end
    end
  end

  describe "changing an address" do
    context "when changing a postcode search address" do
      before do
        stub_request(
          :get,
          "https://api.os.uk/search/places/v1/postcode?key=ABC123&postcode=TE571NG"
        )
          .to_return(
            status: 200,
            body: {
              results: [
                {
                  DPA: {
                    ADDRESS: "123, Main Street, Springfield, TE57 1NG",
                    BUILDING_NUMBER: "123",
                    THOROUGHFARE_NAME: "Main Street",
                    POST_TOWN: "Springfield",
                    POSTCODE: "TE57 1NG"
                  }
                },
                {
                  DPA: {
                    ADDRESS: "125, Main Street, Springfield, TE57 1NG",
                    BUILDING_NUMBER: "125",
                    THOROUGHFARE_NAME: "Main Street",
                    POST_TOWN: "Springfield",
                    POSTCODE: "TE57 1NG"
                  }
                }
              ]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        stub_request(
          :get,
          "https://api.os.uk/search/places/v1/postcode?key=ABC123&postcode=TE579NG"
        )
          .to_return(
            status: 200,
            body: {
              results: [
                {
                  DPA: {
                    ADDRESS: "1, New Road, Newtown, TE57 9NG",
                    BUILDING_NUMBER: "1",
                    THOROUGHFARE_NAME: "New Road",
                    POST_TOWN: "Newtown",
                    POSTCODE: "TE57 9NG"
                  }
                }
              ]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      context "when the user searches again with a new postcode" do
        it "clears the stored address and forces a new selection" do
          complete_journey_selecting_postcode_address

          click_on change_address_link

          # Change drops the user back onto the postcode search, pre-filled
          # with the postcode they previously searched.
          expect(page).to have_field("Postcode", with: "TE57 1NG")

          fill_in "Postcode", with: "TE57 9NG"
          click_on "Search"

          # Changing the postcode clears the previously selected address, so
          # the user cannot continue until they pick a new one.
          click_on "Continue"
          expect(page).to have_text "Select an address"
        end

        context "when the user picks a new address" do
          it "saves the new address" do
            complete_journey_selecting_postcode_address

            click_on change_address_link

            fill_in "Postcode", with: "TE57 9NG"
            click_on "Search"

            choose "1, New Road, Newtown, TE57 9NG"
            click_on "Continue"

            expect(page).to have_text check_answers_heading
            expect(page).to have_text "1, New Road, Newtown, TE57 9NG"
            expect(page).not_to have_text "123, Main Street, Springfield, TE57 1NG"
          end
        end
      end

      context "when the user searches again with the same postcode" do
        context "when the user selects a different address and continues" do
          it "saves the newly selected address" do
            complete_journey_selecting_postcode_address

            click_on change_address_link

            fill_in "Postcode", with: "TE57 1NG"
            click_on "Search"

            choose "125, Main Street, Springfield, TE57 1NG"
            click_on "Continue"

            expect(page).to have_text check_answers_heading
            expect(page).to have_text "125, Main Street, Springfield, TE57 1NG"
            expect(page).not_to have_text "123, Main Street, Springfield, TE57 1NG"
          end
        end

        context "when the user selects the same address and continues" do
          it "keeps the same address" do
            complete_journey_selecting_postcode_address

            click_on change_address_link

            fill_in "Postcode", with: "TE57 1NG"
            click_on "Search"

            choose "123, Main Street, Springfield, TE57 1NG"
            click_on "Continue"

            expect(page).to have_text check_answers_heading
            expect(page).to have_text "123, Main Street, Springfield, TE57 1NG"
          end
        end
      end

      context "when none of the addresses are correct" do
        it "lets the user enter their address manually" do
          complete_journey_selecting_postcode_address

          click_on change_address_link

          fill_in "Postcode", with: "TE57 1NG"
          click_on "Search"

          click_on "I can’t find my address in the list"

          expect(page).to have_text "What is your address?"
          fill_in "House number or name", with: "Flat 2"
          fill_in "Building and street", with: "Other Street"
          fill_in "Town or city", with: "Springfield"
          fill_in "Postcode", with: "TE57 1NG"

          click_on "Continue"

          expect(page).to have_text check_answers_heading
          expect(page).to have_text "Flat 2, Other Street, Springfield, TE57 1NG"
        end
      end

      context "when the user now chooses to enter their address manually" do
        it "lets the user enter their address manually" do
          complete_journey_selecting_postcode_address

          click_on change_address_link

          click_on "Enter your address manually"

          expect(page).to have_text "What is your address?"
          fill_in "House number or name", with: "Flat 2"
          fill_in "Building and street", with: "Other Street"
          fill_in "Town or city", with: "Springfield"
          fill_in "Postcode", with: "TE57 1NG"
          click_on "Continue"

          expect(page).to have_text check_answers_heading
          expect(page).to have_text "Flat 2, Other Street, Springfield, TE57 1NG"
        end
      end
    end

    context "when changing a manually entered address" do
      context "when the user updates their address details and continues" do
        it "saves the updated address" do
          complete_journey_entering_manual_address

          click_on change_address_link

          expect(page).to have_text "What is your address?"
          expect(page).to have_field("House number or name", with: "Flat 1")

          fill_in "House number or name", with: "Flat 99"
          fill_in "Building and street", with: "Updated Street"
          fill_in "Town or city", with: "Newville"
          fill_in "Postcode", with: "NE1 6EE"
          click_on "Continue"

          expect(page).to have_text check_answers_heading
          expect(page).to have_text "Flat 99, Updated Street, Newville, NE1 6EE"
        end
      end

      context "when there has been an api error" do
        it "doesn't show the postcode search form" do
          stub_request(
            :get,
            "https://api.os.uk/search/places/v1/postcode?key=ABC123&postcode=TE571NG"
          )
            .to_return(status: 500, body: "")

          complete_journey_upto_postcode_search

          fill_in "Postcode", with: "TE57 1NG"
          click_on "Search"

          # The API error forces the claimant onto the manual address page.
          expect(page).to have_text "What is your address?"
          fill_in "House number or name", with: "Flat 1"
          fill_in "Building and street", with: "Fake Street"
          fill_in "Town or city", with: "Springfield"
          fill_in "Postcode", with: "TE57 1NG"
          click_on "Continue"

          complete_journey_from_address_to_check_answers

          click_on change_address_link

          # Having entered their address manually, changing it returns them to
          # the manual page, never the postcode search.
          expect(page).to have_text "What is your address?"
          expect(page).not_to have_text "What is your home address?"
          expect(page).not_to have_button "Search"
        end
      end
    end
  end

  def complete_journey_selecting_postcode_address
    complete_journey_upto_postcode_search

    fill_in "Postcode", with: "TE57 1NG"
    click_on "Search"

    choose "123, Main Street, Springfield, TE57 1NG"
    click_on "Continue"

    complete_journey_from_address_to_check_answers
  end

  def complete_journey_entering_manual_address
    complete_journey_upto_postcode_search

    click_on "Enter your address manually"

    fill_in "House number or name", with: "Flat 1"
    fill_in "Building and street", with: "Fake Street"
    fill_in "Town or city", with: "Springfield"
    fill_in "Postcode", with: "TE57 1NG"
    click_on "Continue"

    complete_journey_from_address_to_check_answers
  end
end
