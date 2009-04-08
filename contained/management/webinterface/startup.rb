#!/usr/bin/env ruby
ARGV << "-p"; ARGV << "5005"
$interface_version = "0.2.1"
require 'config/boot'

class ServiceManager
  def start()
    Thread.new do
      $provider.for($service[:domain].to_sym, $service[:name].to_sym).set_status("Running..")
    end  
    
    require 'commands/server'
  end
end
