FactoryBot.define do
  factory :targeted_retention_incentive_payments_award, class: "Policies::TargetedRetentionIncentivePayments::Award" do
    association :school
    academic_year { Journeys.for_policy(Policies::TargetedRetentionIncentivePayments).configuration.current_academic_year }
    award_amount { 2_000 }

    file_upload {
      FileUpload.latest_version_for(Policies::TargetedRetentionIncentivePayments::Award, academic_year).first ||
        create(:file_upload, target_data_model: Policies::TargetedRetentionIncentivePayments::Award.to_s, academic_year: academic_year.to_s)
    }
  end
end
