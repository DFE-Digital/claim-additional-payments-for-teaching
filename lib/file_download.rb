require "net/http"

# Used to download a remote file. Handles redirects up to a maximum of 5.
# Returns the file as a `Tempfile`
class FileDownload
  MAX_REDIRECTS = 5

  class TooManyRedirects < StandardError; end

  attr_reader :url, :encoding

  def initialize(url, encoding: "UTF-8")
    @url = url
    @encoding = encoding
  end

  def fetch
    download_file(url)
  end

  private

  def download_file(url, redirect_limit = MAX_REDIRECTS)
    raise TooManyRedirects if redirect_limit == 0

    response = Net::HTTP.get_response(URI(url))

    case response
    when Net::HTTPSuccess
      temp_file_from_response(response)
    when Net::HTTPMovedPermanently, Net::HTTPRedirection
      download_file(response["location"], (redirect_limit - 1))
    end
  end

  def temp_file_from_response(response)
    body = response.body.force_encoding(encoding)
    file = Tempfile.new(encoding: encoding)
    file.write(body)
    file.close
    file
  end
end
