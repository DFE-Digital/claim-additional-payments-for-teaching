require "rails_helper"

RSpec.describe "Requests when basic auth environment variables are present", type: :request do
  around do |example|
    ClimateControl.modify BASIC_AUTH_USERNAME: "username", BASIC_AUTH_PASSWORD: "password" do
      example.run
    end
  end

  it "doesn't require basic for student-loan requests" do
    get new_claim_path(StudentLoans.routing_name)
    expect(response).to be_successful

    get privacy_notice_path(StudentLoans.routing_name)
    expect(response).to be_successful
  end

  it "requires basic auth for maths-and-physics requests" do
    authorised_headers = {
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("username", "password"),
    }

    get new_claim_path(MathsAndPhysics.routing_name)
    expect(response).to be_unauthorized

    get privacy_notice_path(MathsAndPhysics.routing_name)
    expect(response).to be_unauthorized

    get new_claim_path(MathsAndPhysics.routing_name), params: {}, headers: authorised_headers
    expect(response).to be_successful
  end
end
