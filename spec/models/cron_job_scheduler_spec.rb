require "rails_helper"

RSpec.describe CronJobScheduler, type: :model do
  it "schedules SchoolDataImporterJob" do
    expect {
      described_class.new.schedule
    }.to have_enqueued_job(SchoolDataImporterJob)
  end

  it "schedules DfeSignIn::UserDataImporterJob" do
    expect {
      described_class.new.schedule
    }.to have_enqueued_job(DfeSignIn::UserDataImporterJob)
  end
end
