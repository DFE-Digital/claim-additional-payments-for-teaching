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
  end
end
