class ServiceManager
  exposed_methods :interval=
  def start
    @interval ||= 60
    begin 
      @poller = FileSystemPoller.new(LOAD_PATH.gsub(/(^.+?[\/\/]+.+?)[\/\/]+.+?$/i, "\\1"))
      loop do
        @poller.poll
        sleep(@interval) # Sleep one minute before polling again
      end
    rescue => e
      raise e
    end
  end
  
  def interval=(i)
    @interval = i    
    ContainerLogger.debug "Deployer poll interval set to #{i}"
  end
end