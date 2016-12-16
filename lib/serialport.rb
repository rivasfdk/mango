#Client that recieves incoming weight from serial port using TCP Socket

require 'socket'      # Sockets are in standard library

module Serialport

  class Connection
  
    def self.get_socket_data
      hostname = '192.168.0.105'
      port = 20000

    s = TCPSocket.new(hostname, port)

    while line = s.gets   # Read lines from the socket
      puts line.chomp      # And print with platform line terminator
    end
    s.close               # Close the socket when done
   
    end
  end
end