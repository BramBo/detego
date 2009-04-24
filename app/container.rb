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

class Container
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
   def initiate_installed_services()
     # find exisiting domains and services
     puts "Initializig services"     
     Dir.new(@path).each do |domain|
       next if domain =~ /^\.{1,2}/ || !File.directory?("#{@path}/#{domain}/") 
       add_domain(domain.to_sym)
 
       Dir.new("#{@path}/#{domain}").each do |service|
         next if service =~ /^\.{1,2}/ || !File.directory?("#{@path}/#{domain}/#{service}") 
          find(domain.to_sym).add_service(service.to_sym)
          puts " v | #{service} done"
       end
     end
     
     puts " "
     # now start all the services
     puts "Starting services"
     find(:all).each do |k,d| 
       d.find(:all).each do |k,s|
         begin 
           s.start()
           puts " v | #{s.full_name} started"           
         rescue Exception => e
           puts " x | #{s.full_name} failed".console_red
          end 
       end
     end
     puts ""
     puts "Server Ready".console_bold
     puts ""
  end 
end