FactoryBot.define do
  factory :levelling_up_premium_payments_award, class: "Policies::LevellingUpPremiumPayments::Award" do
    association :school
    academic_year { Journeys.for_policy(Policies::LevellingUpPremiumPayments).configuration.current_academic_year }
    award_amount { 2_000 }

    file_upload {
      FileUpload.latest_version_for(Policies::LevellingUpPremiumPayments::Award, academic_year).first ||
        create(:file_upload, target_data_model: Policies::LevellingUpPremiumPayments::Award.to_s, academic_year: academic_year.to_s)
    }
  end
end
