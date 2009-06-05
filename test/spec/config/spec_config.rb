$: << "#{Dir.getwd}/test/spec" << "#{Dir.getwd}/test/spec/config" << "#{Dir.getwd}/app" << "#{Dir.getwd}/lib/container"
require "container"
ENV["DETEGO_ENV"] = "test"