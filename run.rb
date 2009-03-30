##################################
##        Should be server      ##
##################################
require "config/config.rb"
require "container"
require "service_provider"
require 'drb'

container     = Container.new

#
# Server Start...
#
container.add_domain(:root).add_service(:test_script).start()
container.add_domain(:approach).add_service(:test_script).start()

###################################
##     Should be invoked by      ##
##  client / installed services  ##
##     Through Server facade     ##
###################################
root        = container.find(:root)
test_script = root.find(:test_script)

puts "Method invocation: ".console_dark_yellow + String.new(test_script.invoke(:get_status))
container.find(:approach).find(:test_script).invoke(:approach_root_test_service)
puts "Method invocation: ".console_dark_yellow + String.new(test_script.invoke(:get_status))