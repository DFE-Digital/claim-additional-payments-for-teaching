module SendAnalytics
  class Base
    def initialize(date: Date.yesterday)
      @date = date
    end
  
    def call
      uploader.call
    ensure
      file&.close
      file&.unlink
    end
  
    private
  
    attr_reader :date, :csv, :file_name
  
    def file
      @file ||= Tempfile.open do |f|
        f << csv
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
end