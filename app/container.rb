# Copyright (c) 2009 Bram Wijnands<bram@kabisa.nl>
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
require "domain"
require "observer"

class Container
  include Observable
  
  def initialize
    @domains    = Hash.new
    @path       = SERVICES_PATH

    # Don't initiate the services when testing
    initiate_installed_services() unless ENV["DETEGO_ENV"] =~ /test/i   
  end
  
  def find(domain_name)
    return @domains if domain_name == :all
    
    domain = @domains[domain_name]
    return domain unless domain.nil?
    
    ContainerLogger.warn "Unexisting domain called: #{domain_name}"
    nil
  end
  
  def add_domain(name)
    @domains[name] = @domains[name] || Domain.new(name, self)
    
    domains = @domains.sort{|a,b| "#{a[0]}"<=>"#{b[0]}"}
    @domains.clear
    domains.each do |k,v|
      @domains[k] = v
    end
      
    @domains[name]
  end
  
  def remove(name)
    if name == :all
      @domains.each do |n, domain|
        domain.remove
        @domains.delete(n)
      end
    else
      @domains[name].remove(:all)
      @domains.delete(name)
    end
    
    ContainerLogger.warn "Deleted domain #{name} (#{name.class})"
    true
  end
  
  def shutdown!
    puts "\nShutting down..."
    @domains.each do |n, domain|
      domain.find(:all).each do |s, service|
        begin
          service.shutdown()  
         rescue Exception => e;  next;
         rescue => e;            next;
        end
        puts " v | #{s} shutdown."
      end
    end
    exit
  end
  
  private
  # Initiate and start the services already present in the contained folder.
  # Scans the contained folder, tries to figure an order of startup and invokes start() on the set
  #
  # Note: The services are not tagged installed/not installed and so services placed while the server was running and need a installation won't Work!  
    def initiate_installed_services
     services = {}
     # find exisiting domains and services
     puts "Initializing services"     
     Dir.new(@path).each do |domain|
       next if domain =~ /^\.{1,2}/ || !File.directory?("#{@path}/#{domain}/") 
       add_domain(domain.to_sym)
 
       Dir.new("#{@path}/#{domain}").each do |service|
         next if service =~ /^\.{1,2}/ || !File.directory?("#{@path}/#{domain}/#{service}") 
         
          begin
            s  = find(domain.to_sym).add_service(service.to_sym)
            services["#{domain}::#{service}"] = s.meta_data.depends_on

            puts " v | #{domain}::#{service} done"
          rescue Exception => e
            puts " x | #{domain}::#{service} failed on init".console_red
            puts "   |e> #{e}".console_dark_red
            ContainerLogger.error $!, 2
           end
       end
     end
     
     services = dependency_sort(services)
     
     puts " "
     # now start all the services
     puts "Starting services"
     services[:sorted].each do |k, v|
         s = @domains[k.gsub(/(^.+?)\:\:.+?$/, "\\1").to_sym].find(k.gsub(/^.+?\:\:(.+?)$/, "\\1").to_sym)
         
         begin 
           s.start()
           puts " v | #{s.full_name} started"
         rescue Exception => e
           puts " x | #{s.full_name} failed".console_red
           puts "   |e> #{e}".console_dark_red
          end 
     end
     
     if services[:circular_reference].size > 0
       puts ("="*75).console_red
       puts ("|          ").console_red  + "Warning Depedency missing / circular_reference found !".console_red().console_blink() + " "*9 + "|".console_red()
       
       services[:circular_reference].each do|k,v|
         puts "#{("|").console_red()} #{k} #{" "*(70-k.size())} #{("|").console_red()}"
         value = v.join(" | ")
         puts "#{("|").console_red()} - #{value} #{" "*(68-(value.size()))} #{("|").console_red()}"
       end
       puts ("="*75).console_red
     end
     
     puts ""
     puts "Server Ready".console_bold
     puts ""
  end 

  def dependency_sort(inc)
    dep_hash                  = inc.dup
    sorted, max_cycles, i, j  = [], 10**3, 0, 0

    while sorted.size < inc.size && i < max_cycles
      dep_hash.each do |k,v|
        flag, j = true, (j+1)

        if v.size() > 0
          v.each do |e|      
            flag = false if !sorted.include?(e) || (dep_hash[e] && dep_hash[e].include?(k))
          end
        end

        if flag == true
          sorted << k 
          dep_hash.delete(k)
        end
      end
      i, j = (i+1), 0
    end
    {:sorted => sorted, :circular_reference => dep_hash}
  end
end