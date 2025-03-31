FactoryBot.define do
  factory :payment_confirmation do
    association :created_by, factory: :dfe_signin_user

    file_upload {
      create(:file_upload, target_data_model: PaymentConfirmation.to_s)
    }
  end
end
