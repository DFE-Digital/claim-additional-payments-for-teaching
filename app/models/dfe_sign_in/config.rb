module DfeSignIn
  class Config
    def self.instance
      @instance ||= new
    end

    def bypass?
      (Rails.env.development? || ENV["ENVIRONMENT_NAME"].start_with?("review")) && ENV["BYPASS_DFE_SIGN_IN"] == "true"
    end

    def issuer_uri
      ENV["DFE_SIGN_IN_ISSUER"].present? ? URI(ENV["DFE_SIGN_IN_ISSUER"]) : nil
    end

    def redirect_uri
      return @redirect_uri if @redirect_uri

      if ENV["DFE_SIGN_IN_REDIRECT_BASE_URL"].present?
        @redirect_uri = URI.join(ENV["DFE_SIGN_IN_REDIRECT_BASE_URL"], "/admin/auth/callback")
      end
    end

    def fe_provider_redirect_uri
      return @fe_provider_redirect_uri if @fe_provider_redirect_uri

      if ENV["DFE_SIGN_IN_REDIRECT_BASE_URL"].present?
        @fe_provider_redirect_uri = URI.join(ENV["DFE_SIGN_IN_REDIRECT_BASE_URL"], fe_provider_callback_path)
      end
    end

    def fe_provider_callback_path
      "/further-education-payments-provider/auth/callback"
    end
  end
end
