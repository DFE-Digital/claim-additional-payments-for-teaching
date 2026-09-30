require "rails_helper"
require "tmpdir"
require Rails.root.join("lib/hmrc/sandbox/tasks")

RSpec.describe Hmrc::Sandbox::Tasks do
  it "matches supplied identity details without a saved user and prints the result" do
    client = instance_double(Hmrc::Sandbox::Client)
    output = StringIO.new
    result = {"_links" => {"individual" => {"href" => "/individuals/matching/match-123"}}}
    expect(client).to receive(:match_user).with(first_name: "Jane", last_name: "Smith", nino: "AA123456A", date_of_birth: "1990-01-01").and_return(result)
    tasks = described_class.new(client: client, output: output,
      env: {"FIRST_NAME" => "Jane", "LAST_NAME" => "Smith", "NINO" => "aa 123456 a", "DATE_OF_BIRTH" => "1990-01-01"})

    tasks.match_user

    expect(JSON.parse(output.string)).to eq("matched" => true, "response" => result)
  end

  it "prints a normal non-match result" do
    client = instance_double(Hmrc::Sandbox::Client, match_user: nil)
    output = StringIO.new
    tasks = described_class.new(client: client, output: output,
      env: {"FIRST_NAME" => "Jane", "LAST_NAME" => "Smith", "NINO" => "AA123456A", "DATE_OF_BIRTH" => "1990-01-01"})

    tasks.match_user

    expect(JSON.parse(output.string)).to include("matched" => false)
  end

  it "validates the date of birth before making a matching request" do
    client = instance_double(Hmrc::Sandbox::Client)
    expect(client).not_to receive(:match_user)
    tasks = described_class.new(client: client,
      env: {"FIRST_NAME" => "Jane", "LAST_NAME" => "Smith", "NINO" => "AA123456A", "DATE_OF_BIRTH" => "1990-02-30"})

    expect { tasks.match_user }.to raise_error(ArgumentError, /DATE_OF_BIRTH must be a valid date/)
  end

  it "creates and saves a user, then fetches their employment using the saved identity" do
    Dir.mktmpdir do |directory|
      user = {"userId" => "123", "nino" => "AA123456A", "password" => "password",
              "individualDetails" => {"firstName" => "Jane", "lastName" => "Smith", "dateOfBirth" => "1990-01-01"}}
      client = instance_double(Hmrc::Sandbox::Client)
      expect(client).to receive(:create_user).with(nino: nil).and_return(user)
      output = StringIO.new
      env = {}
      tasks = described_class.new(env: env, directory: directory, client: client, output: output)
      tasks.create_user
      expect(JSON.parse(File.read(File.join(directory, "AA123456A.json")))).to eq(user)

      output.truncate(0)
      output.rewind
      env["NINO"] = "aa 123456 a"

      env["FROM_DATE"] = "2025-01-01"
      expect(client).to receive(:employment_history_for_individual).with(
        first_name: "Jane", last_name: "Smith", date_of_birth: "1990-01-01", nino: "AA123456A",
        from_date: "2025-01-01", to_date: nil, paye_reference: nil, timeout: 30
      ).and_return(double(body: '{"employments":[]}'))
      tasks.fetch_employments
      expect(output.string).to include('"employments": []')
    end
  end

  it "keeps the created user if seeding employment fails, allowing a separate retry" do
    Dir.mktmpdir do |directory|
      client = instance_double(Hmrc::Sandbox::Client)
      expect(client).to receive(:create_user).and_return({"userId" => "123", "nino" => "AA123456A"})
      expect(client).to receive(:create_employments).with(
        nino: "AA123456A", from_date: nil, to_date: nil,
        payload: {"employments" => [{"employerRef" => "123/ABC", "employer" => {"name" => "Test Nursery", "districtNumber" => "123", "schemeRef" => "ABC"}, "employment" => {"startDate" => "2025-01-01"}}]}
      ).and_raise(Hmrc::ResponseError, "failed")
      tasks = described_class.new(directory: directory, client: client, output: StringIO.new,
        env: {"EMPLOYER_NAME" => "Test Nursery", "PAYE_REFERENCE" => "123/ABC", "START_DATE" => "2025-01-01"})

      expect { tasks.create_user }.to raise_error(Hmrc::ResponseError)
      expect(JSON.parse(File.read(File.join(directory, "AA123456A.json"))))
        .to eq("userId" => "123", "nino" => "AA123456A")
    end
  end

  it "rejects invalid dates before creating a remote user" do
    client = instance_double(Hmrc::Sandbox::Client)
    expect(client).not_to receive(:create_user)
    tasks = described_class.new(client: client, env: {
      "EMPLOYER_NAME" => "Test Nursery", "PAYE_REFERENCE" => "123/ABC", "START_DATE" => "2025-02-30"
    })
    expect { tasks.create_user }.to raise_error(ArgumentError, /START_DATE must be a valid date/)
  end

  it "saves a successful employment seed alongside the identity" do
    Dir.mktmpdir do |directory|
      user = {"userId" => "123", "nino" => "AA123456A"}
      File.write(File.join(directory, "AA123456A.json"), user.to_json)
      client = instance_double(Hmrc::Sandbox::Client)
      expect(client).to receive(:create_employments) do |**arguments|
        expect(arguments.fetch(:from_date)).to eq("2025-01-01")
        expect(arguments.fetch(:payload).dig("employments", 0, "employment"))
          .to eq("startDate" => "2025-01-01", "endDate" => "2025-12-31")
        arguments.fetch(:payload)
      end
      tasks = described_class.new(directory: directory, client: client, output: StringIO.new,
        env: {"NINO" => "AA123456A", "EMPLOYER_NAME" => "Test Nursery", "PAYE_REFERENCE" => "123/ABC",
              "START_DATE" => "2025-01-01", "END_DATE" => "2025-12-31", "FROM_DATE" => "2025-01-01"})
      tasks.create_employments

      saved = JSON.parse(File.read(File.join(directory, "AA123456A.json")))
      expect(saved.fetch("userId")).to eq("123")
      expect(saved.dig("seededEmployments", "employments", 0, "employer", "name")).to eq("Test Nursery")
      expect(saved.fetch("employmentQuery")).to eq("fromDate" => "2025-01-01")
    end
  end

  it "submits multiple employments from a JSON file in one request for an existing remote user" do
    Dir.mktmpdir do |directory|
      payload = {"employments" => [
        {"employer" => {"name" => "Old Nursery"}, "employment" => {"startDate" => "2024-01-01", "endDate" => "2024-12-31"}},
        {"employer" => {"name" => "New Nursery"}, "employment" => {"startDate" => "2025-01-01"}}
      ]}
      path = File.join(directory, "employments.json")
      File.write(path, payload.to_json)
      client = instance_double(Hmrc::Sandbox::Client)
      expect(client).to receive(:create_employments).with(nino: "AA123456A", payload: payload, from_date: "2024-01-01", to_date: nil).and_return(payload)
      tasks = described_class.new(client: client, directory: File.join(directory, "users"), output: StringIO.new,
        env: {"NINO" => "AA123456A", "EMPLOYMENTS_FILE" => path, "FROM_DATE" => "2024-01-01"})
      tasks.create_employments
    end
  end

  it "rejects an invalid employment file before creating a user" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, "invalid.json")
      File.write(path, '{"employments":{}}')
      client = instance_double(Hmrc::Sandbox::Client)
      expect(client).not_to receive(:create_user)
      tasks = described_class.new(client: client, env: {"EMPLOYMENTS_FILE" => path})
      expect { tasks.create_user }.to raise_error(ArgumentError, /EMPLOYMENTS_FILE must contain/)
    end
  end

  it "explains when fetching employment requires a missing saved identity" do
    Dir.mktmpdir do |directory|
      tasks = described_class.new(directory: directory, env: {"NINO" => "AA123456A"})
      expect { tasks.fetch_employments }.to raise_error(ArgumentError, /No locally saved user/)
    end
  end
end
