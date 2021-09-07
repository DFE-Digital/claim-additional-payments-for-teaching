class UploadToGoogleCloudStorage
  class MissingBucketNameError < StandardError; end
  require "google/cloud/storage"

  def initialize(local_file_path:, file_name: nil)
    @local_file_path = local_file_path
    @file_name = file_name 
  end

  def call
    bucket.create_file local_file_path, file_name
  end

  private

  attr_reader :local_file_path, :file_name

  def bucket
    @bucket ||= storage.bucket bucket_name
  end

  def bucket_name
    @bucket_name ||= begin
      bn = ENV['STORAGE_BUCKET']
      raise MissingBucketNameError, "Missing ENV variable 'STORAGE_BUCKET'" unless bn.present?
      bn
    end
  end

  def storage
    @storage ||= Google::Cloud::Storage.new
  end
end
