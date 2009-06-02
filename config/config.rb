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
CONTAINER_PATH    = "#{Dir.getwd}"
$: << "#{CONTAINER_PATH}/app"
$: << "#{CONTAINER_PATH}/lib"
SERVICES_PATH     = "#{CONTAINER_PATH}/contained"
DETEGO_VERSION    = "0.4"
LOGGING_LEVEL     = 0
ENV["DETEGO_ENV"] = "development"

# First startup
 require 'fileutils'
 FileUtils.mkdir_p("#{CONTAINER_PATH}/lib", :mode => 0755)

# DRB Port management
 $port_start   = 49800

# Require the need helpers
 require "container_logger"
 require "application_helper"
