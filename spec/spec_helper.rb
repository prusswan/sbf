# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'

# Capybara.register_driver :webkit do |app|
#   driver = Capybara::Webkit::Driver.new(app)
#   driver.browser.set_skip_image_loading true
#   driver
# end

# require 'billy/rspec'

require 'webdrivers'
#require "selenium-webdriver"

options = Selenium::WebDriver::Chrome::Options.new

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  # capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
  #   chromeOptions: { 
  #     args: %w[headless disable-gpu no-sandbox --enable-features=NetworkService,NetworkServiceInProcess]
  #   }
  # )

  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1280,800')

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    options: options
    #desired_capabilities: capabilities,
    #driver_opts: {
    #  verbose: true,
    #  log_path: 'chromedriver.log'
    #}
end

Capybara.default_driver = :headless_chrome # :poltergeist # :webkit
Capybara.javascript_driver = :headless_chrome

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {js_errors:true, port:44678+ENV['TEST_ENV_NUMBER'].to_i, phantomjs_options:['--proxy-type=none'], timeout:300})
end

Capybara.default_max_wait_time = 10

Capybara.configure do |config|
  config.ignore_hidden_elements = false
end

#Capybara::Webkit.configure do |config|
#  config.allow_unknown_urls
#  config.allow_url("m.addthis.com")
#end

# Billy.configure do |c|
#   c.cache = true
#   c.ignore_params = ["http://www.google-analytics.com/__utm.gif",
#                      "https://r.twimg.com/jot",
#                      "http://p.twitter.com/t.gif",
#                      "http://p.twitter.com/f.gif",
#                      "http://www.facebook.com/plugins/like.php",
#                      "https://www.facebook.com/dialog/oauth",
#                      "http://cdn.api.twitter.com/1/urls/count.json"]
#   c.persist_cache = true
#   c.cache_path = 'spec/req_cache/'

#   c.whitelist = ['test.host', 'localhost', '127.0.0.1',
#     # "http://services2.hdb.gov.sg/webapp/BP13INTV/BP13EBSBULIST4",
#     "http://services2.hdb.gov.sg/webapp/BP13INTV/BP13EBPBULIST6.jsp"
#   ]
# end

# # need to call this because of a race condition between persist_cache
# # being set and the proxy being loaded for the first time
# Billy.proxy.restore_cache

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.infer_spec_type_from_file_location!

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end

# https://github.com/thoughtbot/capybara-webkit/issues/840
module Capybara
  class Session

    def save_screenshot(path = nil, options = {})
      options[:width] = current_window.size[0] unless options[:width]
      options[:height] = current_window.size[1] unless options[:height]

      path = prepare_path(path, 'png')
      driver.save_screenshot(path, options)
      path
    end

  end
end
