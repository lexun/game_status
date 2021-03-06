require 'rubygems'
require 'spork'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'

  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'capybara/rspec'

  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.include FactoryGirl::Syntax::Methods
    config.include Devise::TestHelpers, :type => :controller
    config.extend ControllerMacros, :type => :controller
    config.mock_with :mocha
    config.use_transactional_fixtures = true
    config.infer_base_class_for_anonymous_controllers = false
    config.order = "random"

    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true
  end
end

Spork.each_run do
  FactoryGirl.reload
  $VERBOSE = nil
  Dir["#{Rails.root}/app/models/**/*.rb"].each { |model| load model }
  $VERBOSE = false
  Rails.application.reload_routes!
end
