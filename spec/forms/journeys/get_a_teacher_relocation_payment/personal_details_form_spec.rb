require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::PersonalDetailsForm, type: :model do
  let(:journey_session) { build(:get_a_teacher_relocation_payment_session) }

  subject(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::GetATeacherRelocationPayment,
      params: ActionController::Parameters.new({})
    )
  end

  describe "validations" do
    before do
      form.assign_attributes(
        day: date_of_birth.day,
        month: date_of_birth.month,
        year: date_of_birth.year
      )

      form.valid?
    end

    context "with too young of a birth date" do
      let(:date_of_birth) { 20.years.ago }

      it "does not permit the date of birth" do
        expect(form.errors[:date_of_birth]).to include("Age must be above 21")
      end
    end

    context "with too old of a birth date" do
      let(:date_of_birth) { 80.years.ago }

      it "does not permit the date of birth" do
        expect(form.errors[:date_of_birth]).to include("Age must be below 80")
      end
    end

    context "with a valid birth date" do
      let(:date_of_birth) { 30.years.ago }

      it "permits the date of birth" do
        expect(form.errors[:date_of_birth]).to be_empty
      end
    end
  end
end
