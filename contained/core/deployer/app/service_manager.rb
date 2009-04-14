class ServiceManager
  attr_accessor :interval, :message_stack
  exposed_methods :poll 
  
  def initialize 
     @message_stack = []  
     @poller     = FileSystemPoller.new(LOAD_PATH.gsub(/(^.+?[\/]+.+?)\/[^\/]+?\/[^\/]+?$/i, "\\1"), self)
     @interval ||= 120     
  end
  
  def start  
    begin  
    $provider.for($service[:domain].to_sym, $service[:name].to_sym).status = "Running.."
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
    @message_stack = []
    @poller.poll
    return @message_stack
  end
end