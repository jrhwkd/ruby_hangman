#hangman game
require 'json'

module BasicSerialization
  @@serializer = JSON

  def serialize
    obj = {}
    instance_variables.map do |var|
      obj[var] = instance_variable_get(var)
    end
    @@serializer.dump obj
  end

  def unserialize(string)
    obj = @@serializer.parse(string)
    obj.keys.each do |key|
      instance_variable_set(key, obj[key])
    end
  end
end

class Turn
  include BasicSerialization

  attr_reader :display_board, :guesses_remaining, :incorrect_guesses, :guess

  def initialize(secret_word, display_board, secret_board, guesses_remaining, incorrect_guesses, guess = "")
    @secret_word = secret_word
    @display_board = display_board
    @secret_board = secret_board
    @guesses_remaining = guesses_remaining
    @incorrect_guesses = incorrect_guesses  
    @guess = guess
  end

  def turn_display
    puts "#{@guesses_remaining} guesses remaining!\n"
    case @guesses_remaining
    when 6
      puts "--"
      puts " |"
      puts "\n"
    when 5
      puts "--"
      puts " |"
      puts " O"
      puts "\n"
    when 4
      puts "--"
      puts " |"
      puts " O"
      puts " |"
      puts "\n"
    when 3
      puts "--"
      puts " |"
      puts " O"
      puts "/|"
      puts "\n"
    when 2
      puts "--"
      puts " |"
      puts " O"
      puts "/|\\"
      puts "\n"
    when 1
      puts "--"
      puts " |"
      puts " O"
      puts "/|\\"
      puts "/"
      puts "\n"
    when 0
      puts "--"
      puts " |"
      puts " O"
      puts "/|\\"
      puts "/ \\"
      puts "\n"
    end

    puts "Secret word: #{@display_board.join(" ")}"
    puts "Incorrect guesses: #{@incorrect_guesses.join(" ")}"
    puts "\n"
  end

  def get_guess
    puts "What is your guess? Enter \"save\" if you want to save your game."
    @guess = gets.chomp.downcase
  end

  def check_guess(guess)
    if @guess == "save"
      get_guess
    elsif @secret_board.include?(guess)
      puts "Good guess!\n"
      @secret_board.each_with_index do |ch, i|
        @display_board[i] = @secret_board[i] if ch == guess
      end
    else
      puts "Sorry, that character isn't in the secret word!\n"
      @guesses_remaining -= 1
      @incorrect_guesses.push(guess)
    end
  end
end

class Game
  include BasicSerialization

  attr_reader :display_board, :guesses_remaining, :incorrect_guesses

  def initialize(guesses_remaining = 6, incorrect_guesses = Array.new, secret_word = "", secret_board = Array.new, display_board = Array.new)
    @guesses_remaining = guesses_remaining
    @incorrect_guesses = incorrect_guesses
    @secret_word = secret_word
    @secret_board = secret_board
    @display_board = display_board
  end

  private

  def create_secret_word(dictionary)
    #assume each line has one word, remove new line \n
    words = dictionary.map do |word|
      word.slice(0..word.length - 2)
    end
    while @secret_word == ""
      @secret_word = words[rand(100)]
      @secret_word = "" if @secret_word.length < 6 || @secret_word.length > 11
    end
  end

  def create_display_board(secret_word)
    for i in 0..secret_word.to_s.length - 1
      @display_board.push("_")
    end
  end

  def create_secret_board(secret_word)
    @secret_board = secret_word.split("")
  end

  def game_over?(guesses_remaining)
    true if guesses_remaining == 0
  end

  def winner?(secret_word, display_board)
    true if display_board.join == secret_word
  end

  def endgame
    if game_over?(@guesses_remaining)
      puts "--"
      puts " |"
      puts " O"
      puts "/|\\"
      puts "/ \\"
      puts "\n"
      puts "Game over, the secret word was #{@secret_word}!"
    end

    if winner?(@secret_word, @display_board)
      puts "Good guessing, you win! The secret word was #{@secret_word}."
    end
  end
  
  def save_game
    j = 1
    Dir.mkdir("saved_games") unless File.exists?("saved_games")
    while File.exists?("saved_games/hangman#{j}.txt")
      j +=1
    end
    saved_game = File.open("saved_games/hangman#{j}.txt", "w")
    saved_game.puts serialize
    puts "Game saved as hangman#{j}!"
  end

  def load_game
    puts "Would you like to load a saved game? Y or N?"
    input = gets.chomp.downcase
    if input == "y"
      puts "Which game?"
      input = gets.chomp.downcase
      saved_game = File.open("saved_games/#{input}.txt", "r")
      unserialize(saved_game.gets)
    else
      new_game
    end
  end

  def new_game
    dictionary = File.open('5desk.txt', 'r')
    create_secret_word(dictionary)
    create_display_board(@secret_word)
    create_secret_board(@secret_word)
  end

  public

  def play
    load_game

    puts "Let's play hangman!"
    
    while !game_over?(@guesses_remaining) && !winner?(@secret_word, @display_board)
      current_turn = Turn.new(@secret_word, @display_board, @secret_board, @guesses_remaining, @incorrect_guesses)
      current_turn.turn_display
      current_turn.get_guess
      save_game if current_turn.guess == "save"
      current_turn.check_guess(current_turn.guess)
      @guesses_remaining = current_turn.guesses_remaining
      @incorrect_guesses = current_turn.incorrect_guesses
      @display_board = current_turn.display_board
      endgame
    end
  end
end

Game.new.play