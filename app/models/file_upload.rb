class FileUpload < ApplicationRecord
  belongs_to :uploaded_by, class_name: "DfeSignIn::User"
end
