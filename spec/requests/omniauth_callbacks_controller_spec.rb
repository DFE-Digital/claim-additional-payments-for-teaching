require "rails_helper"

RSpec.describe "OmniauthCallbacksControllers", type: :request do
  describe "#callback" do
    def set_mock_auth(trn)
      OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new(
        "extra" => {
          "raw_info" => {
            "trn" => trn
          }
        }
      )
      Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:default]
    end

    context "when trn is not nil" do
      before do
        set_mock_auth("1234567")

        allow_any_instance_of(OmniauthCallbacksController).to receive(:current_journey_routing_name).and_return(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
      end

      it "redirects to the claim path with correct parameters" do
        get claim_auth_tid_callback_path

        expect(response).to redirect_to(
          claim_path(
            journey: "additional-payments",
            slug: "sign-in-or-continue",
            claim: {
              logged_in_with_tid: true,
              teacher_id_user_info_attributes: {
                trn: "1234567"
              }
            }
          )
        )
      end
    end

    context "when trn is nil" do
      before do
        set_mock_auth(nil)

        allow_any_instance_of(OmniauthCallbacksController).to receive(:current_journey_routing_name).and_return(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)
      end

      it "redirects to the claim path with correct parameters" do
        get claim_auth_tid_callback_path

        expect(response).to redirect_to(
          claim_path(
            journey: "student-loans",
            slug: "sign-in-or-continue",
            claim: {
              logged_in_with_tid: true,
              teacher_id_user_info_attributes: {
                trn: nil
              }
            }
          )
        )
      end
    end

    context "auth failure csrf detected" do
      it "redirects to /auth/failure" do
        OmniAuth.config.mock_auth[:default] = :csrf_detected

        get claim_auth_tid_callback_path

        expect(response).to redirect_to(
          auth_failure_path(message: "csrf_detected", strategy: "tid")
        )
      end
    end
  end

  describe "#failure" do
    context "FE journey" do
      before do
        create(:journey_configuration, :further_education_payments)
      end

      context "when onelogin auth fail" do
        it "renders problem with service page" do
          get "/further-education-payments/claim"

          get "/auth/failure?message=access_denied&origin=http%3A%2F%2Flocalhost%3A3000%2Ffurther-education-payments%2Fsign-in&strategy=onelogin"

          expect(response.body).to include("Sorry, there is a problem with the service")
        end
      end

      context "when onelogin idv fail" do
        it "renders cannot progress page" do
          get "/further-education-payments/claim"

          journey_session = Journeys::FurtherEducationPayments::Session.last
          journey_session.answers.logged_in_with_onelogin = true
          journey_session.save!

          get "/auth/failure?message=access_denied&origin=http%3A%2F%2Flocalhost%3A3000%2Ffurther-education-payments%2Fsign-in&strategy=onelogin"

          expect(response.body).to include("We cannot progress your application")
        end
      end
    end
  end

  describe "#onelogin" do
    let(:omniauth_hash) do
      OmniAuth::AuthHash.new(
        "uid" => "12345",
        "extra" => {
          "raw_info" => {}
        }
      )
    end

    before do
      OmniAuth.config.mock_auth[:onelogin] = omniauth_hash
      Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:onelogin]

      allow(OneLoginSignIn).to receive(:bypass?).and_return(false)

      create(:journey_configuration, :further_education_payments)
      get "/further-education-payments/claim"
    end

    context "signing in" do
      it "sets onelogin_uid from omniauth hash" do
        journey_session = Journeys::FurtherEducationPayments::Session.last

        expect {
          get auth_onelogin_path
        }.to change { journey_session.reload.answers.onelogin_uid }.from(nil).to("12345")
      end
    end

    context "idv step" do
      let(:omniauth_hash) do
        OmniAuth::AuthHash.new(
          "uid" => "12345",
          "extra" => {
            "raw_info" => {
              "https://vocab.account.gov.uk/v1/coreIdentityJWT" => ""
            }
          }
        )
      end

      it "ensure idv matches logged in user" do
        journey_session = Journeys::FurtherEducationPayments::Session.last
        journey_session.answers.onelogin_uid = "54321"
        journey_session.save!

        validator_double = double(
          OneLogin::CoreIdentityValidator,
          call: nil,
          first_name: "John",
          surname: "Doe"
        )

        allow(OneLogin::CoreIdentityValidator).to receive(:new).and_return(validator_double)

        get auth_onelogin_path

        expect(response).to redirect_to("http://www.example.com/auth/failure?strategy=onelogin&message=access_denied&origin=http://www.example.com/further-education-payments/sign-in")
      end
    end
  end
end
