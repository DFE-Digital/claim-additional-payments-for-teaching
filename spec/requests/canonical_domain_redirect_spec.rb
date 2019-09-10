require "rails_helper"

RSpec.describe "Canonical domain redirect", type: :request do
  before(:all) do
    ENV["CANONICAL_HOSTNAME"] = "http://teacherpayments.com"
    Rails.application.reload_routes!
  end

  after(:all) do
    ENV["CANONICAL_HOSTNAME"] = ""
    Rails.application.reload_routes!
  end

  it "redirects to the canonical domain" do
    expect(get("http://example.org/")).to redirect_to("http://teacherpayments.com/")
    expect(response.status).to eq(301)
  end

  it "keeps the original path" do
    expect(get("http://example.org/cookies")).to redirect_to("http://teacherpayments.com/cookies")
    expect(response.status).to eq(301)
  end

  it "keeps query strings in place" do
    expect(get("http://example.org/cookies?foo=bar")).to redirect_to("http://teacherpayments.com/cookies?foo=bar")
    expect(response.status).to eq(301)
  end
end
