require "rake"

namespace :schools_data do
  def export_school_data(policy_name)
    require "csv"

    CSV.open("#{Rails.root}/tmp/eligible_for_#{policy_name}.csv", "wb") do |csv|
      csv << School.attribute_names
      School.includes(:local_authority, :local_authority_district).find_each do |school|
        csv << school.attributes.values if school.public_send("eligible_for_#{policy_name}?")
      end
    end
  end

  desc "Import schools data from Get Information About Schools"
  task import: :environment do
    SchoolDataImporterJob.perform_later
  end

  desc "Export schools eligible for Student loans to csv"
  task "export:student_loans": :environment do
    export_school_data(:student_loans)
  end

  desc "Export schools eligible for Maths and physics to csv"
  task "export:maths_and_physics": :environment do
    export_school_data(:maths_and_physics)
  end
end
