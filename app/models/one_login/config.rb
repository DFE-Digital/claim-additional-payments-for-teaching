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

  private

  def integration_env?
    ENV.fetch("ONELOGIN_DID_URL", "").include?("integration")
  end
end
