namespace :hmrc do
  namespace :sandbox do
    {
      services: "Check access to Create Test User by fetching available services (no users created)",
      match_user: "Match an individual (FIRST_NAME=... LAST_NAME=... NINO=... DATE_OF_BIRTH=YYYY-MM-DD)",
      create_user: "Create and save a sandbox individual; optionally seed employment (see docs/hmrc-sandbox.md)",
      create_employments: "Seed employment once for a sandbox user (NINO=...; see docs/hmrc-sandbox.md)",
      fetch_employments: "Fetch live sandbox employment history (NINO=... FROM_DATE=YYYY-MM-DD)"
    }.each do |name, description|
      desc description
      task name => :environment do
        require Rails.root.join("lib/hmrc/sandbox/tasks")
        Hmrc::Sandbox::Tasks.new.public_send(name)
      rescue ArgumentError, JSON::ParserError, SystemCallError, Hmrc::ResponseError, Faraday::Error => e
        abort "HMRC sandbox: #{e.message}"
      end
    end
  end
end
