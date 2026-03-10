require "rails_helper"

RSpec.describe Claims::VerifyPersonalBankAccountJob, type: :job do
  before do
    stub_request(:post, "https://test-api.service.hmrc.gov.uk/oauth/token")
      .with(
        body: {
          "client_id" => "test",
          "client_secret" => "test",
          "grant_type" => "client_credentials"
        }
      ).to_return(
        status: 200,
        body: {
          access_token: "abc123",
          expires_in: 3600
        }.to_json
      )
  end

  describe "#perform" do
    context "when bank details have been validated" do
      let(:claim) { create(:claim, hmrc_bank_validation_succeeded: true) }

      before do
        described_class.perform_now(claim)
      end

      it "doesn't make a new request" do
        expect(
          a_request(:post, "https://test-api.service.hmrc.gov.uk/misc/bank-account/verify/personal")
        ).not_to have_been_made
      end

      it "doesn't record a new hmrc bank validation response" do
        expect(claim.hmrc_bank_validation_responses.count).to eq 0
      end
    end

    context "when the bank details have not been validated" do
      let(:claim) do
        create(
          :claim,
          hmrc_bank_validation_succeeded: false,
          bank_account_number: "12345678",
          bank_sort_code: "123456",
          banking_name: "Test Name"
        )
      end

      context "when the response is successful" do
        before do
          stub_request(
            :post, "https://test-api.service.hmrc.gov.uk/misc/bank-account/verify/personal"
          ).with(
            body: {
              account: {
                sortCode: "123456",
                accountNumber: "12345678"
              },
              subject: {
                name: "Test Name"
              }
            }.to_json
          ).to_return(
            status: 200,
            body: {
              nameMatches: "yes",
              sortCodeIsPresentOnEISCD: "yes",
              accountExists: "yes"
            }.to_json
          )

          described_class.perform_now(claim)
        end

        it "sets `Claim#hmrc_bank_validation_succeeded` to true" do
          expect(claim.reload.hmrc_bank_validation_succeeded).to be true
        end

        it "records a new hmrc bank validation response" do
          expect(claim.hmrc_bank_validation_responses.count).to eq 1

          expect(claim.hmrc_bank_validation_responses.first).to include(
            "code" => 200,
            "body" => {
              "nameMatches" => "yes",
              "sortCodeIsPresentOnEISCD" => "yes",
              "accountExists" => "yes"
            }
          )
        end
      end

      context "when the response is not successful" do
        context "when the details don't match" do
          before do
            stub_request(
              :post, "https://test-api.service.hmrc.gov.uk/misc/bank-account/verify/personal"
            ).with(
              body: {
                account: {
                  sortCode: "123456",
                  accountNumber: "12345678"
                },
                subject: {
                  name: "Test Name"
                }
              }.to_json
            ).to_return(
              status: 200,
              body: {
                nameMatches: "yes",
                sortCodeIsPresentOnEISCD: "no",
                accountExists: "yes"
              }.to_json
            )

            described_class.perform_now(claim)
          end

          it "sets `Claim#hmrc_bank_validation_succeeded` to false" do
            expect(claim.reload.hmrc_bank_validation_succeeded).to be false
          end

          it "records a new hmrc bank validation response" do
            expect(claim.hmrc_bank_validation_responses.count).to eq 1

            expect(claim.hmrc_bank_validation_responses.first).to include(
              "code" => 200,
              "body" => {
                "nameMatches" => "yes",
                "sortCodeIsPresentOnEISCD" => "no",
                "accountExists" => "yes"
              }
            )
          end
        end

        context "when the repsonse is an error" do
          before do
            stub_request(
              :post, "https://test-api.service.hmrc.gov.uk/misc/bank-account/verify/personal"
            ).with(
              body: {
                account: {
                  sortCode: "123456",
                  accountNumber: "12345678"
                },
                subject: {
                  name: "Test Name"
                }
              }.to_json
            ).to_return(
              status: 403,
              body: ""
            )

            described_class.perform_now(claim)
          end

          it "sets `Claim#hmrc_bank_validation_succeeded` to false" do
            expect(claim.reload.hmrc_bank_validation_succeeded).to be false
          end

          it "records a new hmrc bank validation response" do
            expect(claim.hmrc_bank_validation_responses.count).to eq 1

            expect(claim.hmrc_bank_validation_responses.first).to include(
              "code" => 403,
              "body" => ""
            )
          end
        end
      end
    end
  end
end
