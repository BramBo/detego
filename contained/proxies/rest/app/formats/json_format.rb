class JSONFormat < BASEFormat
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
    
    key     = (hsh[:list_open]) ? "<#{xf(hsh[:list_open])}>" : (hsh[:list_close]) ? "</#{xf(hsh[:list_close])}>" : "<#{xf(hsh[:key])} #{options} />"
    @content += key
  end

  
  def xf(str)      # illegal characters allowed in method names !
   return str.gsub(/\=/, "")
  end
end
