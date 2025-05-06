require 'bundler/setup'
Bundler.require

# Require all models and controllers
Dir[File.join(File.dirname(__FILE__), "../app/models/*.rb")].each { |file| require file }
Dir[File.join(File.dirname(__FILE__), "../app/controllers/*.rb")].each { |file| require file }
