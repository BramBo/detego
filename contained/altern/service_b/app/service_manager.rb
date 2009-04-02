class ServiceManager
  exposed_methods :say_hello, :approach_root_test_service
  
  def say_hello(str="")
    return "hello from #{$service[:full_name]} #{str}"
  end
  
  def approach_root_test_service
     $provider.on(:root, :service_a).set_status("#{$service[:full_name]} infiltrated :root::service_a!") 
     
     ## Error call can't let the provider crash the container here !
     $provider.on(:root, :serviceasd_a).set_status("#{$service[:full_name]} infiltrated :root::service_a!") 
  end
  
  def start
    
  end
end