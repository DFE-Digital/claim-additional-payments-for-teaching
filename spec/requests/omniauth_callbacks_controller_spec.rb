require "rails_helper"

RSpec.describe "OmniauthCallbacksControllers", type: :request do
  describe "#sign_out" do
    let(:claim_id) { "1234-1234-1234-1234" }

    before do
      answers_with_claim = double(claim: double(id: claim_id))
      journey_session_with_answers_and_claim = double(answers: answers_with_claim)
      allow_any_instance_of(OmniauthCallbacksController).to receive(:current_journey_routing_name).and_return(journey)
      allow_any_instance_of(OmniauthCallbacksController).to receive(:journey_session).and_return(journey_session_with_answers_and_claim)

      get auth_sign_out_path(journey: "further-education-payments-provider")
    end

    context "no journey returns a 404" do
      let(:journey) { nil }

      it "404 page" do
        expect(response.body).to include("Page not found")
      end
    end
  end

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

        allow_any_instance_of(OmniauthCallbacksController).to receive(:current_journey_routing_name).and_return(Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME)
      end

      it "redirects to the claim path with correct parameters" do
        get claim_auth_tid_callback_path

        expect(response).to redirect_to(
          claim_path(
            journey: "targeted-retention-incentive-payments",
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

      context "when the journey session is missing" do
        it "renders problem with service page" do
          get "/auth/failure?message=access_denied&origin=http%3A%2F%2Flocalhost%3A3000%2Ffurther-education-payments%2Fsign-in&strategy=onelogin"

          expect(response.body).to include("Sorry, there is a problem with the One Login service")
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

      it "sets timestamp onelogin_auth_at" do
        journey_session = Journeys::FurtherEducationPayments::Session.last

        expect {
          get auth_onelogin_path
        }.to change { journey_session.reload.answers.onelogin_auth_at }.from(nil).to(be_within(10.seconds).of(Time.now))
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
          last_name: "Doe"
        )

        allow(OneLogin::CoreIdentityValidator).to receive(:new).and_return(validator_double)

        get auth_onelogin_path

        expect(response).to redirect_to("http://www.example.com/auth/failure?strategy=onelogin&message=access_denied&origin=http://www.example.com/further-education-payments/sign-in")
      end

      it "sets timestamp onelogin_idv_* variables" do
        journey_session = Journeys::FurtherEducationPayments::Session.last
        journey_session.answers.onelogin_uid = "12345"
        journey_session.save!

        validator_double = double(
          OneLogin::CoreIdentityValidator,
          call: nil,
          first_name: "John",
          last_name: "Doe",
          full_name: "John Doe",
          date_of_birth: Date.new(1970, 12, 13)
        )

        allow(OneLogin::CoreIdentityValidator).to receive(:new).and_return(validator_double)

        expect {
          get auth_onelogin_path
        }.to change { journey_session.reload.answers.onelogin_idv_at }.from(nil).to(be_within(10.seconds).of(Time.now))
          .and change { journey_session.reload.answers.onelogin_idv_first_name }.from(nil).to("John")
          .and change { journey_session.reload.answers.onelogin_idv_last_name }.from(nil).to("Doe")
          .and change { journey_session.reload.answers.onelogin_idv_date_of_birth }.from(nil).to(Date.new(1970, 12, 13))
      end
    end

    context "idv step with return code present" do
      let(:omniauth_hash) do
        OmniAuth::AuthHash.new(
          "uid" => "12345",
          "extra" => {
            "raw_info" => {
              "https://vocab.account.gov.uk/v1/returnCode" => [{"code" => "ABC"}]
            }
          }
        )
      end

      it "updates session vars" do
        journey_session = Journeys::FurtherEducationPayments::Session.last
        journey_session.answers.onelogin_uid = "12345"
        journey_session.save!

        expect {
          get auth_onelogin_path
        }.to change { journey_session.reload.answers.onelogin_idv_at }.from(nil).to(be_within(10.seconds).of(Time.now))
          .and change { journey_session.reload.answers.identity_confirmed_with_onelogin }.from(nil).to(false)
          .and not_change { journey_session.reload.answers.onelogin_idv_first_name }
          .and not_change { journey_session.reload.answers.onelogin_idv_last_name }
          .and not_change { journey_session.reload.answers.onelogin_idv_date_of_birth }
      end

      it "updates return codes stats" do
        journey_session = Journeys::FurtherEducationPayments::Session.last
        journey_session.answers.onelogin_uid = "12345"
        journey_session.save!

        expect {
          get auth_onelogin_path
        }.to change { Stats::OneLogin.count }.by(1)

        expect(Stats::OneLogin.last.one_login_return_code).to eql("ABC")
      end
    end
  end
end
