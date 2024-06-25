require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::FurtherEducationTeachingStartYearForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:further_education_teaching_start_year) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        further_education_teaching_start_year:
      }
    )
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "#radio_options" do
    it "returns 6 options" do
      expect(subject.radio_options.size).to eql(6)
    end

    it "returns expected data" do
      travel_to Time.zone.local(2024, 12, 1) do
        expected = [
          OpenStruct.new(id: "2020", name: "September 2020 to August 2021"),
          OpenStruct.new(id: "2021", name: "September 2021 to August 2022"),
          OpenStruct.new(id: "2022", name: "September 2022 to August 2023"),
          OpenStruct.new(id: "2023", name: "September 2023 to August 2024"),
          OpenStruct.new(id: "2024", name: "September 2024 to August 2025"),
          OpenStruct.new(id: "pre-2020", name: "I started before September 2020")
        ]

        expect(subject.radio_options).to eql(expected)
      end
    end
  end

  describe "validations" do
    let(:further_education_teaching_start_year) { nil }

    it do
      is_expected.not_to(
        allow_value(further_education_teaching_start_year)
        .for(:further_education_teaching_start_year)
        .with_message("Select which academic year you started teaching in further education in England")
      )
    end
  end

  describe "#save" do
    let(:further_education_teaching_start_year) { AcademicYear.current.start_year.to_s }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.further_education_teaching_start_year }.to(further_education_teaching_start_year)
      )
    end
  end
end
