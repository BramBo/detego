##########################################################################################
# Copyright (c) 2009 Bram Wijnands
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
##########################################################################################

##################################
##        Should be server      ##
##################################

  require "config/config.rb"
  require "container"
  require "service_provider"
  require 'drb'

  container     = Container.new

  #
  # Server Start...
  #
  container.add_domain(:root).add_service(:service_a).start()
  container.add_domain(:altern).add_service(:service_b).start()
  container.add_domain(:management).add_service(:webinterface).start()

  ###################################
  ##     Should be invoked by      ##
  ##  client / installed services  ##
  ##     Through Server facade     ##
  ###################################
  container.find(:altern).find(:service_b).invoke(:approach_root_test_service)

loop do
  # @todo: better exit signal
  exit if gets
end