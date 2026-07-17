require "rails_helper"

require Rails.root.join("db/seeders/base")

RSpec.describe Seeders::Base, nullify_stdout: true do
  describe "#call" do
    before do
      allow(SchoolDataImporterJob).to receive(:perform_now).and_return(nil)
    end

    it "runs without error" do
      subject.call
    end
  end
end
