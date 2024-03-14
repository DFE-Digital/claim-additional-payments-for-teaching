require "rails_helper"

RSpec.describe Form, type: :model do
  let(:form_model) { FactoryBot.build(:form) }

  it "is valid with valid attributes" do
    expect(form_model).to be_valid
  end

  it "is not valid without a given name" do
    form_model.given_name = nil
    expect(form_model).not_to be_valid
  end

  it "is not valid without a family name" do
    form_model.family_name = nil
    expect(form_model).not_to be_valid
  end

  it "is not valid without an email address" do
    form_model.email_address = nil
    expect(form_model).not_to be_valid
  end

  # Continue in similar fashion for all other required fields
end
