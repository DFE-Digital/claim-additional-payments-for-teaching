require "rails_helper"

RSpec.describe SelectHomeAddressForm, type: :model do
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

  describe "#initialize" do
    context "when there's no address attributes in the params" do
      it "loads them from the journey session" do
        journey_session = create(
          :student_loans_session,
          answers: attributes_for(
            :student_loans_answers,
            address_line_1: "123",
            address_line_2: "Main Street",
            address_line_3: "Springfield",
            postcode: "TE57 1NG"
          )
        )

        form = described_class.new(
          journey: journey_session.journey_class,
          journey_session: journey_session,
          params: ActionController::Parameters.new(claim: {})
        )

        expect(form.address).to eq(
          "123, Main Street, Springfield, TE57 1NG"
        )
      end
    end
  end

  describe "#save" do
    context "when not skip_postcode_search" do
      context "when the form is valid" do
        around do |example|
          original_cache = Rails.cache
          Rails.cache = ActiveSupport::Cache::MemoryStore.new
          example.run
        ensure
          Rails.cache = original_cache
        end

        it "stores the selected address in the session" do
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

          # Populate the cache with the addresses as this form is expected to
          # read from the cahce
          PostcodeSearch.new("TE57 1NG").addresses

          journey_session = create(
            :student_loans_session,
            answers: attributes_for(
              :student_loans_answers,
              skip_postcode_search: false,
              postcode: "TE57 1NG"
            )
          )

          form = described_class.new(
            journey: journey_session.journey_class,
            journey_session: journey_session,
            params: ActionController::Parameters.new(claim: {
              address: "123, Main Street, Springfield, TE57 1NG",
              skip_postcode_search: false
            })
          )

          expect { expect(form.save).to eq(true) }.to(
            change { journey_session.reload.answers.address_line_1 }.to("123")
            .and(change { journey_session.answers.address_line_2 }.to("Main Street")
            .and(change { journey_session.answers.address_line_3 }.to("Springfield")))
          )
        end
      end
    end
  end
end
