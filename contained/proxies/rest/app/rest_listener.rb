require 'socket'

class RESTListener
  def initialize(port=5055)
      @port = port    
  end
  
  def start
    begin 
      @serv = TCPServer.new(@port.to_i)    
    rescue => e
      puts e
      return false
    end    
    puts "#{self.class} started on port: #{@port}"    
    while true
      @t = Thread.new(@serv.accept) do |session|
        prot  = session.addr[0]
        cmd   = session.gets.chomp

        query_print(session, cmd)
        session.close
      end
    end
  end  
  
  def stop()
    @serv = nil
  end
  
  private
   def query_print(session, gets)
     @params      = gets.gsub(/^(GET|POST)[\s]*(?=\/)/i, "")
     @params      = @params.gsub(/^\/([^\s]*?)\s.+?$/, "\\1")
     @params.gsub!(/\?[a-z]+\=([a-z]+?)$/i, "")
     
     format_str   = $1                  || "xml"          
     list         = @params.split(/\//) || []
     @format      =  eval("#{format_str.upcase}Format").new()

     case list.size 
      when 0        # /
       session.print(domain_list(list))
       
      when 1         # /domain_name    
       session.print(domain_services(list))

      when 2         # /domain_name/service_name
       session.print(service_methods(list))       

     else
       session.print(method_invocation(list))              
     end
          
   end
   
   def domain_list(list)
     @format << {:list_open => "domains"}

     $provider.get_domains().each do |s|
         @format << {:key => "domain", :options => {:name => "#{s}"}}
     end
     @format << {:list_close => "domains"}
     @format     
   end
   
   def domain_services(list)
     @format << {:list_open => "services"}

     $provider.for(list[0].to_sym).get_services().each do |s|
         @format << {:key => "service", :options => {:name => "#{s}",:full_name => "#{list[0]}::#{s}"}}
     end
     @format << {:list_close => "services"}
     @format 
   end
   
   # better format, because of the lack of data structure in meta-data
   def service_methods(list)
     @format << {:list_open => "meta_data"}

     begin 
       $provider.for(list[0].to_sym, list[1].to_sym).get_meta_data().each do |key, meta|
       # service_methods/exposed_variables/readable_var_values
        @format << {:list_open => "#{key}"}       
        
        # exposed/all/both/write/read/val_name
        meta.each do |m_k, m_v|
          options = {}
          if m_v.class == Hash || m_v.class == Array
            @format << {:list_open => "#{m_k}"}          
          
            m_v.each do |a,b|
                options = {:parameters => "#{b}"} if b
                @format << {:key => "#{a}", :options => options}
            end
            @format << {:list_close => "#{m_k}"}
            
            #readable vars
          else
            @format << {:key => "#{m_k}", :options => {:value => "#{m_v}"}}
          end
        end
        
        @format << {:list_close => "#{key}"}
      end
     @format << {:list_close => "meta_data"}
     @format    
    rescue => e
       puts e
       return "ERRORS"
    end
   end
   
   # Should be this method ! 
   def service_methods2(list)
     @format << {:list_open => "meta_data"}

     begin
       result = $provider.for(list[0].to_sym, list[1].to_sym).get_meta_data()       
       recursive_format("methods", result)
     rescue => e
       puts e
     end
     
     @format << {:list_close => "meta_data"}
     @format    
   end   
   
   def method_invocation(list)
     @format << {:list_open => "results"}

     result = eval("$provider.for(:#{list[0]}, :#{list[1]}).#{list[2]}")
     begin
       recursive_format("result", result)
     rescue => e
       puts e
     end

     @format << {:list_close => "results"}
     @format    
   end
   
   def recursive_format(key, data)
     case data.class.to_s
      when Hash.to_s
        data.each do |k,v| 
          @format << {:list_open => "#{k}"}
          recursive_format(k, v)
          @format << {:list_close => "#{k}"}          
        end
      when Array.to_s
          @format << {:list_open => "#{key}"}        
        data.each do |v| 
          recursive_format(key, v)
        end
        @format << {:list_close => "#{key}"}        
     else
        @format << {:key => "#{key}", :options => {:value => "#{data}"}}
     end   
   end
end