require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::Delta do
  subject do
    described_class.new(a:, b:)
  end

  describe "#changes" do
    let(:a) do
      build(
        :claim,
        :further_education,
        eligibility_attributes: {
          building_construction_courses: ["maths"],
          chemistry_courses: ["foo"]
        }
      )
    end

    let(:b) do
      build(
        :claim,
        :further_education,
        eligibility_attributes: {
          building_construction_courses: ["physics"],
          chemistry_courses: ["foo"]
        }
      )
    end

    it do
      expected = {
        building_construction_courses: [["maths"], ["physics"]]
      }.with_indifferent_access

      expect(subject.changes).to eql(expected)
    end
  end
end
