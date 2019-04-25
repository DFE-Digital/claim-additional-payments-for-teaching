require "rails_helper"
require "rake"

RSpec.describe "rake schools_data:import" do
  let(:school_data_importer) { instance_spy("SchoolDataImporter") }
  before do
    Rake::Task.define_task(:environment)
    Rake.application.rake_require "tasks/import_schools_data"
    allow(SchoolDataImporter).to receive(:new).and_return(school_data_importer)
  end

  it "runs the school data importer" do
    Rake::Task["schools_data:import"].invoke

    expect(school_data_importer).to have_received(:run)
  end
end
