# First code to be executed when Detego boots
$: << "#{LOAD_PATH}/app"
require "service_manager"

ServiceCodeBase::Initializer.configure do |config|
  config.dont_save  = false
  config.dont_start = false
end