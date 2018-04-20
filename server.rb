#!/usr/bin/ruby
require 'socket'

class Server
	attr_accessor :port, :server

	def initialize(port)
		@port = port
		@server = TCPServer.new(port)
		@connections = Hash.new
		@rooms = Hash.new
		@clients = Hash.new
		@clients2 = Hash.new
		@connections[:clients] = @clients
		@pseudonymes = []
		@pongs = Hash.new
		@pongs[:clients2] = @clients2
		@threads = []
		@chaines = ["serveur","Connection reussi"]
		@moment = nil
		@limite = nil 
	end	
	
	def run()
		loop{
			mise_en_forme(@chaines[0])		
			@threads << Thread.start(@server.accept) do |client|
				nick_name = nouveau_client(client)
				puts "#{nick_name} #{client}"
				
				@connections[:clients][nick_name] = client
				puts "#{@connections[:clients]}"
				mise_en_forme(@chaines[1])
	
				@pseudonymes << nick_name
	            
				envoie_du_ping(nick_name, client)
				utilisateurs_en_ligne(client)
				listen_msg(nick_name, client)		
				@t.join	

			end
		}.join
	end

	#fonction qui va envoyer un ping au client
	def envoie_du_ping(username, client)
		@t = Thread.new do
			loop{
				ping(username, client)
			}
		end
	end

	#fonction qui retourn le pseudo choisis d'un client
	def nouveau_client(client)
		while 1
			client.puts "Bienvenue dans le chat v.1, enregistrez-vous avec la commande /pseudo"
			commande_verif = client.gets.chomp
				if commande_verif == "/pseudo"
					break
				end
		end
		
				
		
		client.puts "Entrez votre pseudo: "
		username = client.gets.chomp.to_sym
		pseudo_deja_pris(client, username)		
		username = pseudo_correcte(client, username)
		return username
	end

	#fonction qui test si un pseudo est déjà pris
	def pseudo_deja_pris(client, username)
		@connections[:clients].each do |autrenom, autresock|
			if username == autrenom
				client.puts "Attention ce pseudo existe deja"
				Thread.kill self	
			end
		end
	end
	
	#fonction qui test si le pseudo respecte la norme
	def pseudo_correcte(client, username)
		#username.to_s.each_byte do |c|
		#	if ((c != 45) && !(c > 48 && c < 57) && !(c > 65 && c < 90) && (c != 95) && !(c > 97 && c < 122))
		#		client.puts "Rentrez un pseudo correct"  
		#	end
		#end
		
		if (username.length) > 12 || (username.length) < 2
			client.puts "Rentrez un pseudo correct"
			username = client.gets
		end

		return username
	
	end
	
	#fonction qui affiche les utilisateurs en ligne
	def utilisateurs_en_ligne(client)
		client.puts "----------------------"
		client.puts "Utilisateurs en ligne:\n"
		@pseudonymes.each do |pseudo|
			client.puts "=>#{pseudo}\n"
		end
		client.puts "----------------------"
	end
	
	#fonction qui deconnecte un client après avoir executé la commande /quit
	def deconnexion_client(username, client)
		@pseudonymes.delete(username)
		client.puts "Deconnexion"
		@connections[:clients].each do |autrename, autresock|
			if username == autrename
				next
			else
				temps = Time.new
				autresock.puts "[#{temps.hour}.#{temps.min}.#{temps.sec}]-Déconnection de #{username}"
			
		#@connections[:rooms] = @rooms
		#@connections[:rooms] = @rooms
			end
		end
		username.to_sym	
		@connections[:clients].delete(username)
		Thread.kill self	
	end
	
	def time_out(username)
		@pseudonymes.delete(username)
		@connections[:clients].each do |autrename, autresock|
			if username == autrename
				next
			else
				temps = Time.new
				autresock.puts "[#{temps.hour}.#{temps.min}.#{temps.sec}]-Déconnection de #{username}"	
			end
		end
		username.to_sym	
		@connections[:clients].delete(username)
		Thread.kill @threads[1]
	end
		
	
	#fonction uniquement pour l'affichage coté serveur
	def mise_en_forme(str)
		$stdout.sync = true	
		(str.length+2).times do 
			print "-"
		end
		print "\n-#{str}-\n"
		(str.length+2).times do 
			print "-"
		end
		print "\n"
	end
	
	#on ping le client pour voir si il est toujours là
	def ping(username, client)
		future = Time.now + 10
		
		while 1
			now = Time.now
			if now.to_i == future.to_i
				client.puts "ping"
				break
			end
			
		end
	end
	
	def check_dernier_pong(username, client)
		
		@pongs[:clients2].each do |name, time|
			@moment = Time.now
			if time == nil
				puts "attention de #{name}"
				@limite = @moment + 30
				@pongs[:clients2][name.to_sym] = "nondef"
			end
			puts "{#@moment} et {#@limite} et time = #{time} de #{name}"
			if @moment.to_i == @limite.to_i && time == "nondef"
				time_out(name)
			end	
		end
	end
	
	#fonction où le serveur ecoute un message sur une socket et la distribue autres sockets
	def listen_msg(username, client)
		
		 @pongs[:clients2][username] = nil
		 #puts "#{@pongs[:clients2]}"
		 loop{
			msg = client.gets.chomp
			
			puts"message de la socket #{@connections[:clients][username]}"

			msg_priv = msg[0..2]

			if msg_priv == "msg"
				msg_priv = {}
				msg_priv = msg.split
				@connections[:clients].each do |autrename, autresock|
					if autrename == msg_priv[1].to_sym
						temps = Time.new
						autresock.puts "[#{temps.hour}.#{temps.min}.#{temps.sec}]-message privé de #{username.to_s}: #{msg}"
					end
				end
			
			elsif msg == "/list"
				utilisateurs_en_ligne(client)		
			elsif msg == "/quit"
				deconnexion_client(username, client)
			elsif msg == "pong"
				puts "#{msg} de #{username.to_s}"
				username.to_sym
				@pongs[:clients2][username] = Time.now
			else
				@connections[:clients].each do |autrenom, autresocket|
					if autrenom == username 
						next 	
					else	
						temps = Time.new
						autresocket.puts "[#{temps.hour}.#{temps.min}.#{temps.sec}]-#{username.to_s}: #{msg}"
					end
				end
			end
			check_dernier_pong(username, client)

		}
	end
	

	def test2(client)
		#client = server.accept

		while 1
			client.puts "Bienvenue dans le chat, enregistrer avec la commande /pseudo"	
			commande = client.gets.chomp
			if commande == "/pseudo"
				break
			end
		end
		
		client.puts "Entrez votre name= "
		name = client.gets.chomp
		client.puts "coucou" + name

		while 1
			line = client.gets
			puts name + ": " + line.chomp
			str = $stdin.gets 
			client.puts str
		end 

		client.close	
	end
end


port = ARGV[0].to_i


if ARGV[0].to_i == 0
    puts "inserez port"
	exit
end


serv = Server.new(port)

#serv.wait_clt()
serv.run()


