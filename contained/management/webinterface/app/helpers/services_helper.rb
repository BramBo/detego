module ServicesHelper
  def var_list(collection, type="elements", mode="r")
    if collection.size>0
      r ="<ul class='var_list_helper'>\n"
      collection.each do |e|
        r += "\t <li>\n\t  <span class='ui-triangle'></span><span>#{e[0].to_s}</span>\n"
        value = (e[1].to_s.size>0) ? e[1].to_s : "-----"
        
        if mode == "r"
          r += "\t  <span class='value'>#{value}</span>\n"
        else
          r += "\t  <span class='variable_value value' title='Click to set this parameter'><span>#{value}</span><img src='/images/icons/script_go.png' class='var_control' /></span>\n"
        end
        
        r += "\t </li>\n"
      end
      
      return r+"\t</ul>"
    else
      "\t<p class='no_list_elements'>No #{type}</p>"
    end
  end  
  
  # Nasty method, "abuses" e[1] for two purposes
  # 
  def method_list(collection, type="elements", use="for show", handler="def")
    if collection.size>0
      r ="<ul class='meth_list_helper'>\n"
      collection.each do |e|
        click_handler = (e.class==Array && handler != "def") ? "click=\"#{e[1]}\"" : ""
        n             = (e.class==Array) ? e[0]       : e
        parameters    = (e.class==Array) ? e[1].to_a  : []
        
        r += "\t <li>\n\t  <span class='ui-triangle'></span><span>#{n.to_s}</span>\n"
        
        if use=="runnable"
          # Rb_Arr: ["a", "b"] ::to js func call => w_parameters(['a', 'b'])
          str           = parameters.map{|e|e = %{'#{e}'}}.join(", ")
          click_handler = %{click="w_parameters(this, [#{str}])"} if parameters.size > 0 && handler == "def"
          name          = (parameters.size > 0) ? " name='modal' href='#dialog'" : ""
          
          r += "\t  <span class='value'><img src='/images/invoke.png' #{click_handler} class='runnable_method' alt=\"Invoke #{n} on #{$service[:full_name]}' title='Invoke #{n} on #{$service[:full_name]}\" /></span>\n"
        end
        
        r += "\t </li>\n"
      end
      
      return r+"\t</ul>"
    else
      "\t<p class='no_list_elements'>No #{type}</p>"
    end
  end
end
