class XMLFormat < BASEFormat
  def <<(hsh)
    options = 
      if hsh[:options]
        str = ""
        hsh[:options].each do |k,v|
          str += %{#{k}="#{v}" }  
        end 
        str
      else
        ""
    end
    
    key     = (hsh[:list_open]) ? "<#{xf(hsh[:list_open])} #{options}>" : (hsh[:list_close]) ? "</#{xf(hsh[:list_close])} #{options}>" : "<#{xf(hsh[:key])} #{options} />"
    @content += key
  end

  def out
     return %{<?xml version='1.0' encoding='UTF-8'?>\n#{@content}}
  end
  
  def xf(str)      # illegal characters allowed in method names !
   return str.gsub(/\=/, "")
  end
end
