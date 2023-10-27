require "rails_helper"

RSpec.describe DfeIdentity::ClaimUserDetailsUpdater do
  describe ".call" do
    let(:claim) { create(:claim) }

    it "updates the claim with teacher ID user info" do
      teacher_id_user_info = {
        "given_name" => "John",
        "family_name" => "Doe",
        "trn" => "123456",
        "birthdate" => "1990-01-01",
        "ni_number" => "AB123456C",
        "trn_match_ni_number" => "True"
      }
      allow(claim).to receive(:teacher_id_user_info).and_return(teacher_id_user_info)

      expect {
        described_class.call(claim)
      }.to change { claim.first_name }.to("John")
        .and change { claim.surname }.to("Doe")
        .and change { claim.teacher_reference_number }.to("123456")
        .and change { claim.date_of_birth }.to(Date.new(1990, 1, 1))
        .and change { claim.national_insurance_number }.to("AB123456C")
        .and change { claim.logged_in_with_tid }.to(true)
    end

    it "updates the claim with the saved teacher ID user info" do
      claim = create(:claim, :with_valid_teacher_id_user_info)

      expect {
        described_class.call(claim)
      }.to change { claim.first_name }.to("John")
        .and change { claim.surname }.to("Doe")
        .and change { claim.teacher_reference_number }.to("123456")
        .and change { claim.date_of_birth }.to(Date.new(1990, 1, 1))
        .and change { claim.national_insurance_number }.to("AB123456C")
        .and change { claim.logged_in_with_tid }.to(true)
    end

    it "does not update the claim if user info is not validated" do
      claim = create(:claim, :with_invalid_teacher_id_user_info)

      expect {
        described_class.call(claim)
      }.not_to change { claim.reload }
    end
  end
end
