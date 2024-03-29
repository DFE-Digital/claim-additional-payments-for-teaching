require "rails_helper"

module Policies
  module TestPolicy
    include BasePolicy

    extend self
  end
end

RSpec.describe BasePolicy, type: :model do
  describe "::to_s" do
    it do
      expect(Policies::TestPolicy.to_s).to eq("TestPolicy")
    end
  end

  describe "::policy_type" do
    it do
      expect(Policies::TestPolicy.policy_type).to eq("test-policy")
    end
  end

  describe "::short_name" do
    before do
      allow(I18n).to receive(:t)
    end

    it do
      Policies::TestPolicy.short_name

      expect(I18n).to have_received(:t).with("test_policy.policy_short_name")
    end
  end

  describe "::locale_key" do
    it do
      expect(Policies::TestPolicy.locale_key).to eq("test_policy")
    end
  end
end
