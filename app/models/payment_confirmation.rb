class PaymentConfirmation < ApplicationRecord
  has_many :payments, foreign_key: :confirmation_id

  belongs_to :payroll_run
  belongs_to :created_by, class_name: "DfeSignIn::User"
  belongs_to :file_upload, dependent: :destroy, optional: true
end
