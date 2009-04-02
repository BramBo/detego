module Kernel
  def calling_method(lvl = 0)
    return caller[lvl]
  end
end

class ContainerLogger
  COLORS = {:debug => :console_def, :error => :console_dark_red, :warn => :console_dark_yellow}
  def self.method_missing(method_name, *args, &block)
    str = args[0].to_s
    lvl = args[1].to_i || 0
    str = eval("str.#{COLORS[method_name]}")
    log_file = File.new("log/debug.log", "a+")
    if method_name.to_s =~ /error|warn/i
      log_file.puts("(#{method_name}): ".console_bold+" #{str} in #{calling_method(lvl)}")
    else
      log_file.puts("(#{method_name}): ".console_bold+" #{str}")
    end
    log_file.close
  end
end
