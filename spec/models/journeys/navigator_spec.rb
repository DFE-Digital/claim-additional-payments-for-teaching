require "rails_helper"

RSpec.describe Journeys::Navigator do
  subject { described_class.new(current_slug:, slug_sequence:, params:, session:) }

  let(:current_slug) { "teaching-responsibilities" }
  let(:slug_sequence) { Journeys::FurtherEducationPayments::SlugSequence.new(journey_session) }
  let(:params) { ActionController::Parameters.new }
  let(:session) { {} }
  let(:journey_session) do
    create(:further_education_payments_session, answers: answers)
  end

  describe "#next_slug" do
    context "starting journey" do
      let(:answers) do
        build(
          :further_education_payments_answers
        )
      end

      it "returns first slug" do
        expect(subject.next_slug).to eql("teaching-responsibilities")
      end
    end

    context "when on first slug" do
      let(:current_slug) { "teaching-responsibilities" }

      let(:answers) do
        build(
          :further_education_payments_answers,
          teaching_responsibilities: "true"
        )
      end

      it "returns second slug" do
        expect(subject.next_slug).to eql("further-education-provision-search")
      end
    end

    context "when on second slug" do
      let(:current_slug) { "further-education-provision-search" }

      let(:answers) do
        build(
          :further_education_payments_answers,
          teaching_responsibilities: true,
          provision_search: "ply"
        )
      end

      before do
        create(:school, name: "Plymouth")
      end

      it "returns third slug" do
        expect(subject.next_slug).to eql("select-provision")
      end
    end

    context "when should be ineligible" do
      let(:current_slug) { "teaching-responsibilities" }

      let(:answers) do
        build(
          :further_education_payments_answers,
          teaching_responsibilities: false
        )
      end

      it "returns ineligible" do
        expect(subject.next_slug).to eql("ineligible")
      end
    end
  end
end
