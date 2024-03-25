require "rails_helper"

RSpec.describe SelectMobileNumberForm do
  let(:claim) { instance_double("Claim", teacher_id_user_info: {"phone_number" => "123-456-7890"}) }

  describe ".extract_attributes" do
    context "when mobile_check is 'use'" do
      let(:form) { SelectMobileNumberForm.new(claim, "use") }

      it "returns the teacher's phone number and sets provide_mobile_number to true" do
        expect(form.extract_attributes).to eq({
          mobile_number: "123-456-7890",
          provide_mobile_number: true,
          mobile_check: "use",
          mobile_verified: nil
        })
      end
    end

    context "when mobile_check is 'alternative'" do
      let(:form) { SelectMobileNumberForm.new(claim, "alternative") }

      it "returns nil for mobile_number and sets provide_mobile_number to true, and sets mobile_check to 'alternative'" do
        expect(form.extract_attributes).to eq({
          mobile_number: nil,
          provide_mobile_number: true,
          mobile_check: "alternative",
          mobile_verified: nil
        })
      end
    end

    context "when mobile_check is 'declined'" do
      let(:form) { SelectMobileNumberForm.new(claim, "declined") }

      it "returns nil for mobile_number and sets provide_mobile_number to false, and sets mobile_check to 'declined'" do
        expect(form.extract_attributes).to eq({
          mobile_number: nil,
          provide_mobile_number: false,
          mobile_check: "declined",
          mobile_verified: nil
        })
      end
    end
  end
end
