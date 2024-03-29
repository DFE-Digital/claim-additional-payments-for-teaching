require "rails_helper"

RSpec.describe Admin::PresenterMethods do
  subject(:admin_presenter) do
    Class.new do
      include Admin::PresenterMethods
    end
  end

  describe "#display_school" do
    let(:school) do
      build(:school,
        name: "Bash Street School",
        urn: "1234",
        establishment_number: 4567,
        local_authority: build(:local_authority, code: 123))
    end

    it "shows a school with a link and the DfE number" do
      gias_url = "https://get-information-schools.service.gov.uk/Establishments/Establishment/Details/#{school.urn}"
      expect(admin_presenter.new.display_school(school)).to eq(
        "<a class=\"govuk-link\" href=\"#{gias_url}\"><span class=\"govuk-visually-hidden\">View</span> #{school.name} <span class=\"govuk-visually-hidden\">on Get Information About Schools</span></a> <span class=\"govuk-body-s\">(#{school.dfe_number})</span>"
      )
    end
  end

  describe "#display_boolean" do
    subject { admin_presenter.new.display_boolean(value) }

    context "when answered No" do
      let(:value) { false }

      it { is_expected.to eq("No") }
    end

    context "when answered Yes" do
      let(:value) { true }

      it { is_expected.to eq("Yes") }
    end

    context "when not answered" do
      let(:value) { nil }

      it { is_expected.to eq("N/A") }
    end
  end
end
