# frozen_string_literal: true

require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement do
  describe ".configuration" do
    context "with journey configuration record" do
      let!(:configuration) { create(:journey_configuration, :student_loans) }

      it "returns the record" do
        expect(described_class.configuration).to eq(configuration)
      end
    end

    context "with no journey configuration record" do
      it "raises an exception" do
        expect { described_class.configuration }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe ".start_page_url" do
    before { allow(Journeys::TeacherStudentLoanReimbursement::SlugSequence).to receive(:start_page_url).and_return("test") }

    it "returns the slug sequence start_page_url" do
      expect(described_class.start_page_url).to eq("test")
    end
  end

  describe ".slug_sequence" do
    subject(:slug) { described_class.slug_sequence }

    it { is_expected.to eq(Journeys::TeacherStudentLoanReimbursement::SlugSequence) }
  end

  describe ".answers_presenter" do
    subject(:presenter) { described_class.answers_presenter }

    it { is_expected.to eq(Journeys::TeacherStudentLoanReimbursement::AnswersPresenter) }
  end
end
