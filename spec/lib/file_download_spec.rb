require "rails_helper"
require "file_download"

RSpec.describe FileDownload do
  let(:file_url) { "https://somewhere.com/file.csv" }
  let(:example_file) { File.open("spec/fixtures/files/file.csv") }
  let(:example_iso_encoded_file) { File.open("spec/fixtures/files/iso_encoded_file.csv") }

  it "returns a Tempfile for the given URL" do
    request = stub_request(:get, file_url).to_return(body: example_file)

    file = FileDownload.new(file_url).fetch

    expect(request).to have_been_requested

    expect(file).to be_a(Tempfile)
    expect(FileUtils.identical?(file.path, example_file.path)).to be_truthy
  end

  it "allows the file encoding to be overridden" do
    request = stub_request(:get, file_url).to_return(body: example_iso_encoded_file)

    file = FileDownload.new(file_url, encoding: "ISO-8859-1").fetch

    expect(request).to have_been_requested

    expect(file).to be_a(Tempfile)
    expect(FileUtils.identical?(file.path, example_iso_encoded_file.path)).to be_truthy
  end

  it "handles Redirect (302) responses" do
    redirected_url = "https://somewhere.else/file.csv"
    stub_request(:get, file_url).to_return(status: 302, headers: {"Location" => redirected_url})
    stub_request(:get, redirected_url).to_return(body: example_file)

    file = FileDownload.new(file_url).fetch

    expect(FileUtils.identical?(file.path, example_file.path)).to be_truthy
  end

  it "handles Permanent Redirect (301) responses" do
    redirected_url = "https://somewhere.else/file.csv"
    stub_request(:get, file_url).to_return(status: 301, headers: {"Location" => redirected_url})
    stub_request(:get, redirected_url).to_return(body: example_file)

    file = FileDownload.new(file_url).fetch

    expect(FileUtils.identical?(file.path, example_file.path)).to be_truthy
  end

  it "gives up after 5 redirects" do
    5.times do |i|
      stub_request(:get, "http://url.com/file-#{i}.csv")
        .to_return(status: 301, headers: {"Location" => "http://url.com/file-#{i + 1}.csv"})
    end

    expect {
      FileDownload.new("http://url.com/file-0.csv").fetch
    }.to raise_error(HTTPClient::BadResponseError)
  end

  it "raises an exception on any other response" do
    stub_request(:get, file_url).to_return(status: [500, "Internal Server Error"])

    expect {
      FileDownload.new(file_url).fetch
    }.to raise_error(FileDownload::DownloadError, "500 response for #{file_url}")
  end
end
