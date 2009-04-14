#!/usr/bin/env ruby
ARGV << "-p"; ARGV << "5005"
$interface_version = "0.3.2"
require 'config/boot'

class ServiceManager
  def start()
    Thread.new do
      $provider.for($service[:domain].to_sym, $service[:name].to_sym).status= "Running.."
    end  
    
    require 'commands/server'
  end
end
