class ServiceManager
  attr_accessor :hallo, :hoi
  attr_reader   :read_only
  attr_writer   :write_only  
  exposed_methods :say_hello, :set_status, :get_status
  
  def initialize
    @hallo      = "Hello"
    @hoi        = "Hey"
    @write_only = "NOT READABLE"
    @read_only  = "READ ONLY"
  end

  def say_hello
    return "hello from hello.rb in #{$service[:full_name]} #{str} Status: #{$state}"
  end

  def set_status(str)
    $state = str
  end
  
  def get_status
    return "#{$service[:full_name]} status: #{$state}"
  end
  
  def start
     $provider.for($service[:domain].to_sym, $service[:name].to_sym).set_status("Started")     
  end
end