class Upload
  require "google/cloud/storage"

  def initialize(bucket_name:, local_file_path:, file_name: nil)
    
  end

  def call
    
  end
end

def upload_file(local_file_path:, file_name: nil)
  # The ID of your GCS bucket
  # bucket_name = "your-unique-bucket-name"

  # The path to your file to upload
  # local_file_path = "/local/path/to/file.txt"

  # The ID of your GCS object
  # file_name = "your-file-name"

  

  storage = Google::Cloud::Storage.new
  bucket  = storage.bucket bucket_name

  file = bucket.create_file local_file_path, file_name

  puts "Uploaded #{local_file_path} as #{file.name} in bucket #{bucket_name}"
end
# [END storage_upload_file]

upload_file bucket_name: ARGV.shift, local_file_path: ARGV.shift, file_name: ARGV.shift if $PROGRAM_NAME == __FILE__
