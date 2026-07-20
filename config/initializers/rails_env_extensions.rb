module RailsEnvExtensions
  def review_app?
    ENV["ENVIRONMENT_NAME"]&.start_with?("review") || false
  end
end

Rails.env.singleton_class.include(RailsEnvExtensions)
