Dir.chdir("../../")
require "config/config.rb"
require "container.rb"
ENV["DETEGO_ENV"] = "test"

Spec::Runner.configure { |c| }