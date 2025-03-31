FactoryBot.define do
  factory :eligible_fe_provider do
    ukprn { rand(10_000_000..19_000_000) }
    academic_year { AcademicYear.current }
    max_award_amount { [4_000, 5_000, 6_000].sample }
    lower_award_amount { [2_000, 2_500, 3_000].sample }
    primary_key_contact_email_address { Faker::Internet.email }

    file_upload {
      FileUpload.latest_version_for(EligibleFeProvider, academic_year).first ||
        create(:file_upload, target_data_model: EligibleFeProvider.to_s, academic_year: academic_year.to_s)
    }
  end
end
