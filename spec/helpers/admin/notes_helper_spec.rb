require "rails_helper"

RSpec.describe Admin::NotesHelper, type: :helper do
  describe "#body_with_anchors" do
    let(:body) { "Test link https://www.gov.uk" }

    it "returns the text with anchor tags around URIs" do
      expect(helper.body_with_anchors(body)).to eql('Test link <a class="govuk-link" target="_blank" rel="noreferrer noopener" href="https://www.gov.uk">https://www.gov.uk</a>')
    end
  end
end
