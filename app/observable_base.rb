require 'singleton'

class ObservableBase
  include Singleton
  DOMAIN_ADDED , DOMAIN_REMOVED                      = "domain added!" , "domain removed!"
  SERVICE_ADDED, SERVICE_REMOVED                     = "service added!", "service removed!"
  SERVICE_STARTED, SERVICE_STOPPED, SERVICE_INVOKED  = "service started!", "service stopped!", 'service method invoked!'
  SERVICE_INSTALLED, SERVICE_UNINSTALLED             = "service installed!", "service removed!"
  DOMAIN, SERVICE                                    = "domain group", "service group"
  attr_reader :observers  
  
  def update(sender, group, event, params)  
    (@observers ||= []).each do|obs, gr, ev, fil|
      next unless gr == group && (ev==event || ev.to_s == "all")
      next unless obs.status() =~ /started/i

      begin        
        if fil.nil? || fil == :none || filter(fil, sender, params)
          obs.service_manager.update(group, event, params)  unless obs.service_manager.nil?
        end
      rescue
        ContainerLogger.error $!, 2
      end
    end
    true
  end
  
  # add_observer-ish method...
  def subscribe(observer, group, event = :all, filter = :none)
    @observers ||= []
    @observers << [observer, group, event, filter]
    ContainerLogger.debug "#{observer.full_name} subscribed to #{group} => #{event} {#{filter}}"    
  end

  # remove_observer-ish method...
  def unsubscribe(observer, group, event = :all)
    @observers.reject{|v| v[0..2] == [observer, group, event]}
  end
    
  # Filter certain events, depending on the sending obj/service
  #  The filter is defined in a service implemention/code-base (through subscribe)
  #  the filter may contain anything that is available with the parmas passed by the events, :domain/:service/:full_name
  #  even methods defined on the sender(obj) may be set as filter, 
  #     f.e. a service sent an invoked event, the filter may contain :full_name
  #     because #<Service: xxx>.full_name is a defined method !
  def filter(set_filter, sender, params)
    return true if set_filter.class == Symbol
    
    results = []
    (set_filter.class==Hash ? set_filter : {}).each do |key, val|
      if sender.respond_to?(key.to_s) && (sender.__send__(key.to_s).to_s == val.to_s)
        results << key
      elsif (params[key.to_s] || params[key.to_sym] || "") == val.to_s
        results << key        
      end
    end
    
    return true if results.size >= set_filter.keys.size
    false  
  end  
end