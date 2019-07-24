OmniAuth.config.test_mode = true
OmniAuth.config.path_prefix = "/admin/auth"
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
