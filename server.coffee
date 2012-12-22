express = require 'express'
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

app.use express.logger()
app.use express.static(__dirname + '/public')

server.listen(8080)
console.log "listening on port 8080"

#instantiate new Bag
Bag = require './Bag'

#load dictionary
Dictionary = require('./Dictionary.coffee')


PLAYERS = []
GAME_STARTED = false
WINNER = null

#manage socket connections
io.sockets.on 'connection', (client) ->
	PLAYERS.push(client)
	console.log "New Player: #{client.id} connected"
	console.log "#{PLAYERS.length} players connected"

	#when client assigns themself a nickname
	client.on 'set nickname', (name) ->
		console.log "received request from #{client.id} to set nickname to #{name}"
		client.set 'nickname', name, ->
			client.get 'nickname', (err, clientName) ->
				console.log "Client #{client.id} assigned nickname #{clientName}"
				client.emit('ready', nickname: clientName)

	#when someone triggers to start game,
	#deal given number of tiles to each connected player
	client.on 'start game', (data) ->
		console.log "Starting game..."
		numStartingTiles = data.numStartingTiles
		if not GAME_STARTED
			for player in PLAYERS
				for i in [0..numStartingTiles]
					player.emit 'new tile', tile: Bag.pop()
				#send each player update on bag size
			io.sockets.emit 'bag size', size: Bag.size()
			console.log "current bag size: #{Bag.size()}"
			GAME_STARTED = true

	#when someone 'peels', tell everyone else to peel
	client.on 'peel', (data) ->
		if Bag.isEmpty()
			client.emit 'bag empty'
			return
		else
			for player in PLAYERS
				player.emit 'new tile', tile: Bag.pop()
		#send client update on bag size
		io.sockets.emit 'bag size', size: Bag.size()
		console.log "current bag size: #{Bag.size()}"

	#when someone wants to dump
	client.on 'dump', (data) ->
		newtiles = Bag.dump data.tile
		for tile in newtiles
			client.emit 'new tile', tile: tile
			console.log "sending [#{tile}] to #{client}"
		#send client update on bag size
		io.sockets.emit 'bag size', size: Bag.size()
		console.log "current bag size: #{Bag.size()}"

	#when someone wants to call bananas
	#if board is valid, end the game
	client.on 'validate', (data) ->
		if Dictionary.validate data.board
			WINNER = true
			client.get "nickname", (err, name) ->
				io.sockets.emit "bananas", winner: name
			return
		else
			client.emit 'board invalid'

	#when player disconnects
	client.on 'disconnect', () ->
		#remove player from PLAYERS
		console.log "Player #{client.id} disconnected"
		index = PLAYERS.indexOf client
		if index > -1
			PLAYERS.splice index, 1

#Handle main route
app.get '/', (req, res) ->
	res.sendfile(__dirname + '/index.html');

