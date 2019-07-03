require "rails_helper"
require "rake"

RSpec.describe "rake schools_data:import" do
  before do
    Rake::Task.define_task(:environment)
    Rake.application.rake_require "tasks/import_schools_data"
  end

  it "enqueues SchoolDataImporterJob" do
    Rake::Task["schools_data:import"].invoke

    expect(SchoolDataImporterJob).to have_been_enqueued.on_queue("school_data")
  end
end
