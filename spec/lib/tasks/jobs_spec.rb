require "rails_helper"
require "rake"

RSpec.describe "rake jobs:schedule" do
  def queue_adapter_for_test
    DelayedJobTestAdapter.new
  end

  before do
    Rake::Task.define_task(:environment)
    Rake.application.rake_require "tasks/jobs"
  end

  it "schedules SchoolDataImporterJob" do
    expect {
      Rake::Task["jobs:schedule"].invoke
    }.to change {
      Delayed::Job
        .where("handler LIKE ?", "%job_class: SchoolDataImporterJob%")
        .count
    }.by(1)
  end
end
