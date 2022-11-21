FactoryBot.define do
  factory :file_upload do
    association :uploaded_by, factory: :dfe_signin_user

    body do
      <<~CSV
        TRN,GeneralSubjectDescription,2nd,3rd,4th,5th,6th,7th,8th,9th,10th,11th,12th,13th,14th,15th
        1234567,Art and Design / Art,Commercial and Business Studies/Education/Management,Design and Technology - Graphics,English,Geography,Health and Social Care,History,Mathematics / Mathematical Development (Early Years),Media Studies,Music,Other Vocational Subject,Physical Education / Sports,Science,Sociology,Spanish
        ,,,,,,,,,,,,,,,
      CSV
    end
  end
end
