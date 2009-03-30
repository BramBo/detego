class ContainerLogger
  COLORS = {:debug => :console_def, :error => :console_dark_red, :warn => :console_dark_yellow}
  def self.method_missing(method_name, *args, &block)
    str = args[0].to_s
    str = eval("str.#{COLORS[method_name]}")
    log_file = File.new("log/debug.log", "a+")
    log_file.puts("(#{method_name}): ".console_bold+" #{str}")
    log_file.close
  end
end
