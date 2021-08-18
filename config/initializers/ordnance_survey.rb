OrdnanceSurvey.configure do |config|
  def parse_string(string:, content_type: :string)
    raise ArgumentError if [:hash, :string].exclude?(content_type)
    return if string.blank?

    case content_type
    when :string
      string
    when :hash
      JSON.parse(string.gsub("=>", ":"), symbolize_names: true)
    end
  end

  config.client.base_url = parse_string(string: ENV["ORDNANCE_SURVEY_API_BASE_URL"])
  config.client.params = parse_string(string: ENV["ORDNANCE_SURVEY_CLIENT_PARAMS"], content_type: :hash)
end
