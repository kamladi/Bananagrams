class Events
	constructor: () ->
		@events = {}
	bind: (evt, callback) ->
		@events[evt] = @events[event] or {}
		@events[event].push callback
	unbind: (event, callback) ->
		if event in @events
			if callback in @events[event]
				index = @events[event].indexOf(callback)
				@events[event].splice index, 1
	trigger: (event, args...) ->
		if event in @events
			for callback in @events[event]
				callback.apply @, args

###
	GAME class: manages client-side game logic and socket connections
###
class Game extends Events
	constructor: (@BOARD, @HAND) ->
		@bagSize = 144
		@connect()

		#event handlers
		@BOARD.on 'addTileToBoard', @addTileToBoard

	connect: () ->
		#socket init
		@socket = io.connect 'http://localhost'
		
		#setup handlers for socket events
		@socket.on 'connect', () ->
			@socket.emit 'set nickname', prompt("Welcome! Enter a nickname")
		@socket.on 'ready', (data) ->
			console.log "connected as #{data.nickname}"
		@socket.on 'new tile', @addNewTile
		@socket.on 'bag size', @updateBagSize
		@socket.on 'bananas', @gameOver

	startGame: (numStartingTiles = 7) ->
		@socket.emit 'start game', numStartingTiles: numStartingTiles

	addNewTile: (data) ->
		console.log "Received new tile: #{data.tile}"
		@HAND.addTile tile
		console.log "current hand: #{@hand}"

	addTileToBoard: (data) ->
		##get tile from hand and add to board
		tile = @HAND.getSelectedTile()
	
	updateBagSize: (data) ->
		@bagSize = data.size
		console.log "Bag size: #{data.size}"
	
	gameOver: (data) ->
		winner = data.winner
		alert "BANANAS! #{winner} won!"
	
###
	HAND class: manages the player's 'hand' of tiles
###
class Hand extends Events
	constructor: () ->
		@$hand = $('hand')
		@$hand.on('click', 'div', @selectTile)
	addTile: (tile) ->
		newTile = document.createElement 'div'
		newTile.className = "tile"
		newTile.innerText = tile
		@hand.appendChild newTile
	selectTile: (e) ->
		tileDiv = e.target
		tileDiv.addClass 'selected'
	getSelectedTile: () ->
		selectedTile = $.hand.find('div.selected')
		if selectedTile
			tile = selectedTile.text()
			selectedTile.remove()
			return tile


###
	BOARD class: manages board on screen
###
class Board extends Events
	constructor: () ->
		@$board = $('#board')
		NUMCOLS = 10
		NUMROWS = 10

		#build table
		htmlString = ""
		for i in [0...NUMCOLS]
			htmlString += "<tr>"
			for j in [0...NUMCOLS]
				html += "<td></td>"
			htmlString += "</tr>"
		@$board.html htmlString

		#event handlers
		@on 'addToBoard', @insertTile
		@on 'removeFromBoard', @removeTile
	
	insertTile: (tile, x, y) ->
		row = @board.find('tr')[y]
		col = row.getElementsByTagName('td')[x]
		col.innerText = tile

	removeTile: (x, y) ->
		row = @$board.find('tr')[y]
		col = row.getElementsByTagName('td')[x]
		tile = col.innerText
		col.innerText = ""

#let's kick everything off at page load
window.onload = ->
	window.GAME = new Game(new Board(), new Hand())
