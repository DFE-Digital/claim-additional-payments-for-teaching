require "rails_helper"

RSpec.describe FileImporterJob do
  let(:dummy_job) { Class.new(FileImporterJob) }
  let(:importer_class) do
    Class.new do
      def initialize(_file)
        nil
      end

      def run
      end
    end
  end
  let(:rescue_with_lambda) { lambda {} }
  let(:notify_with_mailer) { AdminMailer }

  it { is_expected.to be_a(ApplicationJob) }

  describe ".import_with" do
    it "sets the importer class" do
      expect { dummy_job.import_with(importer_class) }.to change { dummy_job.importer_class }.to(importer_class)
    end

    it "sets the post import block to execute" do
      expect { dummy_job.import_with(importer_class) {} }.to change { dummy_job.post_import_block }
    end
  end

  describe ".rescue_with" do
    it "sets a lambda to execute when rescuing from an exception" do
      expect { dummy_job.rescue_with(rescue_with_lambda) }.to change { dummy_job.rescue_with_lambda }.to(rescue_with_lambda)
    end
  end

  describe ".notify_with" do
    it "sets target mailer's success and failure methods" do
      expect { dummy_job.notify_with(notify_with_mailer, success: :foo, failure: :bar) }
        .to change { dummy_job.notify_with_mailer }.to(notify_with_mailer)
        .and change { dummy_job.success_mailer_method }.to(:foo)
        .and change { dummy_job.failure_mailer_method }.to(:bar)
    end
  end

  describe "#perform" do
    let(:importer_mock) { instance_double(importer_class, run: nil) }
    let(:post_import_mock) { double("block", call: nil) }
    let(:file_upload_id) { file&.id }

    def apply_config(dummy_job, importer_class, rescue_with_class = nil, notify_with_mailer = nil)
      dummy_job.import_with(importer_class) { post_import_mock.call }
      dummy_job.rescue_with(rescue_with_class)
      dummy_job.new
    end

    before do
      allow(importer_class).to receive(:new).and_return(importer_mock)
      allow(rescue_with_lambda).to receive(:call)
      allow(Rollbar).to receive(:error)
    end

    before do
      job = apply_config(dummy_job, importer_class, rescue_with_lambda, notify_with_mailer)
      job.perform(file_upload_id)
    end

    context "when an error occurs" do
      let(:file) { nil }

      it "does not run the importer" do
        expect(importer_class).not_to have_received(:new)
      end

      it "executes the rescue lambda" do
        expect(rescue_with_lambda).to have_received(:call)
      end

      it "does not execute the post import block" do
        expect(post_import_mock).not_to have_received(:call)
      end

      it "sends the exception to Rollbar" do
        expect(Rollbar).to have_received(:error).with(ActiveRecord::RecordNotFound)
      end
    end

    context "when a file upload can be imported" do
      let(:file) { create(:file_upload, body: "stuff") }
      let(:tempfile) do
        Tempfile.new.tap do |f|
          f.write(file.body)
          f.rewind
        end
      end

      it "runs the importer", :aggregate_failures do
        expect(importer_class).to have_received(:new)
        expect(importer_mock).to have_received(:run)
        expect(file.body).to eq(tempfile.read)
      end

      it "executes the post import block" do
        expect(post_import_mock).to have_received(:call)
      end

      it "deletes the original file upload" do
        expect(FileUpload.exists?(id: file_upload_id)).to eq(false)
      end
    end
  end
end
