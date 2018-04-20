#!/usr/bin/ruby

require 'socket'
require 'io/console'

class Client
	attr_accessor :hostname, :port

	def initialize(hostname, port)
		@hostname = hostname
		@port = port
		@active = nil 
		@server = TCPSocket.new(hostname, port)
		@envoie = nil
		@reponse = nil

		ecouter()
		envoyer()
		
		@envoie.join
		@reponse.join

	end

	def ecouter()
		@reponse = Thread.new do 
			loop {
				msg = @server.gets.chomp
				if msg == "ping"
					@server.puts("pong")
				
					trap("INT"){@server.puts("/quit")}
				
				else
				puts "#{msg}"
					if msg == "Attention ce pseudo existe deja" || msg == "Rentrez un pseudo correct" ||  msg == "Deconnexion"
						exit
					end
#					if msg == "Utilisateurs en ligne:"
#						@active = "ok"
#					end
				end
				trap("INT"){@server.puts("/quit")}
				
			}
		end
	end

	def envoyer()
		@envoie = Thread.new do
			loop {
					msg = $stdin.gets.chomp
					@server.puts(msg)
				
			}
		end
	end

	def test()
		while 1 
			line = @server.gets
			puts line.chomp
			str = $stdin.gets 
			@server.puts str
	
		end
		@server.close
	end
	 


end




hostname = ARGV[0]
port = ARGV[1].to_i


c = Client.new(hostname, port) 


