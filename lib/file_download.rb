# Used to download a remote file. Handles redirects up to the given maximum.
# Returns the file as a `Tempfile`
class FileDownload
  MAX_REDIRECTS = 5

  class DownloadError < StandardError; end

  attr_reader :url, :encoding

  def initialize(url, encoding: "UTF-8")
    @url = url
    @encoding = encoding
  end

  def fetch
    client = HTTPClient.new
    client.follow_redirect_count = MAX_REDIRECTS
    response = client.get(url, follow_redirect: true)

    if response.ok?
      temp_file_from_response(response)
    else
      raise DownloadError, "#{response.status} response for #{url}"
    end
  end

  private

  def temp_file_from_response(response)
    body = response.body.force_encoding(encoding)
    file = Tempfile.new(encoding: encoding)
    file.write(body)
    file.close
    file
  end
end
