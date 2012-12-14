class Bag
	constructor: () ->
		@tiles = []
		#add all 144 tiles to set
		@addTiles 2, ["J", "K", "Q", "X", "Z"]
		@addTiles 3, ["B", "C", "F", "H", "M", "P", "V", "W", "Y"]
		@addTiles 4, ["G"]
		@addTiles 5, ["L"]
		@addTiles 6, ["D", "S", "U"]
		@addTiles 8, ["N"]
		@addTiles 9, ["T", "R"]
		@addTiles 11, ["O"]
		@addTiles 12, ["I"]
		@addTiles 13, ["A"]
		@addTiles 18, ["E"]
		
		#randomize array once created? for now, picking random index on demand
		###
		@tiles.sort ->
			0.5 - Math.random()
		###
		
	addTiles: (numDuplicates, letters) ->
		for letter in letters
			for i in [0...numDuplicates]
				@tiles.push letter

	pop: () ->
		#random number between 0 and number of tiles left
		if @isEmpty()
			return null
		randIndex = Math.floor(Math.random()*@tiles.length)
		tile = @tiles.splice randIndex, 1

		return tile

	dump: (tile) ->
		@tiles.push tile
		if @tiles.length >= 3
			returnTiles = (@pop() for i in [0...3])
		else
			returnTiles = (@pop() for i in [0...@tiles.length])
		return returnTiles

	size: () ->
		return @tiles.length
	
	isEmpty: () ->
		return @tiles.length is 0

module.exports = new Bag()
