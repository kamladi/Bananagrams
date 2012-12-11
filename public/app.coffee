Game = 
	init: () ->
		@hand = []
		@bagSize = 144
		@nickname = prompt "Welcome! Enter a nickname"
		while @nickname?
			prompt "Invalid nickname."
		@connect()

		#init canvases
		board = document.getElementById 'board'
		@boardctx = board.getContext '2d'

	connect: () ->
		#set up sockets
		socket = io.connect 'http://localhost'

		socket.on 'connect', () ->
			socket.emit 'set nickname', @nickname
		socket.on 'ready', () ->
			console.log "connected as #{@nickname}"
		socket.on 'new tile', @addNewTile
		socket.on 'bag size', @updateBagSize
		socket.on 'bananas', @gameOver

	startGame: (numStartingTiles = 7) ->
		socket.emit 'start game', numStartingTiles: numStartingTiles

	addNewTile: (data) ->
		console.log "Received new tile: #{data.tile}"
		@hand.push data.tile
		console.log "current hand: #{@hand}"
	
	updateHand: () ->
		HAND.drawHand @hand

	updateBagSize: (data) ->
		@bagSize = data.size
		console.log "Bag size: #{data.size}"
	
	gameOver: (data) ->
		winner = data.winner
		alert "BANANAS! #{winner} won!"
	

HAND = 
	init: () ->
		@canvas = document.getElementById 'hand'
		@ctx = @canvas.getContext '2d'
		@W = @canvas.width
		@H = @canvas.height
		setInterval(@drawHand, 60)
	
	drawHand: () ->
		@resetCanvas()
		hand = GAME.hand
		for i in [0...hand.length]
			@drawTile hand[i], i
	
	drawTile: (tile, index) ->
		width = @W / GAME.hand.length
		@ctx.strokeStyle = "black"
		@ctx.strokeRect(index * width, 0, width, @H)

	resetHandCanvas: () ->
		@ctx.fillStyle = "white"
		@ctx.fillRect(0, 0, @W, @H)	

BOARD = 
	init: () ->
		@canvas = document.getElementById 'board'
		@ctx = @canvas.getContext '2d'
		@W = @canvas.width
		@H = @canvas.height
		setInterval(@drawBoard, 60)

	drawBoard: () ->
		resetBoardCanvas()

	resetBoardCanvas: () ->
		@ctx.fillStyle = "white"
		@ctx.fillRect(0, 0, @W, @H)
		NUMCOLS = 10
		NUMROWS = 10
		for i in [0..NUMCOLS]
			@ctx.moveTo(i * (@W/NUMCOLS), 0)
			@ctx.lineTo(i * (@W/NUMCOLS), @H)
		for i in [0..NUMROWS]
			@ctx.moveTo(i * (@W/NUMROWS), 0)
			@ctx.lineTo(i * (@W/NUMROWS), @W)
		@ctx.strokeStyle = "black"
		@ctx.stroke()


Game.init()

