require "rails_helper"

RSpec.describe Upload do
  subject { Upload }
  describe "#call" do
    # save this for later
    let!(:original_storage_bucket_env) { ENV["STORAGE_BUCKET"] }

    # arguments
    let!(:file) {
      Tempfile.open { |f|
        f << "test"
        f.rewind
        f
      }
    }
    let(:name) { "test" }

    # at the moment, only Google Cloud Storage is used for storage action
    # so create doubles to match functionality
    let(:bucket) { double(Google::Cloud::Storage::Bucket) }
    let(:storage) { double(Google::Cloud::Storage) }
    let(:bucket_name) { "test-bucket-name" }

    before do
      allow(storage).to receive(:bucket).and_return(bucket)
      allow(bucket).to receive(:create_file).with(file.path, name)
    end

    after do
      ENV["STORAGE_BUCKET"] = original_storage_bucket_env
      file&.close
      file&.unlink
    end

    it "runs without error" do
      expect {
        subject.new(
          local_file_path: file.path,
          file_name: name,
          storage: storage
        ).call
      }.to_not raise_error
    end

    context "with a missing bucket ENV" do
      before do
        ENV["STORAGE_BUCKET"] = nil
      end
      it "raises a MissingBucketNameError" do
        expect {
          subject.new(
            local_file_path: file.path,
            file_name: name,
            storage: storage
          ).call
        }.to raise_error(
          subject::MissingBucketNameError
        )
      end
    end
  end
end
