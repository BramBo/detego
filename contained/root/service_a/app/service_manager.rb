class ServiceManager
  exposed_methods :say_hello, :set_status, :get_status

  def say_hello
    return "hello from hello.rb in #{$service[:full_name]} #{str} Status: #{$state}"
  end

  def set_status(str)
    $state = str
  end
  
  def get_status
    return "#{$service[:full_name]} status: #{$state}"
  end
end