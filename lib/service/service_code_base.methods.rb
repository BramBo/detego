def rewire_standard_streams
  Object.send(:remove_const, :STDERR)
  Object.send(:remove_const, :STDOUT)
  $stderr = File.open("#{CONTAINER_PATH}/log/#{$service[:domain]}_#{$service[:name]}.log", 'w+')
  $stdout = File.open("#{CONTAINER_PATH}/log/#{$service[:domain]}_#{$service[:name]}.log", 'w+')  
  Object.send(:const_set, :STDERR, $stderr)
  Object.send(:const_set, :STDOUT, $stdout)  
end

def setup_logging
  require "container_logger"
  ServiceLogger.service="#{$service[:domain]}_#{$service[:name]}"  
end

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

def setup_DRb_services
  DRb.install_acl(
    ACL.new( 
      %w[deny all
         allow localhost 
         allow 127.0.0.1]
   ))
   
  $provider = DRbObject.new(nil, "druby://127.0.0.1:#{$service[:port_in]}")
  $provider.for("#{$service[:domain]}".to_sym, "#{$service[:name]}".to_sym).status = "Booting.."  
  
  @serv = DRb.start_service "druby://127.0.0.1:#{$service[:port_out]}", ($service_manager=ServiceManager.new)
end