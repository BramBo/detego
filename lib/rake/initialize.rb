# First code to be executed when Detego boots
$: << "#{LOAD_PATH}/app"
require "service_manager"

ServiceCodeBase::Initializer.configure do |config|
  config.no_save    = false
  config.dont_save  = false
end