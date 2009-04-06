#!/usr/bin/env ruby
ARGV << "-p"; ARGV << "5005"
require 'config/boot'

class ServiceManager
  def start()
    require 'commands/server'
  end
end
