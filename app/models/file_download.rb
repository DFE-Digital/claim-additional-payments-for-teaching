class FileDownload < ApplicationRecord
  belongs_to :downloaded_by, class_name: "DfeSignIn::User", optional: true
end
