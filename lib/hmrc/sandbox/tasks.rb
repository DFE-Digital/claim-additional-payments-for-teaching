require "fileutils"
require_relative "client"

module Hmrc
  module Sandbox
    class Tasks
      def initialize(env: ENV, output: $stdout, directory: Rails.root.join("tmp", "hmrc-sandbox"), client: nil)
        @env = env
        @output = output
        @directory = Pathname.new(directory)
        @client = client
      end

      def services
        print_json(client.services)
      end

      def match_user
        first_name = required("FIRST_NAME")
        last_name = required("LAST_NAME")
        identifier = nino
        date_of_birth = date("DATE_OF_BIRTH") || raise(ArgumentError, "DATE_OF_BIRTH is required (YYYY-MM-DD)")
        result = client.match_user(first_name: first_name, last_name: last_name,
          nino: identifier, date_of_birth: date_of_birth)
        print_json(result ? {matched: true, response: result} : {matched: false, message: "No individual matched the supplied details"})
      end

      def create_user
        # Validate the optional employment before creating a remote user.
        payload = employment_payload if %w[EMPLOYMENTS_FILE EMPLOYER_NAME PAYE_REFERENCE START_DATE END_DATE].any? { |key| env[key].present? }
        from_date, to_date = query_dates
        FileUtils.mkdir_p(directory, mode: 0o700)
        user = client.create_user(nino: env["NINO"].presence && nino)
        save_user(user)
        print_json(user)
        output.puts "Saved locally to #{user_path(user.fetch("nino"))}"
        seed_employments(user, payload, from_date, to_date) if payload
      end

      def create_employments
        payload = employment_payload
        from_date, to_date = query_dates
        # Also supports users created elsewhere, without a local record.
        user = user_path(nino).exist? ? load_user : {"nino" => nino}
        seed_employments(user, payload, from_date, to_date)
      end

      def fetch_employments
        user = load_user
        details = user.fetch("individualDetails")
        from_date, to_date = query_dates
        raise ArgumentError, "FROM_DATE is required (YYYY-MM-DD)" unless from_date

        response = client.employment_history_for_individual(
          first_name: details.fetch("firstName"), last_name: details.fetch("lastName"),
          date_of_birth: details.fetch("dateOfBirth"), nino: user.fetch("nino"),
          from_date: from_date, to_date: to_date, paye_reference: env["PAYE_REFERENCE"].presence,
          timeout: 30
        )
        print_json(response ? JSON.parse(response.body) : {"message" => "No matching individual found"})
      end

      private

      attr_reader :env, :output, :directory

      def client
        @client ||= Client.new
      end

      def required(name)
        env[name].presence || raise(ArgumentError, "#{name} is required; see docs/hmrc-sandbox.md")
      end

      def nino
        value = required("NINO").delete(" ").upcase
        raise ArgumentError, "NINO must have two letters, six digits and a suffix A-D" unless value.match?(/\A[A-Z]{2}\d{6}[A-D]\z/)
        value
      end

      def date(name)
        value = env[name].presence
        return unless value
        unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/) && Date.iso8601(value)
          raise ArgumentError, "#{name} must be a date in YYYY-MM-DD format"
        end
        value
      rescue Date::Error
        raise ArgumentError, "#{name} must be a valid date in YYYY-MM-DD format"
      end

      def query_dates
        from = date("FROM_DATE")
        to = date("TO_DATE")
        raise ArgumentError, "TO_DATE must not precede FROM_DATE" if from && to && to < from
        [from, to]
      end

      def employment_payload
        if env["EMPLOYMENTS_FILE"].present?
          payload = JSON.parse(File.read(env.fetch("EMPLOYMENTS_FILE")))
          unless payload.is_a?(Hash) && payload["employments"].is_a?(Array) && payload["employments"].all? { |employment| employment.is_a?(Hash) }
            raise ArgumentError, 'EMPLOYMENTS_FILE must contain {"employments": [...]}'
          end
          return payload
        end

        reference = required("PAYE_REFERENCE")
        unless reference.match?(/\A\d{3}\/[a-zA-Z0-9]{1,10}\z/)
          raise ArgumentError, "PAYE_REFERENCE must look like 123/AB456"
        end
        name = required("EMPLOYER_NAME")
        start_date = date("START_DATE") || raise(ArgumentError, "START_DATE is required (YYYY-MM-DD)")
        end_date = date("END_DATE")
        raise ArgumentError, "END_DATE must not precede START_DATE" if end_date && end_date < start_date

        {"employments" => [{
          "employerRef" => reference,
          "employer" => {"name" => name, "districtNumber" => reference.split("/").first, "schemeRef" => reference.split("/").last},
          "employment" => {"startDate" => start_date, "endDate" => end_date}.compact
        }]}
      end

      def seed_employments(user, payload, from_date, to_date)
        response = client.create_employments(nino: user.fetch("nino"), payload: payload, from_date: from_date, to_date: to_date)
        if user.key?("userId")
          user["seededEmployments"] = payload
          user["employmentQuery"] = {"fromDate" => from_date, "toDate" => to_date}.compact
          save_user(user)
        end
        print_json(response)
      end

      def user_path(identifier)
        directory.join("#{identifier}.json")
      end

      def load_user
        path = user_path(nino)
        raise ArgumentError, "No locally saved user for #{nino} in #{directory}" unless path.exist?
        JSON.parse(path.read)
      end

      def save_user(user)
        File.open(user_path(user.fetch("nino")), File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
          file.write(JSON.pretty_generate(user))
        end
      end

      def print_json(value)
        output.puts JSON.pretty_generate(value)
      end
    end
  end
end
