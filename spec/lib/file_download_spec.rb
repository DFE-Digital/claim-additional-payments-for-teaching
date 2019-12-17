require "rails_helper"
require "file_download"

RSpec.describe FileDownload do
  let(:file_url) { "https://somewhere.com/file.csv" }
  let(:example_file) { File.open("spec/fixtures/files/file.csv") }

  it "returns a Tempfile for the given URL" do
    request = stub_request(:get, file_url).to_return(body: example_file)

    file = FileDownload.new(file_url).fetch

    expect(request).to have_been_requested

    expect(file).to be_a(Tempfile)
    expect(FileUtils.identical?(file.path, example_file.path)).to be_truthy
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
end
