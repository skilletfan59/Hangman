#Contains all input funtions
module Input

	#asks player for their name and returns it
	def get_name
		print "What is your name? "
		name = gets.chomp.downcase.split(" ").each {|word| word.capitalize!}.join(" ")
		print %x{clear}
		name
	end

	#gets a valid one letter guess and returns it
	def get_guess
		guess = gets.chomp.downcase
		if guess == "save"
		else	
			if guess.length > 1
				puts "A valid guess must only be one letter"
				guess = nil
			elsif guess.scan(/\d/).empty? == false
				puts "You are not allowed to guess numbers!"
				guess = nil
			end
		end
		guess
	end

	#gets a valid answer to the new or load question
	def get_answer
		entry = nil
		until entry != nil
			print "\nWould you like to start a new game (new) or load a saved game (load)? "
			entry = case gets.chomp.downcase
				when "new", "n" then "new"
				when "load", "l" then "load"
				else nil
			end
			puts "That is not a valid option, new or load?" if entry.nil?
		end
		entry
	end

	#returns true or false based on yes or no answer
	def play_again?
		entry = nil
		until entry != nil
			print "\nWould you like to play again? "
			entry = case gets.chomp.downcase
				when "yes", "y" then true
				when "no", "n" then false
				else nil
			end
			puts "That is not a valid option, yes or no" if entry.nil?
		end
		entry
	end
end

#contains pertanant game functions
module Game_functions

	require "yaml"
	
	#creates a loop to run through multiple games until you don't want to play again
	def run(name)
		play = true
		until not play
			game = Hangman.new(name)
			function = game.play
			if function == "save"
				save(game)
				play = false
			else
				play = play_again?
			end
		end
		close
	end

	#First looks if there is a saved games folder and creates it if not, then asks for an "id" to save it by and checks if that "id" is available, then creates that file and saves the game object to it
	def save(game)
		Dir.mkdir("saved_games") unless Dir.exists? "saved_games"
		look = true
		while look == true
			print "\nPlease enter a unique identifier used to load your game again: "
			id = gets.chomp.downcase
			until id != "exit"
				print "\nYou won't be able to load it with exit. Try a different id: "
				id = gets.chomp.downcase
			end
			filename = "saved_games/saved_game_#{id}.txt"
			if File.file?(filename) == false
				File.open(filename, 'w') {|f| f.write(YAML.dump(game)) }
				print "Saving Game."
				sleep(1)
				print "."
				sleep(1)
				print "."
				sleep(1)
				puts "Game has succesfully saved!"
				puts
				look = false
			else
				puts "There is already a game saved with that id, try a different one!"
			end
		end
	end

	#First looks if there is a saved games folder and creates it if not, then asks for what you saved it by and checks if its a real file, if it is it opens it
	def load
		Dir.mkdir("saved_games") unless Dir.exists? "saved_games"
		look = true
		while look == true
			print "\n(If you don't want to load anymore or can't find your file type 'exit')\nWhat is the unique identifier you saved your game with? "
			id = gets.chomp.downcase
			if id == "exit"
				game = "exit"
				look = false
			else
				filename = "saved_games/saved_game_#{id}.txt"
				if File.file?(filename)
					game = YAML.load(File.read(filename))
					print %x{clear}
					print "Loading Game."
					sleep(1)
					print "."
					sleep(1)
					print "."
					sleep(1)
					look = false
					File.delete(filename)
				else
					puts "There is no saved game with that id, please try again..."
				end
			end
		end
		game
	end

	#exits the game and clears the screen
	def close
		puts "Thanks for playing!"
		sleep(2)
		print %x{clear}
	end
end

