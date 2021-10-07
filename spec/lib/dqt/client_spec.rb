require 'rails_helper'

RSpec.describe Dqt::Client, type: :request do
  let(:trn) { 1001000 }

  let(:params) do
    {
      birthdate: "1966-06-06",
      nino: "AB123123A"
    }
  end

  before do
    stub_qualified_teaching_statuses_show(
      trn: trn,
      params: params
    )
  end

  describe "#teacher#find" do
    subject(:subject) do
      Dqt::Client.new.teacher.find(
        trn,
        birthdate: params[:birthdate],
        nino: params[:nino]
      ) 
    end
    
    it "does not raise an error" do
      expect { subject }.to_not raise_error
    end
  end
end