FactoryBot.define do
  factory :file_upload do
    association :uploaded_by, factory: :dfe_signin_user

    body do
      <<~CSV
        1234567,1234567,Full time,19,Design and Technlogy - Textiles,DTT,34,
        ,,,,,,,,,,,,,,,
      CSV
    end
  end
end
