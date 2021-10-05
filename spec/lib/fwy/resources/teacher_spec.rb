require 'rails_helper'

RSpec.describe Fwy::TeacherResource, type: :request do
  let(:trn)    { 1001000 }
  let(:stub)   { stub_request("teachers/#{trn}", response: stub_response(fixture: "teachers/find")) }
  let(:client) { Fwy::Client.new(adapter: :test, stubs: stub) }

  let(:expected_attributes) do
    {
      date_of_birth: Date.new(1996,7,2),
      first_name: "Mostly",
      surname: "Populated",
      qts_date: Date.new(2021,7,5),
      itt_subject_codes: [
        "applied biology",
        "applied chemistry",
        "applied computing"
      ],
      itt_date: Date.new(2021,6,27),
      qualification_name: "BA (Hons)",
      degree_codes: [],
      national_insurance_number: "AB123456D",
      teacher_reference_number: "1001000",
      active_alert: false
    }
  end

  before do
    allow(Fwy::Bearer).to receive(:get_auth_token).and_return("auth_token")
  end

  describe "#find" do
    let(:subject) { described_class.new(client).find(trn) }
    
    it "returns the expected atttributes" do
      expected_attributes.each do |k,v|
        expect(subject.send(k)).to eql(v)
      end
    end
  end
end