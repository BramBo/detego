#!/usr/bin/env ruby
ARGV << "-p"; ARGV << "5005"
require 'config/boot'

class ServiceManager
  exposed_methods :start
  def start()
    require 'commands/server'
  end
end
