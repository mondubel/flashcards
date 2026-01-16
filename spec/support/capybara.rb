# Capybara configuration for system tests
require 'capybara/rspec'
require 'selenium-webdriver'

# Use rack_test driver for non-JavaScript tests (faster and more reliable)
Capybara.default_driver = :rack_test

# Use Selenium with headless Chrome for JavaScript tests
Capybara.javascript_driver = :selenium_chrome_headless

# Configure wait times
Capybara.default_max_wait_time = 5

# Configure Chrome options for headless mode
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1920,1080')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
