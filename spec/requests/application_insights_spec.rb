require "rails_helper"

RSpec.describe "Application Insights", type: :request do
  let(:app) { lambda { |env| [200, {"Content-Type" => "text/plain"}, ["OK"]] } }
  let(:request) { Rack::MockRequest.new(subject) }
  let(:send_interval) { 0.1 }
  let(:ip) { "1.1.1.1" }

  subject { ApplicationInsights::Rack::TrackRequest.new(app, "ABCDEFG", send_interval) }

  it "sends the client IP along with the rest of the data" do
    # Set up a stub for a request to Application Insights that includes the
    # client IP. The request is gzipped, so requires us to expand the response
    # and then check the contents of the json
    stub = stub_request(:post, ApplicationInsights::Channel::AsynchronousSender::SERVICE_ENDPOINT_URI).with { |req|
      body = Zlib::GzipReader.new(StringIO.new(req.body)).readlines
      json = JSON.parse(body[0])
      json[0]["data"]["baseData"]["properties"]["clientIp"] == ip
    }
    request.get("/", {"REMOTE_ADDR" => ip})
    # The Application Insights requests are sent asynchronously, so we need to
    # sleep for the value of `send_interval` (which is how often the logs are sent)
    # before we check the stub has been requested, which will happen as soon as the
    # `send_interval` has passed.
    sleep(send_interval)
    expect(stub).to have_been_requested.once
  end
end
