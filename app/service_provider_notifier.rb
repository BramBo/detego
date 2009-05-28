# Copyright (c) 2009 Bram Wijnands<bram@kabisa.nl>
#                                                                     
# Permission is hereby granted, free of charge, to any person         
# obtaining a copy of this software and associated documentation      
# files (the "Software"), to deal in the Software without             
# restriction, including without limitation the rights to use,        
# copy, modify, merge, publish, distribute, sublicense, and/or sell   
# copies of the Software, and to permit persons to whom the           
# Software is furnished to do so, subject to the following      
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
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
        if f.nil? || f == :none || filter(f, sender, params)        
          @providee.service_manager.update(group, event, params)          
                    
        else
          ContainerLogger.debug "FILTERED: Address:#{@providee} Sender:#{sender} -=>> [#{group}, #{event}]"  
        end
      rescue
        ContainerLogger.debug $!, 2
      end
    end    
    true
  end
  
  # add_observer-ish method...
  def subscribe(group, event = :all, filter = :none)
    @observers ||= []
    @observers << [group, event, filter]
  end

  # remove_observer-ish method...
  def unsubscribe(group, event = :all)
    @observers.reject{|v| v[0..1] == [group, event]}
  end
  
  # Just a forward method to enable: $provider.const_get(:SERVICE)
  def const_get(const)
    self.class.const_get(const)
  end
  
  # Filter certain events, depending on the sending obj/service
  #  The filter is defined in a service implemention/code-base (through subscribe)
  #  the filter may contain anything that is available with the parmas passed by the events, :domain/:service/:full_name
  #  even methods defined on the sender(obj) may be set as filter, 
  #     f.e. a service sent an invoked event, the filter may contain :full_name
  #     because #<Service: xxx>.full_name is a defined method !
  def filter(set_filter, sender, params)
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