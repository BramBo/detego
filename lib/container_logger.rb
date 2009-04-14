class String
    def console_red;          colorize(self, "\e[1m\e[31m");  end
    def console_dark_red;     colorize(self, "\e[31m");       end
    def console_green;        colorize(self, "\e[1m\e[32m");  end
    def console_dark_green;   colorize(self, "\e[32m");       end
    def console_yellow;       colorize(self, "\e[1m\e[33m");  end
    def console_dark_yellow;  colorize(self, "\e[33m");       end
    def console_blue;         colorize(self, "\e[1m\e[34m");  end
    def console_dark_blue;    colorize(self, "\e[34m");       end
    def console_purple;       colorize(self, "\e[1m\e[35m");  end

    def console_def;          colorize(self, "\e[1m");  end    
    def console_bold;          colorize(self, "\e[1m");  end
    def console_blink;        colorize(self, "\e[5m");  end
    
    def colorize(text, color_code)  "#{color_code}#{text}\e[0m" end
end

module Kernel
  def calling_method(lvl = 1)
    return caller[lvl]
  end
end

class ContainerLogger
  COLORS = {:debug => :console_def, :error => :console_dark_red, :warn => :console_dark_yellow}
  def self.method_missing(method_name, *args, &block)
    str = args[0].to_s
    lvl = args[1].to_i || 0
    str = eval("str.#{COLORS[method_name]}")
    log_file = File.new("#{CONTAINER_PATH}/log/debug.log", "a+")
    if method_name.to_s =~ /error|warn/i
      log_file.puts("(#{method_name}): ".console_bold+" #{str} in #{calling_method(lvl)}")
    else
      log_file.puts("(#{method_name}): ".console_bold+" #{str}")
    end
    log_file.close
  end
end