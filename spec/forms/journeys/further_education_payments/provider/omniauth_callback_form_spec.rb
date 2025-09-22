require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::Provider::OmniauthCallbackForm do
  let(:school) { create(:school, ukprn: "123456") }

  let(:claim) do
    create(
      :claim,
      policy: Policies::FurtherEducationPayments,
      eligibility_attributes: {
        school: school
      }
    )
  end

  let(:journey_session) do
    create(
      :further_education_payments_provider_session,
      answers: {
        claim_id: claim.id
      }
    )
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      auth: auth
    )
  end

  describe "#save!" do
    before do
      allow(DfeSignIn::Api::User).to receive(:new).and_return(dfe_sign_in_user)
    end

    let(:dfe_sign_in_user) do
      instance_double(
        DfeSignIn::Api::User,
        service_access?: service_access,
        role_codes: ["teacher_payments_claim_verifier"]
      )
    end

    let(:auth) do
      OmniAuth::AuthHash.new(
        "uid" => "11111",
        "info" => {
          "email" => "seymore.skinner@springfield-elementary.edu",
          "first_name" => info_first_name,
          "last_name" => info_last_name
        },
        "extra" => {
          "raw_info" => {
            "organisation" => {
              "id" => "22222",
              "ukprn" => "12345678",
              "name" => "Springfield Elementary"
            }
          }
        }
      )
    end

    context "with access to the service" do
      let(:service_access) { true }

      context "when the info payload contains the user's name" do
        let(:info_first_name) { "Seymoure" }
        let(:info_last_name) { "Skinner" }

        it "updates the session with the auth details from dfe signin" do
          expect { form.save! }.to(
            change(journey_session.answers, :dfe_sign_in_uid).from(nil).to("11111").and(
              change(journey_session.answers, :dfe_sign_in_organisation_ukprn)
                .from(nil)
                .to("12345678")
            ).and(
              change(journey_session.answers, :dfe_sign_in_organisation_id)
                .from(nil)
                .to("22222")
            ).and(
              change(journey_session.answers, :dfe_sign_in_organisation_name)
                .from(nil)
                .to("Springfield Elementary")
            ).and(
              change(journey_session.answers, :dfe_sign_in_service_access?)
                .from(false)
                .to(true)
            ).and(
              change(journey_session.answers, :dfe_sign_in_role_codes)
                .from([])
                .to(["teacher_payments_claim_verifier"])
            ).and(
              change(journey_session.answers, :dfe_sign_in_first_name)
                .from(nil)
                .to("Seymoure")
            ).and(
              change(journey_session.answers, :dfe_sign_in_last_name)
                .from(nil)
                .to("Skinner")
            ).and(
              change(journey_session.answers, :dfe_sign_in_email)
                .from(nil)
              .to("seymore.skinner@springfield-elementary.edu")
            )
          )
        end
      end

      context "when the info payload does not contain the user's name" do
        let(:info_first_name) { nil }
        let(:info_last_name) { nil }

        before do
          stub_request(
            :get,
            "https://example.com/organisations/123456/users?email=seymore.skinner%40springfield-elementary.edu"
          ).to_return(
            status: status,
            body: body.to_json
          )
        end

        context "when the dfe api request isn't successful" do
          let(:status) { 404 }
          let(:body) do
            {}
          end

          it "updates the session with the auth details from dfe signin" do
            expect { form.save! }.to(
              change(journey_session.answers, :dfe_sign_in_uid).from(nil).to("11111").and(
                change(journey_session.answers, :dfe_sign_in_organisation_ukprn)
                  .from(nil)
                  .to("12345678")
              ).and(
                change(journey_session.answers, :dfe_sign_in_organisation_id)
                  .from(nil)
                  .to("22222")
              ).and(
                change(journey_session.answers, :dfe_sign_in_organisation_name)
                  .from(nil)
                  .to("Springfield Elementary")
              ).and(
                change(journey_session.answers, :dfe_sign_in_service_access?)
                  .from(false)
                  .to(true)
              ).and(
                change(journey_session.answers, :dfe_sign_in_role_codes)
                  .from([])
                  .to(["teacher_payments_claim_verifier"])
              ).and(
                not_change(journey_session.answers, :dfe_sign_in_first_name)
                  .from(nil)
              ).and(
                not_change(journey_session.answers, :dfe_sign_in_last_name)
                  .from(nil)
              ).and(
                change(journey_session.answers, :dfe_sign_in_email)
                  .from(nil)
                .to("seymore.skinner@springfield-elementary.edu")
              )
            )
          end
        end

        # Edge case: I don't think this can happen IRL as the user has just signed into that org!
        context "when the dfe api request doesn't include the user" do
          let(:status) { 200 }
          let(:body) do
            {
              "ukprn" => "12345678",
              "users" => [
                {
                  "email" => "someone-else@springfield-elementary.edu",
                  "firstName" => "Seymoure",
                  "lastName" => "Skinner",
                  "userStatus" => 1,
                  "roles" => ["teacher_payments_claim_verifier"]
                }
              ]
            }
          end

          it "updates the session with the auth details from dfe signin" do
            expect { form.save! }.to(
              change(journey_session.answers, :dfe_sign_in_uid).from(nil).to("11111").and(
                change(journey_session.answers, :dfe_sign_in_organisation_ukprn)
                  .from(nil)
                  .to("12345678")
              ).and(
                change(journey_session.answers, :dfe_sign_in_organisation_id)
                  .from(nil)
                  .to("22222")
              ).and(
                change(journey_session.answers, :dfe_sign_in_organisation_name)
                  .from(nil)
                  .to("Springfield Elementary")
              ).and(
                change(journey_session.answers, :dfe_sign_in_service_access?)
                  .from(false)
                  .to(true)
              ).and(
                change(journey_session.answers, :dfe_sign_in_role_codes)
                  .from([])
                  .to(["teacher_payments_claim_verifier"])
              ).and(
                not_change(journey_session.answers, :dfe_sign_in_first_name)
                  .from(nil)
              ).and(
                not_change(journey_session.answers, :dfe_sign_in_last_name)
                  .from(nil)
              ).and(
                change(journey_session.answers, :dfe_sign_in_email)
                  .from(nil)
                .to("seymore.skinner@springfield-elementary.edu")
              )
            )
          end
        end

        context "when the dfe api request is successful" do
          let(:status) { 200 }
          let(:body) do
            {
              "ukprn" => "12345678",
              "users" => [
                {
                  "email" => "seymore.skinner@springfield-elementary.edu",
                  "firstName" => "Seymoure",
                  "lastName" => "Skinner",
                  "userStatus" => 1,
                  "roles" => ["teacher_payments_claim_verifier"]
                }
              ]
            }
          end

          it "updates the session with the auth details from dfe signin" do
            expect { form.save! }.to(
              change(journey_session.answers, :dfe_sign_in_uid).from(nil).to("11111").and(
                change(journey_session.answers, :dfe_sign_in_organisation_ukprn)
                  .from(nil)
                  .to("12345678")
              ).and(
                change(journey_session.answers, :dfe_sign_in_organisation_id)
                  .from(nil)
                  .to("22222")
              ).and(
                change(journey_session.answers, :dfe_sign_in_organisation_name)
                  .from(nil)
                  .to("Springfield Elementary")
              ).and(
                change(journey_session.answers, :dfe_sign_in_service_access?)
                  .from(false)
                  .to(true)
              ).and(
                change(journey_session.answers, :dfe_sign_in_role_codes)
                  .from([])
                  .to(["teacher_payments_claim_verifier"])
              ).and(
                change(journey_session.answers, :dfe_sign_in_first_name)
                  .from(nil)
                  .to("Seymoure")
              ).and(
                change(journey_session.answers, :dfe_sign_in_last_name)
                  .from(nil)
                  .to("Skinner")
              ).and(
                change(journey_session.answers, :dfe_sign_in_email)
                  .from(nil)
                .to("seymore.skinner@springfield-elementary.edu")
              )
            )
          end
        end
      end
    end

    context "without access to the service" do
      let(:service_access) { false }
      let(:info_first_name) { "Seymoure" }
      let(:info_last_name) { "Skinner" }

      it "sets the service access flag to false" do
        expect { form.save! }.to(
          change(journey_session.answers, :dfe_sign_in_uid).from(nil).to("11111").and(
            change(journey_session.answers, :dfe_sign_in_organisation_ukprn)
              .from(nil)
              .to("12345678")
          ).and(
            change(journey_session.answers, :dfe_sign_in_organisation_id)
              .from(nil)
              .to("22222")
          ).and(
            not_change(journey_session.answers, :dfe_sign_in_service_access?)
          ).and(
            not_change(journey_session.answers, :dfe_sign_in_role_codes)
          ).and(
            change(journey_session.answers, :dfe_sign_in_first_name)
              .from(nil)
              .to("Seymoure")
          ).and(
            change(journey_session.answers, :dfe_sign_in_last_name)
              .from(nil)
              .to("Skinner")
          ).and(
            change(journey_session.answers, :dfe_sign_in_email)
              .from(nil)
            .to("seymore.skinner@springfield-elementary.edu")
          )
        )
      end
    end
  end
end
