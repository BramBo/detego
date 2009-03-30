class ServiceManager
  exposed_methods :say_hello, :approach_root_test_service
  
  def say_hello(str="")
    return "hello from #{$service[:full_name]} #{str}"
  end
  
  def approach_root_test_service
     $provider.on(:root, :test_script).set_status("#{$service[:full_name]} infiltrated :root::test_script!")
  end
end