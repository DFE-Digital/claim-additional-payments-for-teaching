require "rails_helper"

RSpec.describe JourneyComponentPreviewUrlBuilder do
  describe ".call!" do
    let(:journey) { Journeys::FurtherEducationPayments }
    let(:session) { {} }
    let(:controller) { Object.new }

    it "sets the session school_id so answers.school.name resolves" do
      school = create(:school, :further_education, :open)
      create(:eligible_fe_provider, ukprn: school.ukprn, academic_year: AcademicYear.current)

      described_class.call!(journey:, slug: "taught-at-least-one-term", session:, controller:)

      session_key = :"#{journey.routing_name}_journeys_session_id"
      answers = journey::Session.find(session[session_key]).answers

      expect(answers.school_id).to eq(school.id)
      expect(answers.school.name).to eq(school.name)
    end
  end
end
