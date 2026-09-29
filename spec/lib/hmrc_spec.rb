require "rails_helper"

RSpec.describe Hmrc do
  describe "bank validations namespace" do
    it "exposes the nested bank validations client and configuration" do
      expect(Hmrc::BankValidations.client).to be_an_instance_of(Hmrc::BankValidations::Client)
      expect(Hmrc::BankValidations.configuration).to be_an_instance_of(Hmrc::BankValidations::Configuration)
    end
  end

  describe "employments namespace" do
    it "exposes the nested employment client and configuration" do
      expect(Hmrc::Employments.client).to be_an_instance_of(Hmrc::Employments::Client)
      expect(Hmrc::Employments.configuration).to be_an_instance_of(Hmrc::Employments::Configuration)
    end
  end
end
