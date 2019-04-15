require "rake"

namespace :schools_data do
  desc "Import schools data from Get Information About Schools"
  task import: :environment do
    SchoolDataImporter.new.run
  end
end
