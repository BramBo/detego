# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def list(collection, type="elements", link_path=nil)
    if collection.size>0
      r ="<ul class='list_helper'>"
      collection.each do |e|
        if link_path.nil?
          r += "<li class='ui-helper-reset ui-corner-bottom''>#{e.to_s}</li>"
        else
          if e.public_methods.include?("parent_route")
            r += "<li class='ui-corner-bottom'>"+link_to("#{(e).to_s}", eval("#{link_path}(e.parent_route, e)"))+"</li>"            
          else
            r += "<li class='ui-corner-bottom'>"+link_to("#{e.to_s}", eval("#{link_path}(e)"))+"</li>"            
          end
        end
      end
      
      return r+"</ul>"
    else
      "<p class='no_list_elements'>No #{type}</p>"
    end
  end
  
  
  def status_to_icon(status)
    img = "<img class='service_status' src='"
    case status  
     when /started/i then
      img += "/images/started.png"
     when /run/i then
      img += "/images/running.png"
     when /stop/i then
      img += "/images/stopped.png"      
     when /boot/i then
      img += "/images/booting.png"        
     else
      img += "/images/stopped.png"          
    end
    img+"' alt='#{status}' title='#{status}' />"
  end
end
