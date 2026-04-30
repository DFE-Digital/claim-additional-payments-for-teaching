require "rails_helper"

RSpec.describe "Admin viewing file uploads" do
  before do
    sign_in_as_service_operator
  end

  context "when file upload is not yet processed" do
    let(:file_upload) do
      create(
        :file_upload,
        :not_completed_processing,
        :with_current_academic_year,
        target_data_model: "Foo"
      )
    end

    scenario "it refreshes the page every 5 seconds" do
      visit "/admin/file-uploads/#{file_upload.id}"

      expect(page.response_headers["refresh"]).to eql("5")
    end
  end

  context "when file upload has been processed" do
    let(:file_upload) do
      create(
        :file_upload,
        :with_current_academic_year,
        target_data_model: "Foo"
      )
    end

    scenario "it does not refresh the page" do
      visit "/admin/file-uploads/#{file_upload.id}"

      expect(page.response_headers["refresh"]).to be_blank
    end
  end
end
