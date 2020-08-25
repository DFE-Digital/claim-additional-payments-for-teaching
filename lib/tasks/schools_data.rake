require "rake"

namespace :schools_data do
  def export_school_data(policy_name, as: nil)
    require "csv"

    CSV.open("#{Rails.root}/tmp/eligible_for_#{policy_name}.csv", "wb") do |csv|
      csv << School.attribute_names
      School.includes(:local_authority, :local_authority_district).find_each do |school|
        suffix = as ? "as_#{as}" : nil
        method_name = ["eligible_for_#{policy_name}", suffix].compact.join("_") + "?"
        csv << school.attributes.values if school.public_send(method_name)
      end
    end
  end

  desc "Import schools data from Get Information About Schools"
  task import: :environment do
    logger = Logger.new($stdout)
    logger.info "Importing schools data, this may take a couple minutes..."
    SchoolDataImporter.new.run
    logger.info "Schools data import complete!"
  end

  desc "Export schools eligible for Student Loans to CSV"
  task "export:student_loans": :environment do
    export_school_data(:student_loans, as: :claim_school)
  end

  desc "Export schools eligible for Maths and Physics to CSV"
  task "export:maths_and_physics": :environment do
    export_school_data(:maths_and_physics)
  end
end
