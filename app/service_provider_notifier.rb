module ServiceProviderNotifier
  DOMAIN_ADDED , DOMAIN_REMOVED                      = "domain added!" , "domain removed!"
  SERVICE_ADDED, SERVICE_REMOVED                     = "service added!", "service removed!"
  SERVICE_STARTED, SERVICE_STOPPED, SERVICE_INVOKED  = "service started!", "service stopped!", 'service method invoked!'
  DOMAIN, SERVICE                                    = "domain group", "service group"
  attr_reader :observers
  
  def update(sender, group, event, params)
    (@observers ||= []).each do |g, e, f|
      next unless g == group && (e==event || e == :all)

      begin
        filter =  (sender.respond_to?(:name)) ? sender.name : ""
        
        if f.nil? || f[:object].nil?
          @service.service_manager.update(group, event, params)
          
        elsif f[:object] == filter
          @service.service_manager.update(group, event, params)
          
        else; end
      rescue
        ContainerLogger.debug $!, 2
      end
    end
  end
  
  # Current filter capabilities
  #  filter {:object => "domain_name[::service_name]"}   [] == optional
  def subscribe(group, event = :all, filter = :none)
    @observers ||= []
    @observers << [group, event, filter]
  end

  def unsubscribe(group, event = :all)
    @observers.reject{|v| v[0..1] == [group, event]}
  end
  
  def const_get(const)
    self.class.const_get(const)
  end
end