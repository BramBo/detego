# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def list(collection, type="elements", link_path=nil)
    if collection.size>0
      r ="<ul class='list_helper'>"
      collection.each do |e|
        if link_path.nil?
          r += "<li>#{e.to_s}</li>"
        else
          if e.public_methods.include?("parent_route")
            r += "<li>"+link_to("#{e.to_s}", eval("#{link_path}(e.parent_route, e)"))+"</li>"            
          else
            r += "<li>"+link_to("#{e.to_s}", eval("#{link_path}(e)"))+"</li>"            
          end
        end
      end
      
      return r+"</ul>"
    else
      "<p class='no_list_elements'>No #{type}</p>"
    end
  end
end
