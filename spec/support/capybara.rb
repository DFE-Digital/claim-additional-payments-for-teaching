require "capybara/rspec"
begin
  require "webdrivers"
rescue LoadError
  nil
end

view_mode = (ENV.fetch("VIEW", false) == "true") ? :chrome : :headless_chrome
args = %w[disable-dev-shm-usage no-sandbox window-size=1280x1280]
args <<= "headless" unless view_mode == :chrome

Capybara.register_driver view_mode do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Options.chrome(
      args: args
    )
  )
end

Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = view_mode
  config.default_max_wait_time = 5
  config.server = :puma, {Silent: true}
end

Capybara.automatic_label_click = true

RSpec.configure do |config|
  config.around(:each, :smoke) do |example|
    Capybara.current_driver = Capybara.javascript_driver
    Capybara.run_server = false
    example.run
    Capybara.run_server = true
    Capybara.current_driver = Capybara.default_driver
  end
end
