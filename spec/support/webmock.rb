require "webmock/rspec"

WebMock.disable_net_connect!(allow: %w[chromedriver.storage.googleapis.com 127.0.0.1])
