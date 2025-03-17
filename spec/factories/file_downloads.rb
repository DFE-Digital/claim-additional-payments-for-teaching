FactoryBot.define do
  factory :file_download do
    association :downloaded_by, factory: :dfe_signin_user

    body { "STUFF" }
    filename { "stuff.csv" }
    content_type { "text/csv" }
  end
end
