express = require 'express'
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

app.use express.logger()
app.use express.static(__dirname + '/public')

app.listen(8080)
console.log "listening on port 8080"

#instantiate new Bag
Bag = require 'Bag'


PLAYERS = []
GAME_STARTED = true

#manage socket connections
io.sockets.on 'connection', (client) ->
	PLAYERS.push(client)

	#when client assigns themself a nickname
	client.on 'set nickname', (name) ->
		client.set 'nickname', name, client.emit('ready')

	#when someone triggers to start game,
	#deal given number of tiles to each connected player
	client.on 'start game', (data) ->
		numStartingTiles = data.numStartingTiles
		if not GAME_STARTED
			for player in PLAYERS
				for i in [0..numStartingTiles]
					player.emit 'new tile', tile: Bag.pop()

	#when someone 'peels', tell everyone else to peel
	client.on 'peel', (data) ->
		if Bag.isEmpty()
			io.sockets.emit "bananas", winner: client
		else
			io.sockets.emit 'new tile', tile: Bag.pop()
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

