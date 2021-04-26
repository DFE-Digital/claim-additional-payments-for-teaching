Dqt.configure do |config|
  def json_to_hash(json)
    JSON.parse(json.gsub("=>", ":"), symbolize_names: true)
  end

  config.client.headers = json_to_hash(ENV["DQT_CLIENT_HEADERS"]) if ENV["DQT_CLIENT_HEADERS"]
  config.client.host = ENV["DQT_CLIENT_HOST"] if ENV["DQT_CLIENT_HOST"]
  config.client.params = json_to_hash(ENV["DQT_CLIENT_PARAMS"]) if ENV["DQT_CLIENT_PARAMS"]
  config.client.port = ENV["DQT_CLIENT_PORT"].to_i if ENV["DQT_CLIENT_PORT"]
end
