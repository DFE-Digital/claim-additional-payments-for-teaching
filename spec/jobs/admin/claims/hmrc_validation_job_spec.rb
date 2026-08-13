require "rails_helper"

RSpec.describe Admin::Claims::HmrcValidationJob do
  let(:claim) do
    create(
      :claim,
      :submitted,
      banking_name: "Seymour Skinner",
      bank_sort_code: "010203",
      bank_account_number: "47274828",
      hmrc_bank_validation_responses: []
    )
  end

  subject(:perform_job) { described_class.new.perform(claim) }

  describe "#perform", :with_stubbed_hmrc_client do
    it "sends the claim's bank details to the HMRC API" do
      perform_job

      expect(
        a_request(
          :post,
          "#{HMRC_TEST_BASE_URL}/misc/bank-account/verify/personal"
        ).with(
          body: {
            account: {
              sortCode: "010203",
              accountNumber: "47274828"
            },
            subject: {
              name: "Seymour Skinner"
            }
          }.to_json
        )
      ).to have_been_made
    end

    it "records the response on the claim" do
      expect { perform_job }.to(
        change { claim.reload.hmrc_bank_validation_responses }
        .from([]).to(
          [
            {
              "code" => 200,
              "body" => {
                "sortCodeIsPresentOnEISCD" => "yes",
                "accountExists" => "yes",
                "nameMatches" => "yes"
              }
            }
          ]
        )
      )
    end

    context "when the details don't match" do
      let(:name_match) { false }
      let(:account_exists) { false }
      let(:sort_code_correct) { false }

      it "records the response on the claim" do
        expect { perform_job }.to(
          change { claim.reload.hmrc_bank_validation_responses }
          .from([]).to(
            [
              {
                "code" => 200,
                "body" => {
                  "sortCodeIsPresentOnEISCD" => "no",
                  "accountExists" => "no",
                  "nameMatches" => "no"
                }
              }
            ]
          )
        )
      end
    end

    context "when the claim has existing responses" do
      let(:existing_response) do
        {
          "code" => 200,
          "body" => {
            "sortCodeIsPresentOnEISCD" => "yes",
            "accountExists" => "yes",
            "nameMatches" => "no"
          }
        }
      end

      before do
        claim.update!(hmrc_bank_validation_responses: [existing_response])
      end

      it "appends the new response" do
        perform_job

        expect(claim.reload.hmrc_bank_validation_responses).to eq(
          [
            existing_response,
            {
              "code" => 200,
              "body" => {
                "sortCodeIsPresentOnEISCD" => "yes",
                "accountExists" => "yes",
                "nameMatches" => "yes"
              }
            }
          ]
        )
      end
    end
  end

  describe "#perform when the HMRC API errors", :with_failing_hmrc_bank_validation do
    it "doesn't raise an error" do
      expect { perform_job }.not_to raise_error
    end

    it "records the error response on the claim" do
      expect { perform_job }.to(
        change { claim.reload.hmrc_bank_validation_responses }
        .from([]).to([{"code" => 429, "body" => "Test failure"}])
      )
    end
  end
end
