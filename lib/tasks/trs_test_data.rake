require "rake"
require "csv"

namespace :trs_test_data do
  def export_data(policy)
    csv_file = File.open(Rails.root.join("tmp", "trs_data_#{policy.to_s.demodulize.underscore}.csv"), "w")
    "Policies::#{policy}::Test::TrsDataGenerator".constantize.to_file(csv_file)

    csv_file.path
  end

  desc "Export test data for manual load into the Teaching Record Service (TRS)"
  task export: :environment do
    logger = Logger.new($stdout)

    Policies.all.reject do |policy|
      !Object.const_defined?("Policies::#{policy}::Test::UserPersona") ||
        !Object.const_defined?("Policies::#{policy}::Test::TrsDataGenerator")
    end.each do |policy|
      personas_file = "Policies::#{policy}::Test::UserPersona::FILE".constantize

      logger.info "Generating test data for #{policy} from user personas in #{personas_file}..."
      csv_file = export_data(policy)
      logger.info "Export complete! Data is saved in #{csv_file}"
    end
  end
end
