FactoryBot.define do
  factory :active_storage_blob, class: "ActiveStorage::Blob" do
    skip_create

    initialize_with do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("test file content"),
        filename: "document.pdf",
        content_type: "application/pdf"
      )
    end
  end
end
