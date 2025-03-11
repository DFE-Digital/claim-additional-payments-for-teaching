require "webmock/rspec"

WebMock.disable_net_connect!(allow: %w[127.0.0.1])
