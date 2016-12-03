namespace :manage_socket_messages do
  desc "manage data (weight from weight indicator) recieved over TCP socket"
  task manage_message: :environment do
  	require 'socket'      # Sockets are in standard library
	  host = '192.168.0.100'
    port = 20000

		@server = TCPSocket.new(@host, port)

    loop do 
      Thread.start(@server.accept) do |tcpSocket|
        port, ip = Socket.unpack_sockaddr_in(tcpSocket.getpeername)
        begin
          loop do
            line = tcpSocket.recv(100).strip
            handle_message line
          end
          rescue SystemCallError
          #close the socket's logic
        end
      end
    end
  end
end

def handle_message
 		while line = s.gets   # Read lines from the socket
 		  puts line.chop      # And print with platform line terminator
 		end
end
