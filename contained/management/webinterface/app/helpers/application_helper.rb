# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def list(collection, type="elements", link_path=nil)
    if collection.size>0
      r ="\t<ul class='list_helper'>\n"
      collection.each do |e|
        if link_path.nil?
          r += "\t\t<li class='ui-helper-reset ui-corner-bottom''>#{e.to_s}</li>\n"
        else
          if e.public_methods.include?("parent_route")
            r += "\t\t<li class='ui-corner-bottom'>"+link_to("#{(e).to_s}", eval("#{link_path}(e.parent_route, e)"))+"</li>\n"            
          else
            r += "\t\t<li class='ui-corner-bottom'>"+link_to("#{e.to_s}", eval("#{link_path}(e)"))+"</li>\n"            
          end
        end
      end
      
      return r+"\t</ul>\n"
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
