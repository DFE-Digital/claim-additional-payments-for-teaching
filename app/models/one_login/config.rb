class OneLogin::Config
  def self.instance
    @instance ||= new
  end

  def home_url
    if integration_env?
      "https://home.integration.account.gov.uk/"
    else
      "https://home.account.gov.uk/"
    end
  end

  def bypass?
    (!Rails.env.production? || ENV["ENVIRONMENT_NAME"].start_with?("review")) && ENV["BYPASS_ONELOGIN_SIGN_IN"] == "true"
  end

  def issuer_uri
    ENV["ONELOGIN_SIGN_IN_ISSUER"].present? ? URI(ENV["ONELOGIN_SIGN_IN_ISSUER"]) : nil
  end

  def redirect_uri
    if ENV["ONELOGIN_REDIRECT_BASE_URL"].present?
      URI.join(ENV["ONELOGIN_REDIRECT_BASE_URL"], "/auth/onelogin")
    end
  end

  def secret_key
    if ENV["ONELOGIN_SIGN_IN_SECRET_BASE64"].present?
      OpenSSL::PKey::RSA.new(Base64.decode64(ENV["ONELOGIN_SIGN_IN_SECRET_BASE64"] + "\n"))
    end
  end

  private

  def integration_env?
    ENV.fetch("ONELOGIN_DID_URL", "").include?("integration")
  end
end
