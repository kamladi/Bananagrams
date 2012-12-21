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
		@initMenuHandlers()

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

	initMenuHandlers: () ->
		menuBtns = $('#menu li')
		startGameBtn = menuBtns[0]
		peelBtn = menuBtns[1]
		dumpBtn = menuBtns[2]

		startGameBtn.onclick = @startGame
		peelBtn.onclick = @peel
		dumpBtn.onclick = @dump
	
	startGame: (e) =>
		tileNum = 7
		@socket.emit 'start game', numStartingTiles: tileNum

	addTileToHand: (data) =>
		console.log "Received new tile: #{data.tile}"
		@HAND.addTile data.tile
	
	peel: () =>
		if @HAND.$hand.find('.tile').length isnt 0
			return false
		@socket.emit 'peel'

	dump: (e) =>
		selectedTile = @HAND.getSelectedTile()
		@socket.emit 'dump', tile: selectedTile

	updateBagSize: (data) =>
		@bagSize = data.size
		console.log "Bag size: #{data.size}"
		$('#menu p span.bag-size').text @bagSize
	
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
		#hand now has at least one tile,
		#so remove 'empty hand' message if it exists
		if @$hand.find('p').length isnt 0
			@$hand.find('p').remove()
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
		@NUMCOLS = 10
		@NUMROWS = 10
		#empty symbol
		@EMPTY = "&oslash;"

		#build table
		htmlString = ""
		for i in [0...@NUMROWS]
			htmlString += @createNewRow()
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
                        # Careful... method addTileToHand takes object literal
                        # with the property "tile", NOT a string
			GAME.addTileToHand tile: tile
			cell.innerHTML = @EMPTY
			#prune empty edge rows/cols
			#NOTE: this will never actually be called, because
				#everytime we add a tile to an edge row/col,
				#we create an empty row/col. Therefore we will never
				#have an edge row/col with a tile in it.
			@unextendBoard row, col
		
		# if the cell is empty, move the selected tile in hand to board
		else
            selectedTile = @GAME.HAND.getSelectedTile()
            # highlights cell on board only if there is a selected
            # tile otherwise nothing
            if selectedTile
                    cell.classList.toggle 'tile'
                    cell.innerHTML = selectedTile
                    #if no more tiles in hand, tell user to peel
                    if GAME.HAND.$hand[0].childElementCount is 0
                    	GAME.HAND.$hand.html('<p>No more tiles! Click "Peel!" to get another one</p>')
            #if we added a tile in an edge row/col, 
            #prepend/append new row/col
            @extendBoard row, col

	addTile: (tile, x, y) ->
		row = @$board.find('tr')[y]
		col = row.getElementsByTagName('td')[x]
		col.innerText = tile

	#given a row, col index where a tile was added,
	#extend the board appropriately
	extendBoard: (row, col) ->
		if row is 0 or row is @NUMROWS - 1
        	newRowHTML = @createNewRow()
        	if row is 0
        		@$board.prepend newRowHTML
        	else
        		@$board.append newRowHTML
        	@NUMROWS += 1
		if col is 0 or col is @NUMCOLS - 1
			@$board.find('tr').each ->
				newCell = document.createElement 'td'
				newCell.innerHTML = "&Oslash;"
				if col is 0
					this.insertBefore newCell, this.firstChild
				else
					this.appendChild newCell
			@NUMCOLS += 1
	#given a row, col index where a tile was removed,
	#remove edge rows/columns appropriately
	unextendBoard: (row, col) ->
		if row is 0 and @rowEmpty(0)
			@$board.find('tr').eq(0).remove()
			@NUMROWS -= 1
		if row is @NUMROWS-1 and @rowEmpty(@NUMROWS-1)
			@$board.find('tr').eq(@NUMROWS-1).remove()
			@NUMROWS -= 1
		if col is 0 and @colEmpty(0)
			@$board.find('tr').each ->
				@removeChild @firstChild
			@NUMCOLS -= 1
		if col is @NUMCOLS-1 and @colEmpty(@NUMCOLS-1)
			@$board.find('tr').each ->
				@removeChild @lastChild
			@NUMCOLS -= 1

	# checks if a given row has no tiles
	rowEmpty: (rowIndex) ->
		row = @$board.find('tr')[rowIndex]
		cells = row.children
		for i in [0...@NUMCOLS]
			if cells[i].classList.contains 'tile'
				return false
		return true
	
	# checks if a given column has no tiles
	colEmpty: (colIndex) ->
		rows = @$board.find('tr')
		for i in [0...@NUMROWS]
			if rows[i].firstChild.classList.contains 'tile'
				return false
		return true

	createNewRow: ->
		newRow = "<tr>"
		for i in [0...@NUMCOLS]
			newRow += "<td>&Oslash;</td>"
		newRow += "</tr>"
		newRow


#let's kick everything off at page load
$(document).ready ->
	window.GAME = new Game(new Board(), new Hand())
