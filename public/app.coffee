###
	GAME class: manages client-side game logic and socket connections
###
class Game
	constructor: (@BOARD, @HAND) ->
		@bagSize = 144

		#save reference to game object in BOARD and HAND
		@BOARD.GAME = @
		@HAND.GAME = @

		#leggo
		@connect()
		alert "Game starting in 5 seconds..."
		window.setTimeout(@startGame, 5000)

	connect: () ->
		#socket init
		@socket = io.connect 'http://localhost:8080'
		
		#setup handlers for socket events
		@socket.on 'connect', () =>
			console.log "connected to localhost"
			name = prompt("Welcome! Enter a nickname")
			if name is ""
				console.log "no name entered"
				return false
			console.log "entered " + name
			@socket.emit 'set nickname', name
			@
		@socket.on 'ready', (data) =>
			console.log "connected as #{data.nickname}"
		@socket.on 'new tile', @addTileToHand
		@socket.on 'bag size', @updateBagSize
		@socket.on 'bananas', @gameOver

	startGame: (numStartingTiles = 7) =>
		@socket.emit 'start game', numStartingTiles: numStartingTiles
		@

	addTileToHand: (data) =>
		console.log "Received new tile: #{data.tile}"
		@HAND.addTile data.tile
	
	peel: () ->
		@socket.emit 'peel'

	dump: (tile) ->
		@socket.emit 'dump', tile: tile

	updateBagSize: (data) =>
		@bagSize = data.size
		console.log "Bag size: #{data.size}"
	
	gameOver: (data) ->
		winner = data.winner
		alert "BANANAS! #{winner} won!"
	
###
	HAND class: manages the player's 'hand' of tiles
###
class Hand
	constructor: () ->
		@$hand = $('#hand')
		@$hand.on('click', 'div', @selectTile)
	addTile: (tile) ->
		newTile = document.createElement 'div'
		newTile.className = "tile"
		newTile.innerText = tile
		@$hand.append newTile
	selectTile: (e) =>
		tileDiv = $(e.target)
		console.log "#{tileDiv.text()} selected"
		selectedTile = @$hand.find('.selected')
		if selectedTile and selectedTile is not tileDiv
			selectedTile.removeClass 'selected'
		tileDiv.toggleClass 'selected'
	getSelectedTile: () ->
		selectedTile = @$hand.find('.selected')
		if selectedTile
			tile = selectedTile.text()
			selectedTile.remove()
			return tile
		else
			console.log "no tile currently selected"
			return null


###
	BOARD class: manages board on screen
###
class Board
	constructor: () ->
		@$board = $('#board')
		NUMCOLS = 10
		NUMROWS = 10
		#empty symbol
		@EMPTY = "&oslash;"

		#build table
		htmlString = ""
		for i in [0...NUMCOLS]
			htmlString += "<tr>"
			for j in [0...NUMCOLS]
				htmlString += "<td>" + @EMPTY + "</td>"
			htmlString += "</tr>"
		@$board.html htmlString

		#event handlers
		@$board.on 'click', 'td', @handleClick

	handleClick: (e) =>
		console.log "table cell clicked:"
		cell = e.currentTarget
		col = cell.cellIndex
		row = cell.parentNode.rowIndex
		tile = cell.innerHTML
		console.log "(tile, row, col): (#{tile}, #{row}, #{col})"
		
		
		# if the cell has a letter, move letter back to hand
		if cell.classList.contains 'tile'
			cell.classList.toggle 'tile'
			GAME.addTileToHand tile
			cell.innerHTML = @EMPTY
		
		# if the cell is empty, move the selected tile in hand to board
		else
			cell.classList.toggle 'tile'
			selectedTile = @GAME.HAND.getSelectedTile()
			if selectedTile
				cell.innerHTML = selectedTile
			#if no more tiles in hand, peel
			console.log GAME.HAND.$hand[0]
			if GAME.HAND.$hand[0].childElementCount is 0
				console.log "PEELING"
				GAME.peel()
	
	addTile: (tile, x, y) ->
		row = @$board.find('tr')[y]
		col = row.getElementsByTagName('td')[x]
		col.innerText = tile

#let's kick everything off at page load
$(document).ready ->
	window.GAME = new Game(new Board(), new Hand())
