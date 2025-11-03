require "rails_helper"

RSpec.describe "Static pages", type: :request do
  %i[terms_conditions cookies accessibility_statement contact_us].each do |static_page|
    it "renders the #{static_page} page for the student loans policy" do
      get public_send(:"#{static_page}_path", Journeys::TeacherStudentLoanReimbursement.routing_name)

      expect(response).to be_successful
      expect(response.body).to include("Teachers: claim back your student loan repayments")
    end
  end
end
