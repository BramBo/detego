require 'socket'


class RESTListener

  def initialize(port=5055)
      @port = port    
    begin 
      @serv = TCPServer.new(@port.to_i)    
    rescue => e
      puts e
    end
  end
  
  def start
    puts "#{self.class} started on port: #{@port}"    
    while true
      @t = Thread.new(@serv.accept) do |session|
        prot  = session.addr[0]
        cmd   = session.gets.chomp

        query(session, cmd)
        session.close
      end

    end
  end  
  
  def stop()
    @serv = nil
  end
  
  private
  
   def query(session, gets)
     @params      = gets.gsub(/^(GET|POST)[\s]*(?=\/)/i, "")
     @params      = @params.gsub(/^\/([^\s]*?)\s.+?$/, "\\1")
     @params.gsub!(/\?[a-z]+\=([a-z]+?)$/i, "")
     
     format_str   = $1 || "xml"          
     list         = @params.split(/\//) || []
     format       =  eval("#{format_str.upcase}Format").new()

     case list.size 
      when 0        # /
       session.print(domain_list(format, list))
       
     when 1         # /domain_name    
       session.print(domain_services(format, list))

     when 2         # /domain_name/service_name
       session.print(service_methods(format, list))       

     else
       
       session.print "Service method invocation\n"              
       session.print "#{list[0]}::#{list[1]}.#{list[2]}()"              
     end
          
   end
   
   def domain_list(format, list)
     format << {:list_open => "domains"}

     $provider.get_domains().each do |s|
         format << {:key => "domain", :options => {:name => "#{s}"}}
     end
     format << {:list_close => "domains"}
     format     
   end
   
   def domain_services(format, list)
     format << {:list_open => "services"}

     $provider.for(list[0].to_sym).get_services().each do |s|
         format << {:key => "service", :options => {:full_name => "#{list[0]}::#{s}", :name => "#{s}"}}
     end
     format << {:list_close => "services"}
     format
   end
   
   def service_methods(format, list)
     format << {:list_open => "meta_data"}

     $provider.for(list[0].to_sym, list[1].to_sym).get_meta_data().each do |key, meta|
       
       # service_methods/exposed_variables/readable_var_values
        format << {:list_open => "#{key}"}       
        
        # exposed/all/both/write/read/val_name
        meta.each do |m_k, m_v|
          options = {}
          if m_v.class == Hash || m_v.class == Array
            format << {:list_open => "#{m_k}"}          
          
            m_v.each do |a,b|
                options = {:parameters => "#{b}"} if b
                format << {:key => "#{a}", :options => options}
            end
            format << {:list_close => "#{m_k}"}
            
            #readable vars
          else
            format << {:key => "#{m_k}", :options => {:value => "#{m_v}"}}
          end
        end
        
        format << {:list_close => "#{key}"}
      end
     format << {:list_close => "meta_data"}
     format
   end
end