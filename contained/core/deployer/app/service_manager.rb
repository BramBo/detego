class ServiceManager
  def start
    @interval ||= 90
    begin 
      @poller = FileSystemPoller.new(LOAD_PATH.gsub(/(^.+?[\/\/]+.+?)[\/\/]+.+?$/i, "\\1"))
      loop do
        @poller.poll
        sleep(@interval) # Sleep by default one minute before polling again
      end
    rescue => e
      ContainerLogger.debug e, 1
      raise e
    end
  end
end