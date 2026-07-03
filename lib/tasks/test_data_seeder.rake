namespace :test_data_seeder do
  desc "generate STRI awards CSV from personas"
  task "generate_stri_awards" => :environment do
    puts Policies::TargetedRetentionIncentivePayments::Test::StriAwardsGenerator.to_csv
  end

  desc "generate School Workforce Census CSV from personas"
  task "generate_school_workforce_census" => :environment do
    puts Policies::TargetedRetentionIncentivePayments::Test::SchoolWorkforceCensusGenerator.to_csv
  end
end
