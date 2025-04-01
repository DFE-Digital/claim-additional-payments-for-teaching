require "rails_helper"

RSpec.describe ApplicationController do
  controller do
    def index
      head :ok
    end
  end

  it "sets security headers" do
    get :index

    expect(response.headers["Strict-Transport-Security"]).to be_present
    expect(response.headers["X-Frame-Options"]).to be_present
    expect(response.headers["X-Content-Type-Options"]).to be_present
    expect(response.headers["X-XSS-Protection"]).to be_present
  end
end
