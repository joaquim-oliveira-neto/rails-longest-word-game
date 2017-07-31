require 'json'
class WordsController < ApplicationController
  def game
    @grid = generate_grid(20)
    @start_time = Time.now

  end

  def score
    @start_time = Time.parse(params[:start_time])
    @end_time = Time.now
    @grid = JSON.parse(params[:grid])
    @attempt = params[:guess]
    @result = run_game(@attempt, @grid, @start_time, @end_time)

    session[:total_score] = (session[:total_score] || 0) + @result[:score]
    @total_score = session[:total_score]
  end

  def generate_grid(grid_size)
    # Generate random grid of letters
    alphabet = ("A".."Z").to_a
    grid = []
    (1..grid_size).each { grid << alphabet.sample }
    grid
  end

  def run_game(attempt, grid, start_time, end_time)
    # TODO: runs the game and return detailed hash of result
    result = {}
    result[:time] = end_time - start_time
    result[:translation] = translate(attempt)
    result[:score] = calculate_score(attempt, grid, result[:translation], result[:time])
    result[:message] = create_message(result[:score], attempt, grid, result[:translation])
    result
  end

  def grid_check(attempt, grid)
    letters_array = attempt.upcase.chars
    letters_array.all? { |letter| letters_array.count(letter) <= grid.count(letter) }
  end

  def translate(attempt)
    url = "https://api-platform.systran.net/translation/text/translate?source=en&target=fr&key=941f11f8-a960-470b-b576-564c641ab31f&input=#{attempt}"
    raw_translation = open(url).read
    translation = JSON.parse(raw_translation)
    translation["outputs"][0]["output"] == attempt ? nil : translation["outputs"][0]["output"]
  rescue
    words = File.read('/usr/share/dict/words').upcase.split("\n")
    words.include? attempt ? attempt : nil
  end

  def calculate_score(attempt, grid, translated_word, elapsed_time)
    return 0 unless grid_check(attempt, grid)
    return 0 if translated_word.nil?
    attempt.size * 10 / elapsed_time
  end

  def create_message(score, attempt, grid, translated_word)
    if score > 0
      "well done"
    elsif grid_check(attempt, grid) == false
      "not in the grid"
    elsif translated_word.nil?
      "not an english word"
    end
  end

end
