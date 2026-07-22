module TeacherId
  class Config
    def self.instance
      @instance ||= new
    end

    def bypass?
      (Rails.env.development? || Rails.env.review_app_like?) && ENV["BYPASS_DFE_SIGN_IN"] == "true"
    end

    def sign_in_endpoint_uri
      ENV["TID_SIGN_IN_API_ENDPOINT"].present? ? URI(ENV["TID_SIGN_IN_API_ENDPOINT"]) : nil
    end

    def sign_in_redirect_uri
      return @sign_in_redirect_uri if @sign_in_redirect_uri

      if ENV["TID_BASE_URL"].present?
        @sign_in_redirect_uri = URI.parse(ENV["TID_BASE_URL"])
        @sign_in_redirect_uri.path = "/claim/auth/tid/callback"

        if Rails.env.review_app_like?
          @sign_in_redirect_uri.host = ENV["CANONICAL_HOSTNAME"]
        end
      end

      @sign_in_redirect_uri
    end
  end
end
