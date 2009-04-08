class ServiceManager
  attr_accessor :interval
  exposed_methods :poll 
  
  def initialize 
     @poller     = FileSystemPoller.new(LOAD_PATH.gsub(/(^.+?[\/\/]+.+?)[\/\/]+.+?$/i, "\\1"))
     @interval ||= 10     
  end
  
  def start  
    begin  
    $provider.for($service[:domain].to_sym, $service[:name].to_sym).set_status("Running..")           
      loop do
        @poller.poll
        sleep(interval) # Sleep by default one minute before polling again
      end
    rescue => e
      ContainerLogger.debug e, 1
      raise e
    end
  end
  
  def poll
    @poller.poll 
  end
end