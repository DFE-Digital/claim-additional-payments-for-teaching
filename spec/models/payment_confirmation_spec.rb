require "rails_helper"

RSpec.describe PaymentConfirmation, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:payments).with_foreign_key(:confirmation_id) }
    it { is_expected.to belong_to(:payroll_run) }
    it { is_expected.to belong_to(:created_by).class_name("DfeSignIn::User") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:scheduled_payment_date) }
  end
end
