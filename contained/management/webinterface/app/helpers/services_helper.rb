module ServicesHelper
  def list(collection, type="elements")
    if collection.size>0
      r ="<ul>"
      collection.each do |e|
        r += "<li>#{e}</li>"
      end
      
      return r+"</ul>"
    else
      "<p class='no_list_elements'>No #{type}</p>"
    end
  end
end
