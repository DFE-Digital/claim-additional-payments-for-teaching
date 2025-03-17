class FileDownload < ApplicationRecord
  belongs_to :downloaded_by, class_name: "DfeSignIn::User", optional: true

  scope :by_source_data_model, ->(source_data_model) { where(source_data_model: source_data_model.to_s) }

  def self.delete_files(source_data_model:, older_than:)
    by_source_data_model(source_data_model)
      .where("created_at < ?", older_than)
      .destroy_all
  end
end
