fs = require 'fs'

class Dictionary
	constructor: () ->
		@dict = []
		#asynchronously loads dictionary file
		#returns an array of words
		fs.readFile './dictionaries/twl.txt', 'utf8', (err, data) ->
			if err
				console.log err
			else
				console.log "dictionary loaded"
			@dict = data.split "\n"
			if @dict.length is 0
				console.log "ERROR BUILDING DICTIONARY"
	
	#Given a 2d array representing a board, check if every word is valid
		#collapses board into 1d arrays of words,
		#then does a linear lookup of each word
	validate: (board) ->
		#annotation for lines 26, 32:
			#join("").split(" ") collapses an array of letters into a string,
			#then splits the string into separate words delimited by whitespace
		valid = true
		#validate horizontal words
		#get list of horiz. words of length > 1 in each row
		rows = []
		rows.push word for word in row.join("").split(" ") when word.length > 1 for row in board

		#validate vertical words
		#get list of vert. words of length > 1 in each col
		cols = []
		for i in [0...board[0].length]
			col = (board[j][i] for j in [0...board.length]).join("").split(" ")
			cols.push word for word in col when word.length > 1

		console.log rows
		console.log cols

		#check that every word in rows and columns is valid
		rowWordsValid = rows.every @isValidWord, @
		colWordsValid = cols.every @isValidWord, @
		rowWordsValid and colWordsValid
	
	#Given a word, look it up in the dictionary array
	#BINARY SEARCH YO!
	isValidWord: (word) ->
		low = 0
		high = @dict.length
		while low < high
			mid = Math.floor (low + high) / 2
			if @dict[mid] is word
				return true
			else if word < @dict[mid]
				high = mid - 1
			else #if @dict[mid] < word
				low = mid + 1
		false


module.exports = new Dictionary()