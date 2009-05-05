class XHTMLFormat
  attr_reader :content, :last_open  
  
  def initialize()
    @content    = ""
    @last_open  = 0
  end

  def <<(hsh)
    options = 
      if hsh[:options]
        str = "<ul>"
        hsh[:options].each do |k,v|
          str += %{<li><b>#{k}</b> #{v}</li> }  if v.size > 0
        end 
        str += "</ul>"
      else
        ""
    end
    
    key     = (hsh[:options]) ? "#{header(hsh)} #{options}"  : "#{header(hsh)}"

    @content += key
  end

  def out
     return %{
     <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
     <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
     <head></head>
      <body>
       #{@content}
      </body>
     </html>
     }
  end

  def inspect; out; end 
  def to_s;    out; end
  
  def header(hsh)
    @last_open +=  1 if (hsh[:list_open] || hsh[:key])    
    r           = "<h#{last_open}>#{(hsh[:key] || hsh[:list_open] || hsh[:list_close])}</h#{last_open}>"
    @last_open -=  1 if (hsh[:list_close] ||hsh[:key])
    r
  end
end
