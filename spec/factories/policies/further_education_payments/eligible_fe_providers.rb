FactoryBot.define do
  factory :eligible_fe_provider, class: "Policies::FurtherEducationPayments::EligibleFeProvider" do
    ukprn { rand(10_000_000..19_000_000) }
    academic_year { AcademicYear.current }
    max_award_amount { [4_000, 5_000, 6_000].sample }
    lower_award_amount { [2_000, 2_500, 3_000].sample }
    primary_key_contact_email_address { Faker::Internet.email }

    file_upload {
      FileUpload.latest_version_for(Policies::FurtherEducationPayments::EligibleFeProvider, academic_year).first ||
        create(:file_upload, target_data_model: Policies::FurtherEducationPayments::EligibleFeProvider.to_s, academic_year: academic_year.to_s)
    }

    trait :with_dsi_bypass_ukprn do
      ukprn { 10000952 }
    end

    trait :with_school do
      after(:create) do |eligible_fe_provider|
        create(:school, ukprn: eligible_fe_provider.ukprn)
      end
    end
  end
end
