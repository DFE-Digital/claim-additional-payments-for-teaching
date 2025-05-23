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

  describe "#permissible_slug?" do
    context "when permissible" do
      let(:answers) do
        build(
          :further_education_payments_answers
        )
      end

      it "returns truthy" do
        expect(subject.permissible_slug?).to be_truthy
      end
    end

    context "when not permissible" do
      let(:current_slug) { "address" }
      let(:answers) do
        build(
          :further_education_payments_answers
        )
      end

      it "returns falsey" do
        expect(subject.permissible_slug?).to be_falsey
      end
    end
  end

  describe "#furthest_permissible_slug" do
    context "when new journey" do
      let(:answers) do
        build(
          :further_education_payments_answers
        )
      end

      it "returns first slug" do
        expect(subject.furthest_permissible_slug).to eql("teaching-responsibilities")
      end
    end

    context "when mid-journey" do
      let(:current_slug) { "foo" }

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

      it "returns relevant slug" do
        expect(subject.furthest_permissible_slug).to eql("select-provision")
      end
    end

    context "when about to submit" do
      let(:current_slug) { "foo" }
      let(:school) { create(:school) }

      let(:answers) do
        build(
          :further_education_payments_answers,
          :submittable,
          provision_search: school.name,
          skip_postcode_search: true,
          onelogin_uid: "some-uid",
          onelogin_idv_at: 1.second.ago
        )
      end

      it "returns check-answers slug" do
        expect(subject.furthest_permissible_slug).to eql("check-your-answers")
      end
    end
  end

  describe "#clear_impermissible_answers" do
    let(:current_slug) { "foo" }
    let(:school) { create(:school) }

    let(:answers) do
      build(
        :further_education_payments_answers,
        teaching_responsibilities: "true",
        provision_search: school.name,
        school_id: school.id,
        contract_type: "permanent",
        fixed_term_full_year: true
      )
    end

    it "clears impermissible answers from session" do
      expect {
        subject.clear_impermissible_answers
      }.to change { journey_session.reload.answers.fixed_term_full_year }.from(true).to(nil)
    end
  end
end
