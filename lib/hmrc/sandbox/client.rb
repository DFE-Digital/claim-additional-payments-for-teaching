module Hmrc
  module Sandbox
    # Reuse the employment client's application authentication, including TOTP.
    class Client < Employments::Client
      BASE_URL = "https://test-api.service.hmrc.gov.uk"

      def initialize(output: $stderr, **options)
        @output = output
        super(**options)
        unless base_url.to_s.delete_suffix("/") == BASE_URL
          raise ArgumentError, "Set HMRC_EMPLOYMENTS_BASE_URL to #{BASE_URL}"
        end
        self.base_url = BASE_URL
        if client_id.blank? || client_secret.blank?
          raise ArgumentError, "Set HMRC_EMPLOYMENTS_CLIENT_ID and HMRC_EMPLOYMENTS_CLIENT_SECRET"
        end
      end

      def services
        response = get_request!("/create-test-user/services", {
          "Authorization" => "Bearer #{access_token(timeout: 30)}",
          "Accept" => "application/vnd.hmrc.1.0+json"
        }, timeout: 30)
        JSON.parse(response.body)
      end

      def match_user(first_name:, last_name:, nino:, date_of_birth:)
        request = Employments::MatchingRequest.new(
          first_name: first_name, last_name: last_name, nino: nino, date_of_birth: date_of_birth
        )
        response = post_request!(request.path, request.payload,
          request.headers(access_token: access_token(timeout: 30)), timeout: 30)
        JSON.parse(response.body)
      rescue Hmrc::ResponseError => e
        raise unless no_match_response?(e.response)

        nil
      end

      def create_user(nino: nil)
        payload = {serviceNames: ["national-insurance"]}
        payload[:nino] = nino if nino.present?
        post_json("/create-test-user/individuals", payload)
      end

      def create_employments(nino:, payload:, from_date: nil, to_date: nil)
        query = {useCase: "DFE"}
        query[:startDate] = from_date if from_date.present?
        query[:endDate] = to_date if to_date.present?
        path = "/individuals/integration-framework-test-support/individuals/employment/nino/#{CGI.escape(nino)}"
        post_json("#{path}?#{URI.encode_www_form(query)}", payload)
      end

      private

      def post_request!(path, payload, headers = nil, timeout: nil)
        log_request("POST", path) { super }
      end

      def get_request!(path, headers = nil, timeout: nil)
        log_request("GET", path) { super }
      end

      def log_request(method, path)
        endpoint = "#{method} #{base_url}#{path}"
        @output.puts "HMRC sandbox: #{endpoint}"
        response = yield
        @output.puts "HMRC sandbox: #{endpoint} -> HTTP #{response.status}"
        response
      rescue Hmrc::ResponseError => e
        @output.puts "HMRC sandbox: #{endpoint} -> HTTP #{e.response.status}"
        raise
      rescue Faraday::Error => e
        @output.puts "HMRC sandbox: #{endpoint} -> #{e.class}"
        raise
      end

      def post_json(path, payload)
        response = post_request!(path, payload.to_json, {
          "Authorization" => "Bearer #{access_token(timeout: 30)}",
          "Accept" => "application/vnd.hmrc.1.0+json",
          "Content-Type" => "application/json"
        }, timeout: 30)
        JSON.parse(response.body)
      end
    end
  end
end
