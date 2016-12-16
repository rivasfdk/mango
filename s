
[1mFrom:[0m /home/daniela/mango/app/models/serial_thread.rb @ line 17 SerialThread.get_weight_from_socket:

     [1;34m8[0m:   [32mdef[0m [1;36mself[0m.[1;34mget_weight_from_socket[0m
     [1;34m9[0m: 	 hostname = [31m[1;31m'[0m[31m192.168.0.105[1;31m'[0m[31m[0m
    [1;34m10[0m: 	 port = [1;34m20000[0m
    [1;34m11[0m: 
    [1;34m12[0m: 	 s = [1;34;4mTCPSocket[0m.new(hostname, port)
    [1;34m13[0m: 
    [1;34m14[0m:    [1;34m#while line = s.gets    # Read lines from the socket[0m
    [1;34m15[0m:    [1;34m#  @data = line.chomp   # And print with platform line terminator[0m
    [1;34m16[0m:      [1;34m#@data.split(" ").map{|s| s.to_f}.first  # Takes first value of array[0m
 => [1;34m17[0m:      binding.pry          
    [1;34m18[0m:    [1;34m#end[0m
    [1;34m19[0m:    [1;34m#s.close                # Close the socket when done[0m
    [1;34m20[0m: 
    [1;34m21[0m: 	 [1;34m#while line = s.gets   # Read lines from the socket[0m
    [1;34m22[0m:    [1;34m#  puts line.chop      # And print with platform line terminator[0m
    [1;34m23[0m: 	 [1;34m#end[0m
    [1;34m24[0m: 	 [1;34m#s.close               # Close the socket when done[0m
    [1;34m25[0m: 
    [1;34m26[0m:   [32mend[0m

