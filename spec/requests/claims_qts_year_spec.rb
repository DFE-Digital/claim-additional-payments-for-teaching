require "rails_helper"

RSpec.describe "The QTS year question", type: :request do
  let(:maths_and_physics_configuration) { policy_configurations(:maths_and_physics) }

  it "changes the QTS year option labels based on the current academic year the policy is accepting claims for" do
    maths_and_physics_configuration.update!(current_academic_year: "2019/2020")
    start_claim(MathsAndPhysics)

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
