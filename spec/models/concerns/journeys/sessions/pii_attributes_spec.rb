require "rails_helper"

RSpec.describe Journeys::Sessions::PiiAttributes do
  let(:dummy_class) do
    Class.new do
      include ActiveModel::Attributes
      include Journeys::Sessions::PiiAttributes

      attribute :email, :string, pii: true
      attribute :name, :string, pii: true
      attribute :age, :integer, pii: false
    end
  end

  let(:dummy_instance) { dummy_class.new }

  describe ".attribute" do
    it "adds the attribute to the pii_attributes list if pii is true" do
      expect(dummy_class.pii_attributes).to eq([:email, :name])
    end

    it "raises an error if pii is not provided" do
      expect { dummy_class.attribute(:phone_number, :string) }.to(
        raise_error(ArgumentError)
      )
    end
  end

  describe "#attributes_with_pii_redacted" do
    it "redacts pii attributes" do
      dummy_instance.email = "test@example.com"
      dummy_instance.name = "John Doe"
      dummy_instance.age = 30

      expect(dummy_instance.attributes_with_pii_redacted).to eq(
        {
          "email" => "[PII]",
          "name" => "[PII]",
          "age" => 30
        }
      )
    end
  end
end
