require "rails_helper"

RSpec.describe EmploymentDetailsStep, type: :model do
  subject(:step) { described_class.new(form) }

  let(:form) { build(:form) }

  include_examples "behaves like a step",
                   described_class,
                   route_key: "employment-details",
                   required_fields: %i[
                     school_name
                     school_headteacher_name
                     school_address_line_1
                     school_city
                     school_postcode
                   ],
                   optional_fields: %i[school_address_line_2],
                   question: "Employment information",
                   question_type: :multi,
                   template: "step/employment_details"

  describe "additional validations" do
    describe "school_postcode" do
      let(:form) { build(:form, school_postcode:) }
      let(:error) { step.errors.messages_for(:school_postcode) }

      before { step.valid? }

      context "valid" do
        let(:school_postcode) { "SW1A 1AA" }

        it { expect(error).to be_blank }
      end

      context "invalid" do
        let(:school_postcode) { "invalid" }

        it { expect(error).to be_present }
      end
    end
  end
end
