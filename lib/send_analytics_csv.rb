class SendAnalyticsCsv
  def initialize(query:, file_name:, uploader: UploadToGoogleCloudStorage)
    @query = query
    @uploader = uploader
    @file_name = file_name
  end

  def call
    begin
      uploader.new(
        local_file_path: file.path,
        file_name: file_name
      ).call
    ensure
      file&.close
      file&.unlink 
    end
  end

  private
  attr_reader :query, :file_name, :uploader

  def file
    @file ||= Tempfile.open do |f|
      f << query.to_csv
      f.rewind
      f
    end 
  end
end
