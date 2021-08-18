require "capybara/rspec"
begin
  require "webdrivers"
rescue LoadError
  nil
end

view_mode = ENV.fetch("VIEW", false) == "true" ? :chrome : :headless_chrome
args = %w[disable-dev-shm-usage no-sandbox window-size=1280x1280]
args = args << "headless" unless view_mode == :chrome

Capybara.register_driver view_mode do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new(
      args: args
    )
  )
end

Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = view_mode
  config.default_max_wait_time = 5
end

Capybara.automatic_label_click = true
