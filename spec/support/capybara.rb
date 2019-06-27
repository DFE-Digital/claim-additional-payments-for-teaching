require "capybara/rspec"
begin
  require "webdrivers"
rescue LoadError
  nil
end

Capybara.register_driver :headless_chrome do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new(
      args: %w[headless disable-dev-shm-usage no-sandbox]
    )
  )
end

Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = :headless_chrome
  config.default_max_wait_time = 5
end

Capybara.automatic_label_click = true
