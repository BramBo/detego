# General purpose first class methods
#  To prevent the Service init-codebase method to become unreadable.
#   If you doubt this solution please consider all these methods (and service_manager.class.rb) living in one giant String...
#   Also; All suggestions are welcomed !

# Sets the Standard Streams(STDOUT && STDERR) to the service log path
# The service log files are saved under the convention: CONTAINER_PATH/log/#{service.domain.name}_#{service.name}.log
def rewire_standard_streams
  Object.send(:remove_const, :STDERR)
  Object.send(:remove_const, :STDOUT)
  $stderr = File.open("#{CONTAINER_PATH}/log/#{$service[:domain]}_#{$service[:name]}.log", 'w+')
  $stdout = File.open("#{CONTAINER_PATH}/log/#{$service[:domain]}_#{$service[:name]}.log", 'w+')
  Object.send(:const_set, :STDERR, File.open("#{CONTAINER_PATH}/log/#{$service[:domain]}_#{$service[:name]}.log", 'w+'))
  Object.send(:const_set, :STDOUT, File.open("#{CONTAINER_PATH}/log/#{$service[:domain]}_#{$service[:name]}.log", 'w+'))  
end

# includes the container logger and setsup the ServiceLogger obj after
def setup_logging
  require "container_logger"
  ServiceLogger.service="#{$service[:domain]}_#{$service[:name]}"  
end

# Try to load initialize or (if it fails) service_manager
# |> If both fail, the service doesn't meet the requirements and will raise an Exception
def load_codebase_initialize
  begin                
      require 'initialize'
  rescue LoadError 
    begin
      require 'service_manager'
    rescue LoadError        
      raise Exception.new("Neither initialize or ServiceManager could be loaded for #{$service[:full_name]}")
    end
  end
end

# Initialize the communication to and from the Container
# This comm. is setup with two DRb-objects:
#  $provider        -> connection-point of the server  (127.0.0.1:port_in)
#  $service_manager -> connection-point to the service (127.0.0.1:port_out)
def setup_DRb_services
  DRb.install_acl( ACL.new( %w{deny all allow localhost allow 127.0.0.1}) )
   
  $provider = DRbObject.new(nil, "druby://127.0.0.1:#{$service[:port_in]}")
  $provider.for("#{$service[:domain]}".to_sym, "#{$service[:name]}".to_sym).status = "Booting.."  
      
  @serv = DRb.start_service "druby://127.0.0.1:#{$service[:port_out]}", ($service_manager=ServiceManager.new)
end

def stop()
  Object.send(:const_set, :NO_START, true)
end

def no_save()
  Object.send(:const_set, :NO_SAVE, true)
end