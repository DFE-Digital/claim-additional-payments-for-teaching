Dqt.configure do |config|
  def parse_string(string:, content_type: :string)
    raise ArgumentError if [:hash, :integer, :string].exclude?(content_type)
    return if string.blank?

    case content_type
    when :string
      string
    when :hash
      JSON.parse(string.gsub("=>", ":"), symbolize_names: true)
    when :integer
      string.to_i
    end
  end

  config.client.headers = parse_string(string: ENV["DQT_CLIENT_HEADERS"], content_type: :hash)
  config.client.host = parse_string(string: ENV["DQT_CLIENT_HOST"])
  config.client.params = parse_string(string: ENV["DQT_CLIENT_PARAMS"], content_type: :hash)
  config.client.port = parse_string(string: ENV["DQT_CLIENT_PORT"], content_type: :integer)
end
