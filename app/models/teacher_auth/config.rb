module TeacherAuth
  class Config
    def self.instance
      @instance ||= new
    end

    def bypass?
      (Rails.env.development? || ENV["ENVIRONMENT_NAME"].start_with?("review")) && ENV["BYPASS_TEACHER_AUTH"] == "true"
    end

    def callback_path
      @callback_path ||= "#{path_prefix}/teacher/callback"
    end

    def path_prefix
      @path_prefix ||= "/early-years-teachers-financial-incentive-payments/auth"
    end

    def issuer
      @issuer ||= ENV["TEACHER_AUTH_ISSUER"]
    end

    def host
      @host ||= URI.parse(issuer).host
    end

    def redirect_base_url
      return @redirect_base_url if @redirect_base_url

      @redirect_base_url = URI.parse(ENV["TEACHER_AUTH_REDIRECT_BASE_URL"].presence || "https://www.claim-additional-teaching-payment.service.gov.uk")

      if ENV["ENVIRONMENT_NAME"].start_with?("review")
        @redirect_base_url.host = ENV["CANONICAL_HOSTNAME"]
      end

      @redirect_base_url
    end

    def redirect_uri
      @redirect_uri ||= "#{redirect_base_url}#{path_prefix}"
    end

    def jwks_uri
      @jwks_uri ||= ENV["TEACHER_AUTH_JWKS_URI"]
    end
  end
end
