class AddFileUploadIdToPaymentConfirmations < ActiveRecord::Migration[8.0]
  def change
    add_reference :payment_confirmations, :file_upload, type: :uuid, foreign_key: true, null: true
  end
end
