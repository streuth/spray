require 'net/telnet'

class RDebugController
  RDEBUG_NO_PRINT= File.join(Redcar.root, "plugins", "spray", "lib", "controllers", "rdebug_no_print.rb")
  RDEBUG_PROMPT= /PROMPT \(rdb:\d*\) |CONFIRM Really quit\? \(y\/n\)/
  @@current_port= 31415
  @@s= nil
  
  attr_reader :command
  
  def initialize(path, host='localhost', port=nil)
    @path, @host, @port = path, host, (port || @@current_port+=1)
    @command= "rdebug --debug -nx -p #{@port} -s -w -r '#{RDEBUG_NO_PRINT}' '#{@path}'"
  end
  
  def connect
    retries= 1 #1 seconds of timeout
    begin
      @@s= Net::Telnet::new("Host"=> @host, "Port"=> @port, "Prompt"=> RDEBUG_PROMPT,
      "Telnetmode"=> false, "Timeout"=> 2, "Waittime"=> 0)
    rescue
      sleep 0.2
      retry if 0 <= (retries-=0.2)
      raise("Timeout connecting to rdebug on #{@host}:#{@port}")
    end
    @@s.waitfor(/PROMPT \(rdb:\d*\)/)
  end
  
  def send_command(command)
    @@s.cmd(command) || ''
  end
  
  def current_position
    line, file = @@s.cmd("info line").scan(/Line\s(\d+).*"(.*)"/).flatten
    [line.to_i, File.expand_path(file, File.dirname(@path))]
  end
  
end
