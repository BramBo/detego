class ContainerLogger
  def self.method_missing(method_name, *args, &block)
    log_file = File.new("log/#{method_name}.log", "a+")
    log_file.puts(args[0])
    log_file.close
  end
end