require 'rails_helper'

RSpec.describe Fwy::TeacherResource, type: :request do
  let(:trn)    { 1001000 }
  let(:stub)   { stub_request("teachers/#{trn}", response: stub_response(fixture: "teachers/find")) }
  let(:client) { Fwy::Client.new(adapter: :test, stubs: stub) }

  before do
    allow(Fwy::Bearer).to receive(:get_auth_token).and_return("auth_token")
  end

  describe "#find" do
    let(:subject) { described_class.new(client) }
    it "does not raise an error" do
      byebug
      subject.find(trn)
    end
  end
end