require "google/cloud/storage"

class Upload
  class MissingBucketNameError < StandardError; end

  def initialize(local_file_path:, file_name:, storage: Google::Cloud::Storage.new)
    @local_file_path = local_file_path
    @file_name = file_name
    @storage = storage
  end

  def call
    bucket.create_file local_file_path, file_name
  end

  private

  attr_reader :local_file_path, :file_name, :storage

  def bucket
    @bucket ||= storage.bucket bucket_name
  end

  def bucket_name
    @bucket_name ||= begin
      bn = ENV["STORAGE_BUCKET"]
      raise MissingBucketNameError, "Missing ENV variable 'STORAGE_BUCKET'" unless bn.present?
      bn
    end
  end
end
