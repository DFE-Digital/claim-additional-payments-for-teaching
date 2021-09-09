class SendAnalyticsCsv
  def initialize(query:, file_name:)
    @query = query
    @file_name = file_name
  end

  def call
    uploader.call
  ensure
    file&.close
    file&.unlink
  end

  private

  attr_reader :query, :file_name

  def file
    @file ||= Tempfile.open do |f|
      f << query.to_csv
      f.rewind
      f
    end
  end

  def uploader
    @uploader ||= Upload.new(
      local_file_path: file.path,
      file_name: file_name
    )
  end
end
