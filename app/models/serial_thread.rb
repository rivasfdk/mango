#Client that recieves incoming weight from serial port using TCP Socket

require 'socket'      # Sockets are in standard library

class SerialThread


  def self.get_weight_from_socket
	 hostname = '192.168.0.105'
	 port = 20000

	 s = TCPSocket.new(hostname, port)

   #while line = s.gets    # Read lines from the socket
   #  @data = line.chomp   # And print with platform line terminator
     #@data.split(" ").map{|s| s.to_f}.first  # Takes first value of array
     binding.pry          
   #end
   #s.close                # Close the socket when done

	 while line = s.gets   # Read lines from the socket
     puts line.chomp      # And print with platform line terminator
	 end
	 s.close               # Close the socket when done
   
  end
end

