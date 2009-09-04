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

# Set application path and load paths
CONTAINER_PATH          = "#{Dir.getwd}"
SERVICES_PATH           = "#{CONTAINER_PATH}/contained"
LIBRARY_PATH            = "#{CONTAINER_PATH}/lib"
CONTAINER_LIBRARY_PATH  = "#{LIBRARY_PATH}/container"
SERVICE_LIBRARY_PATH    = "#{LIBRARY_PATH}/service"
DETEGO_VERSION          = "0.4.4"
LOGGING_LEVEL           = 0
ENV["DETEGO_ENV"]       = "development"

$: << "#{CONTAINER_PATH}/app" << LIBRARY_PATH << CONTAINER_LIBRARY_PATH << SERVICE_LIBRARY_PATH

# First startup
 require 'fileutils'
 FileUtils.mkdir_p("#{CONTAINER_PATH}/log", :mode => 0755)

# DRB Port management
 $port_start   = 49800

# Require the need helpers
 require "container_logger"
 require "observable_base" 
 require "application_helper"
