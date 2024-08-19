class OneLogin::Config
  def self.home_url
    if integration_env?
      "https://home.integration.account.gov.uk/"
    else
      "https://home.account.gov.uk/"
    end
  end

  def self.integration_env?
    ENV.fetch("ONELOGIN_DID_URL", "").include?("integration")
  end
end
