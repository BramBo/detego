# Copyright (c) 2009 Bram Wijnands
#                                                                     
# Permission is hereby granted, free of charge, to any person         
# obtaining a copy of this software and associated documentation      
# files (the "Software"), to deal in the Software without             
# restriction, including without limitation the rights to use,        
# copy, modify, merge, publish, distribute, sublicense, and/or sell   
# copies of the Software, and to permit persons to whom the           
# Software is furnished to do so, subject to the following      
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.


# Will scan the given path 2 dimension deep on new directory or files where ServiceUnpacker responds to
class FileSystemPoller
  attr_reader :current_structure, :old_structure
  
  def initialize(path, manager)
    @path     = path
    @manager  = manager
    get_current_structure
  end
  
  # Differences between structures
  # old - new may result in the installation/deletion of a new service/domain
  def poll
    begin
      ContainerLogger.debug "New poll (#{Time.now}) #{$service[:full_name]}"
      @old_structure = @current_structure
      get_current_structure
    
      # check for missing entities in the old directory tree
      i = (@old_structure.keys - @current_structure.keys).to_a.each do |d|
        # domain got deleted !
        ContainerLogger.warn "Domain #{d} got deleted!"                
        $provider.remove_domain(d.to_sym)
      end
      @manager.message_stack << "Delete #{i} domains" if i.size > 0
    
    
      # Check for new entities in the current directory tree
      i = (@current_structure.keys - @old_structure.keys).to_a.each do |d|
         ContainerLogger.debug "found new Domain! #{d}"            
        # found new domain
        j=@current_structure[d].each do |s|
         ContainerLogger.debug "New service discovered! #{d}::#{s}"                 
          $provider.add_service(d.to_sym, s.to_sym)    
        end
        @manager.message_stack << "found #{j} service(s)" if j.size > 0        
      end
      @manager.message_stack << "found #{i} domain(s)" if i.size > 0

      # finally check for deleted services within the current domains
      @current_structure.each do |k, d|

        unless @old_structure[k].nil?
          i = (@current_structure[k] - @old_structure[k]).to_a.each do |s|
            ContainerLogger.debug "New service discovered! #{k}::#{s}"                  
            $provider.add_service(k.to_sym, s.to_sym)             
          end
          @manager.message_stack << "Installed #{i} new service(s)" if i.size > 0
      
          i = (@old_structure[k] - @current_structure[k]).to_a.each do |s|      
            ContainerLogger.warn "Service removed! #{k}::#{s}"            
            $provider.remove_service(k.to_sym, s.to_sym)             
          end
          @manager.message_stack << "Removed #{i} service(s)" if i.size > 0
        end
      end
    rescue => ex
      ContainerLogger.error ex, 0
      ContainerLogger.error ex, 1
      ContainerLogger.error ex, 2            
    end
  end
  
  private 
    # Scan first dimension, the domains or a mew archive file which should be a domain including services
    def get_current_structure
      @current_structure = {}
      begin
        Dir.new(@path).each do |domain|
          @manager.message_stack << ServiceUnPacker.new(@path, domain) if ServiceUnPacker.supported_file_type?(domain)
          domain_dir = "#{@path}/#{domain}/"
        
          next if domain =~ /^\.{1,2}/ || !File.directory?(domain_dir) 
          read_dir(domain)
        
        end
      rescue => e
        ContainerLogger.debug e, 1
      end
      @current_structure
    end

    # Scan seconds dimension, the services in a given domain, or a new archive file to be unarchived and installed
    def read_dir(domain)      
      Dir.new("#{@path}/#{domain}").each do |service|
        @manager.message_stack << ServiceUnPacker.new(@path, domain, service) if ServiceUnPacker.supported_file_type?(service)
        
        service_dir = "#{@path}/#{domain}/#{service}"
        next if service =~ /^\.{1,2}/ || !File.directory?(service_dir) 
          @current_structure[domain] ||= []
          @current_structure[domain] << service
      end
    end
end