require "net/http"

# Used to download a remote file. Handles redirects.
# Returns the file as a `Tempfile`
class FileDownload
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def fetch
    download_file(url)
  end

  private

  def download_file(url)
    response = Net::HTTP.get_response(URI(url))

    case response
    when Net::HTTPSuccess
      temp_file_from_response(response)
    when Net::HTTPMovedPermanently, Net::HTTPRedirection
      download_file(response["location"])
    end
  end

  def temp_file_from_response(response)
    body = response.body
    file = Tempfile.new
    file.write(body)
    file.close
    file
  end
end
