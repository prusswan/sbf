# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rspec'
require 'capybara/poltergeist'

# Capybara.register_driver :webkit do |app|
#   driver = Capybara::Webkit::Driver.new(app)
#   driver.browser.set_skip_image_loading true
#   driver
# end

# require 'billy/rspec'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {js_errors:true, port:44678+ENV['TEST_ENV_NUMBER'].to_i, phantomjs_options:['--proxy-type=none'], timeout:300})
end

Capybara.default_driver = :webkit # :poltergeist
Capybara.default_wait_time = 10

Capybara.configure do |config|
  config.ignore_hidden_elements = false
end

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

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end
