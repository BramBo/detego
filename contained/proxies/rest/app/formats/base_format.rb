class BASEFormat 
  attr_reader :content
  
  def initialize()
    @content = ""
  end  
  
    def <<(hsh)
      options = 
        if hsh[:options]
          str = ""
          hsh[:options].each do |k,v|
            str += %{#{k}=#{v} }  
          end 
          str
        else
          ""
      end

      key     = (hsh[:list_open]) ? "#{hsh[:list_open]} #{options}" : (hsh[:list_close]) ? "#{hsh[:list_close]} #{options}" : "#{hsh[:key]} #{options}"
      @content += key
    end

    def out
       return @content
    end

    def inspect;  out; end 
    def to_s;     out; end
end