require "rails_helper"

RSpec.describe EnvironmentLogFormatter do
  subject(:formatter) { described_class.new }
  let(:log) { SemanticLogger::Log.new("ExampleClass", :info) }
  let(:logger) { double(host: 'example.local', application: 'ExampleApp', environment: 'example-rails-env') }

  describe "#call" do
    subject(:formatted_entry) { formatter.call(log, logger) }
    around { |example| ClimateControl.modify(ENVIRONMENT_NAME: "example_env", &example) }

    context "when there are no named tags active" do
      it "adds ENV[\"ENVIRONMENT_NAME\"] to the named tags of the log entry" do
        expect(JSON.parse(formatted_entry)["named_tags"]).to eq("environment" => "example_env")
      end
    end

    context "when there are named tags active" do
      around { |example| SemanticLogger.named_tagged(another_tag: "hello", &example) }

      it "adds ENV[\"ENVIRONMENT_NAME\"] to the named tags of the log entry" do
        expect(JSON.parse(formatted_entry)["named_tags"]).to eq("environment" => "example_env", "another_tag" => "hello")
      end
    end
  end
end