#contains the "game object"
class Hangman

	include Input
	attr_accessor :name
	private

	#creates the game object storing the name of the player, pulling a random word from the dictionary file between 5 and 12 letters, making a display equivilent to it, initializing a wrong guess bank and game board object and setting the wrong guesses to 0
	def initialize(name)
		dictionary = File.readlines "words.txt"
		word_bank = dictionary.select {|word| word.chomp!.length > 4 && word.length < 13}
		@lose = word_bank.sample.downcase
		@answer = @lose.split.join
		@display = @answer.gsub(/\w/, "_")
		@name = name
		@number_wrong = 0
		@wrong_guesses = []
		@gameboard = Drawing.new
	end

	#compares the answer and the progress of the player, returns true when they win
	def won?
		@lose == @display
	end

	public

	#plays through the process of the game
	def play
		#cycles through until 6 wrong guesses or a win
		while @number_wrong < 6
			guess = nil
			print %x{clear}
			#draws out the hangman display
			puts @gameboard.draw(@number_wrong)
			puts "Wrong guesses: " + @wrong_guesses.join(", ") if not @wrong_guesses.empty?
			puts "\n\n     #{@display}\n\n\n"
			#until a valid guess is entered keep asking, checks for duplicate answers too
			until guess != nil
				print "#{@name}, enter a letter to guess or 'save' to save your game:  "
				guess = get_guess
				if guess !=nil && (@display.include?(guess) || @wrong_guesses.include?(guess))
					guess = nil
					puts "You already guessed that letter!"
				end
			end
			break if guess == "save"
			#if the guess is in the answer it loops through in case there are multiple of the same letter in the answer
			if @answer.include?(guess)
				until @answer.include?(guess) == false
					position = @answer.index(guess)
					@display[position] = guess
					@answer.sub!(guess, "*")
				end
			#if the guess is wrong it adds it to the wrong guesses bank and adds 1 to the counter
			else
				@wrong_guesses << guess
				@number_wrong += 1
			end
			break if won?
		end
		#skips the end game stuff if player chose to save
		if guess == "save"
		#outputs for a win
		elsif won?
			print %x{clear}
			puts @gameboard.draw(@number_wrong)
			puts "Wrong guesses: " + @wrong_guesses.join(", ") if not @wrong_guesses.empty?
			puts "\n\n     #{@display}\n\n\n"
			puts "Congratulations #{@name}, You Win!!"
		#outputs for a loss
		else
			print %x{clear}
			puts @gameboard.draw(@number_wrong)
			puts "Wrong guesses: " + @wrong_guesses.join(", ") if not @wrong_guesses.empty?
			puts "\n\n     #{@display}\n\n\n"
			puts "Unfortunately you were unable to guess the word and killed the guy..."
			puts "The correct answer is #{@lose}."
		end
		guess
	end
end

#Stores everything required for the hangman image
class Drawing

	#Creates all needed image components used for the hangman design
	def initialize
		@a = "\u2503"
		@b = "\u2501"
		@c = "\u250F"
		@d = "\u2513"
		@e = "\u253B"
		@g = "\u2502"
		@h = "\u2524"
		@i = "\u2570"
		@j = "\u253C"
		@k = "\u256F"
		@l = "\u2534"
		@m = "\u256D"
		@n = "\u256E"
		@p = "\u03D9"
		@f = "\u2620"
	end

	#draws out the hangman image based on how many wrong guesses there were
	def draw(num)
		if num == 0
			drawing = " #{@c}#{@b}#{@b}#{@d}\n #{@a}\n #{@a}\n #{@a}\n#{@b}#{@e}#{@b}"
		elsif num == 1
			drawing = " #{@c}#{@b}#{@b}#{@d}\n #{@a}  #{@p}\n #{@a}\n #{@a}\n#{@b}#{@e}#{@b}"
		elsif num == 2
			drawing = " #{@c}#{@b}#{@b}#{@d}\n #{@a}  #{@p}\n #{@a}  #{@g}\n #{@a}\n#{@b}#{@e}#{@b}"
		elsif num == 3
			drawing = " #{@c}#{@b}#{@b}#{@d}\n #{@a}  #{@p}\n #{@a} #{@i}#{@h}\n #{@a}\n#{@b}#{@e}#{@b}"
		elsif num == 4
			drawing = " #{@c}#{@b}#{@b}#{@d}\n #{@a}  #{@p}\n #{@a} #{@i}#{@j}#{@k}\n #{@a}\n#{@b}#{@e}#{@b}"
		elsif num == 5
			drawing = " #{@c}#{@b}#{@b}#{@d}\n #{@a}  #{@p}\n #{@a} #{@i}#{@j}#{@k}\n #{@a} #{@m}#{@l}\n#{@b}#{@e}#{@b}"
		elsif num == 6
			drawing = " #{@c}#{@b}#{@b}#{@d}\n #{@a}  #{@f}\n #{@a} #{@m}#{@j}#{@n}\n #{@a} #{@m}#{@l}#{@n}\n#{@b}#{@e}#{@b}"
		end
		drawing
	end
end

#contains the flow of the application
class Run

	include Input
	include Game_functions

	#promts the new/load question and runs the game appropriately
	def initialize
		print %x{clear}
		puts "Welcome to Hangman, Created by Tom Lamers!"
		option = get_answer
		if option == "new"
			name = get_name
			run(name)
		elsif option == "load"
			game = load
			if game == "exit"
				print %x{clear}
				name = get_name
				run(name)
			else
				function = game.play
				if function == "save"
					save(game)
					close
				elsif play_again?
					name = game.name
					run(name)
				else
					close
				end
			end
		end
	end
end
Run.new

	


