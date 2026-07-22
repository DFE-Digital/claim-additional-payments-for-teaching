module RailsEnvExtensions
  def enable_home_components?
    !production? || review_app? || staging_app? || test_app?
  end

  def test_app?
    ENV["ENVIRONMENT_NAME"] == "test"
  end

  def staging_app?
    ENV["ENVIRONMENT_NAME"] == "staging"
  end

  def review_app?
    ENV["ENVIRONMENT_NAME"]&.start_with?("review") || false
  end
end

Rails.env.singleton_class.include(RailsEnvExtensions)
