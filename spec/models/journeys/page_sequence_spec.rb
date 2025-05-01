# frozen_string_literal: true

require "rails_helper"

RSpec.describe Journeys::PageSequence do
  let(:claim) { build(:claim) }
  let(:slug_sequence) { OpenStruct.new(slugs: ["first-slug", "second-slug", "third-slug"]) }
  let(:completed_slugs) { [] }
  let(:journey_session) { create(:student_loans_session) }

  subject(:page_sequence) do
    described_class.new(
      slug_sequence,
      completed_slugs,
      current_slug,
      journey_session
    )
  end

  describe "#next_slug" do
    subject(:next_slug) { page_sequence.next_slug }

    context "with nil current_slug" do
      let(:current_slug) { nil }
      let(:completed_slugs) { ["first-slug"] }

      it { is_expected.to eq("second-slug") }
    end

    context "with current_slug equal to first slug" do
      let(:current_slug) { "first-slug" }
      let(:completed_slugs) { ["first-slug"] }

      it { is_expected.to eq("second-slug") }
    end

    context "with current_slug equal to second slug" do
      let(:current_slug) { "second-slug" }
      let(:completed_slugs) { ["first-slug", "second-slug"] }

      it { is_expected.to eq("third-slug") }
    end

    context "with an ineligible claim" do
      let(:journey_session) do
        create(
          :student_loans_session,
          answers: {
            employment_status: "no_school"
          }
        )
      end
      let(:current_slug) { "second-slug" }
      let(:completed_slugs) { ["first-slug", "second-slug"] }

      it { is_expected.to eq("ineligible") }
    end

    context "when the claim is in a submittable state (i.e. all questions have been answered)" do
      let(:current_slug) { "third-slug" }
      let(:completed_slugs) { ["first-slug", "second-slug", "third-slug"] }
      let(:journey_session) do
        create(
          :student_loans_session,
          answers: attributes_for(:student_loans_answers, :submittable)
        )
      end

      it { is_expected.to eq("check-your-answers") }

      context "when student-loan-amount is in the sequence and the current slug is personal-details" do
        let(:slug_sequence) { OpenStruct.new(slugs: ["personal-details", "student-loan-amount"]) }
        let(:current_slug) { "personal-details" }
        let(:completed_slugs) { ["personal-details", "student-loan-amount"] }

        it { is_expected.to eq("student-loan-amount") }
      end
    end

    context "when address is populated from 'select-home-address'" do
      [
        {policy: Policies::StudentLoans, next_slug: "date-of-birth", slug_sequence: OpenStruct.new(slugs: ["postcode-search", "select-home-address", "address", "date-of-birth"])}
      ].each do |scenario|
        context "#{scenario[:policy]} claim" do
          let(:journey) { Journeys.for_policy(scenario[:policy]) }
          let(:journey_session) do
            build(
              :"#{journey::I18N_NAMESPACE}_session",
              answers: {
                postcode: "AB12 3CD"
              }
            )
          end
          let(:slug_sequence) { scenario[:slug_sequence] }
          let(:current_slug) { "select-home-address" }
          let(:completed_slugs) { ["postcode-search", "select-home-address"] }

          before do
            create(:journey_configuration, journey::I18N_NAMESPACE)
          end

          it { is_expected.to eq(scenario[:next_slug]) }
        end
      end
    end
  end

  describe "previous_slug" do
    subject(:previous_slug) { page_sequence.previous_slug }

    context "first slug in wizard" do
      let(:current_slug) { "first-slug" }
      it { is_expected.to be_nil }
    end

    context "second slug in wizard" do
      let(:current_slug) { "second-slug" }
      it { is_expected.to eq("first-slug") }
    end

    context "third slug in wizard" do
      let(:current_slug) { "third-slug" }
      it { is_expected.to eq("second-slug") }
    end

    context "sequence with dead ends" do
      let(:slug_sequence) { OpenStruct.new(slugs: ["first-slug", "complete", "existing-session", "eligibility-confirmed", "eligible-later", "ineligible"]) }

      ["complete", "existing-session", "eligible-later", "ineligible"].each do |slug|
        context "current_slug is #{slug}" do
          let(:current_slug) { slug }
          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe "in_sequence?" do
    let(:current_slug) { "third-slug" }

    it "returns true when the slug is part of the sequence" do
      expect(page_sequence.in_sequence?("first-slug")).to eq(true)
      expect(page_sequence.in_sequence?("second-slug")).to eq(true)
    end

    it "returns false when the slug is not part of the sequence" do
      expect(page_sequence.in_sequence?("random-slug")).to eq(false)
      expect(page_sequence.in_sequence?("another-rando-slug")).to eq(false)
    end
  end

  describe "#has_completed_journey_until?" do
    let(:slug_sequence) { OpenStruct.new(slugs: ["first-slug", "postcode-search", "select-home-address", "address", "second-slug", "complete", "existing-session", "eligibility-confirmed", "eligible-later", "ineligible"]) }

    subject(:has_completed_journey_until) { page_sequence.has_completed_journey_until?(current_slug) }

    context "when the user has not completed required previous slugs" do
      let(:current_slug) { "second-slug" }
      it { is_expected.to eq(false) }
    end

    context "when the user has completed only required previous slugs" do
      let(:current_slug) { "second-slug" }
      let(:completed_slugs) { ["first-slug", "address"] }
      it { is_expected.to eq(true) }
    end

    context "when the user has completed required and optional previous slugs" do
      let(:current_slug) { "second-slug" }
      let(:completed_slugs) { ["first-slug", "postcode-search", "select-home-address", "address"] }
      it { is_expected.to eq(true) }
    end

    context "sequence with dead ends" do
      let(:slug_sequence) { OpenStruct.new(slugs: ["first-slug", "complete", "existing-session", "eligibility-confirmed", "eligible-later", "ineligible"]) }

      ["complete", "existing-session", "eligible-later", "ineligible"].each do |slug|
        context "current_slug is #{slug}" do
          let(:current_slug) { slug }
          it { is_expected.to eq(true) }
        end
      end
    end

    context "when the address slug has not been completed" do
      let(:current_slug) { "second-slug" }
      let(:completed_slugs) { ["first-slug"] }

      context "when claim has a postcode (selected from postcode search)" do
        let(:journey_session) do
          build(
            :student_loans_session,
            answers: {
              postcode: "AB12 3CD"
            }
          )
        end
        it { is_expected.to eq(true) }
      end

      context "when the claim does not have a postcode" do
        it { is_expected.to eq(false) }
      end

      context "when the user is on the address page" do
        let(:current_slug) { "address" }
        it { is_expected.to eq(true) }
      end
    end
  end

  describe "#next_required_slug" do
    let(:slug_sequence) { OpenStruct.new(slugs: ["first-slug", "postcode-search", "select-home-address", "address", "second-slug", "complete", "existing-session", "eligibility-confirmed", "eligible-later", "ineligible"]) }
    let(:completed_slugs) { ["first-slug", "address"] }
    let(:current_slug) { "address" }

    it "returns the next required and incomplete slug" do
      expect(page_sequence.next_required_slug).to eq("second-slug")
    end
  end
end
