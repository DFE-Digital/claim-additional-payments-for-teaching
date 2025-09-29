require "rails_helper"

RSpec.describe "Recurring Jobs Exist" do
  let(:config) do
    YAML.load_file(Rails.root.join("config", "recurring.yml"), aliases: true)
  end

  let(:job_class_names) do
    config["production"].values.map { |job| job["class"] }.uniq
  end

  it "backs all recurring jobs with a class" do
    job_class_names.each do |class_name|
      expect { class_name.constantize }.not_to(
        raise_error, "Expected job class '#{class_name}' to be defined"
      )
    end
  end
end
