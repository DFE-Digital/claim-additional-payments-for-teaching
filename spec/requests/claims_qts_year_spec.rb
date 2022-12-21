require "rails_helper"

RSpec.describe "The QTS year question", type: :request do
  let(:maths_and_physics_configuration) { create(:policy_configuration, :maths_and_physics) }
  let(:in_progress_claim) { Claim.by_policy(MathsAndPhysics).order(:created_at).last }

  it "changes the QTS year option labels based on the current academic year the policy is accepting claims for" do
    maths_and_physics_configuration.update!(current_academic_year: "2019/2020")
    start_claim(MathsAndPhysics.routing_name)

    set_slug_sequence_in_session(in_progress_claim, "qts-year")

    get claim_path(MathsAndPhysics.routing_name, "qts-year")

    expect(response.body).to include("When did you complete your initial teacher training?")
    expect(response.body).to include("In or before the academic year 2013 to 2014")
    expect(response.body).to include("In or after the academic year 2014 to 2015")

    maths_and_physics_configuration.update!(current_academic_year: "2020/2021")

    get claim_path(MathsAndPhysics.routing_name, "qts-year")
    expect(response.body).to include("In or before the academic year 2014 to 2015")
    expect(response.body).to include("In or after the academic year 2015 to 2016")
  end
end
