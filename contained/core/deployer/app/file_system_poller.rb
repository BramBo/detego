class FileSystemPoller
  attr_reader :current_structure, :old_structure
  
  def initialize(path)
    @path     = path
    get_current_structure
  end
  
  def poll
    begin
      ContainerLogger.debug "New poll (#{Time.now}) #{$service[:full_name]}"
      @old_structure = @current_structure
      get_current_structure
    
      # check for missing entities in the old directory tree
      (@old_structure.keys - @current_structure.keys).to_a.each do |d|
        # domain got deleted !
        ContainerLogger.warn "Domain #{d} got deleted!"                
        $provider.remove_domain(d.to_sym)
      end
    
      # Check for new entities in the current directory tree
      (@current_structure.keys - @old_structure.keys).to_a.each do |d|
         ContainerLogger.debug "found new Domain! #{d}"            
        # found new domain
        @current_structure[d].each do |s|
         ContainerLogger.debug "New service discovered! #{d}::#{s}"                 
          $provider.add_service(d.to_sym, s.to_sym)    
        end
      end

      # finally check for deleted services within the current domains
      @current_structure.each do |k, d|

        unless @old_structure[k].nil?
          (@current_structure[k] - @old_structure[k]).to_a.each do |s|
            ContainerLogger.debug "New service discovered! #{k}::#{s}"                  
            $provider.add_service(k.to_sym, s.to_sym)             
          end
      
          (@old_structure[k] - @current_structure[k]).to_a.each do |s|      
            ContainerLogger.warn "Service removed! #{k}::#{s}"            
            $provider.remove_service(k.to_sym, s.to_sym)             
          end
        end
      end
    rescue => ex
      ContainerLogger.error ex, 0
      ContainerLogger.error ex, 1
      ContainerLogger.error ex, 2            
    end
  end
  
  private 
    def get_current_structure
      @current_structure = {}
      begin
        Dir.new(@path).each do |domain|
          ServiceUnPacker.new(@path, domain) if ServiceUnPacker.supported_file_type?(domain)
          domain_dir = "#{@path}/#{domain}/"
        
          next if domain =~ /^\.{1,2}/ || !File.directory?(domain_dir) 
          read_dir(domain)
        
        end
      rescue => e
        ContainerLogger.debug e, 1
        puts e
      end
      @current_structure
    end
    
    def read_dir(domain)      
      Dir.new("#{@path}/#{domain}").each do |service|
        ServiceUnPacker.new(@path, domain, service) if ServiceUnPacker.supported_file_type?(service)        
        
        service_dir = "#{@path}/#{domain}/#{service}"
        next if service =~ /^\.{1,2}/ || !File.directory?(service_dir) 
          @current_structure[domain] ||= []
          @current_structure[domain] << service
      end
    end
end