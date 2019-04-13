require 'bson'
require 'json'
require 'matrix'
require 'net/http'
require 'observer'

# Main model that holds the data, state, and business logic of the app
class AppModel
  include(Observable)

  attr_reader(:app, :state)

  # Interface type
  GUI = 0
  CLI = 1

  # Player turns
  PLAYER_1_TURN = 1
  PLAYER_2_TURN = 2

  # Game types
  CONNECT_4 = 0
  TOOT_AND_OTTO = 1

  # Game modes
  PLAYER_PLAYER_LOCAL = 0
  PLAYER_PLAYER_DISTRIBUTED = 1
  PLAYER_CPU = 2
  CPU_PLAYER = 3
  CPU_CPU = 4

  # Game phases
  MENU = 0
  IN_PROGRESS = 1
  GAME_OVER = 2

  # Game result
  NO_RESULT_YET = 0
  PLAYER_1_WINS = 1
  PLAYER_2_WINS = 2
  TIE = 3

  # Token
  TOKEN_T = 1
  TOKEN_O = 2

  def initialize(app, presenter, interface = GUI)
    @server_address = 'https://interconnect4-server.herokuapp.com/'

    # Initial game state
    @state = {
      _id: nil,
      interface: interface,
      turn: PLAYER_1_TURN,
      player_turn: true,
      type: CONNECT_4,
      mode: PLAYER_PLAYER_LOCAL,
      phase: MENU,
      board_data: Array.new(6) { Array.new(7, 0) },
      result: NO_RESULT_YET,
      username_1: nil,
      username_2: nil,
      player_1_t: 6,
      player_1_o: 6,
      player_2_t: 6,
      player_2_o: 6,
      board_columns: 7,
      board_rows: 6,
      active_token: TOKEN_T,
      error_message: ''
    }

    @my_turn = nil

    add_observer(presenter)
    changed
    notify_observers('attach_model', self)

    if interface == GUI
      @app = app
      @app.signal_connect('activate') do |application|
        window = Gtk::ApplicationWindow.new(application)
        window.set_title('Ruby Connect Games')
        window.set_size_request(600, 600)
        window.set_border_width(20)

        changed
        notify_observers('init_views', window, @state)
        changed
        notify_observers('game_phase_updated', @state) # Start the game at the main menu
      end
    elsif interface == CLI
      changed
      notify_observers('init_views', nil, @state)
      changed
      notify_observers('game_phase_updated', @state) # Start the game at the main menu
    end
  end

  def update_turn(turn)
    if @state[:mode] == PLAYER_PLAYER_LOCAL || @state[:mode] == PLAYER_PLAYER_DISTRIBUTED
      response = Net::HTTP.get_response(URI(@server_address + "game?_id=#{@state[:_id]}"))
      new_state = eval(response.body)
      @state = Hash[new_state.map{ |k, v| [k.to_sym, v] }]
    else
      @state[:turn] = turn

      if @state[:turn] == PLAYER_1_TURN && @state[:mode] == PLAYER_CPU
        @state[:player_turn] = true
      elsif @state[:turn] == PLAYER_2_TURN && @state[:mode] == PLAYER_CPU
        @state[:player_turn] = false
      end

      if @state[:turn] == PLAYER_1_TURN && @state[:mode] == CPU_PLAYER
        @state[:player_turn] = false
      elsif @state[:turn] == PLAYER_2_TURN && @state[:mode] == CPU_PLAYER
        @state[:player_turn] = true
      end
    end

    changed
    notify_observers('turn_updated', @state, @my_turn)
  end

  def update_game_type(type)
    @state[:type] = type
    @state[:error_message] = ''
    if @state[:type] == CONNECT_4
      @state[:board_columns] = 7
      @state[:board_rows] = 6
      @state[:board_data] =  Array.new(6) { Array.new(7, 0) }
    elsif @state[:type] == TOOT_AND_OTTO
      @state[:board_columns] = 6
      @state[:board_rows] = 4
      @state[:board_data] =  Array.new(4) { Array.new(6, 0) }
    end
    changed
    notify_observers('game_type_updated', @state)
  end

  def update_game_mode(mode)
    @state[:mode] = mode
    @state[:player_turn] = (mode != CPU_PLAYER && mode != CPU_CPU)
    @state[:error_message] = ''

    changed
    notify_observers('game_mode_updated', @state)
  end

  def update_active_token(token)
    @state[:active_token] = token
    update_turn(@state[:turn])
  end

  def start_game
    update_game_phase(IN_PROGRESS)
  end

  # A league game is a game that is recorded in the league table
  def start_league_game(username_1, username_2, game_code)
    @state[:_id] = game_code
    @state[:username_1] = username_1
    @state[:username_2] = username_2

    uri = URI(@server_address + 'create_game')
    response = Net::HTTP.post(uri, @state.to_json, 'Content-Type' => 'application/json')

    if response.body == 'Success'
      update_game_phase(IN_PROGRESS)
    else # Load game
      query_string = "load_game?_id=#{@state[:_id]}&username=#{@state[:username_1]}"
      response = Net::HTTP.get_response(URI(@server_address + query_string))
      if response.body.start_with?('Failure')
        @state[:error_message] = response.body
        changed
        notify_observers('error', @state)
      else
        new_state = eval(response.body)
        @state = Hash[new_state.map{ |k, v| [k.to_sym, v] }]
        update_game_phase(IN_PROGRESS)
      end
    end
  end

  def host_game(username, game_code)
    @state[:username_1] = username
    @state[:_id] = game_code
    @my_turn = PLAYER_1_TURN

    uri = URI(@server_address + 'create_game')
    response = Net::HTTP.post(uri, @state.to_json, 'Content-Type' => 'application/json')

    if response.body == 'Success'
      update_game_phase(IN_PROGRESS)
    else
      query_string = "load_game?_id=#{game_code}&username=#{username}"
      response = Net::HTTP.get_response(URI(@server_address + query_string))
      if response.body.start_with?('Failure')
        @state[:error_message] = response.body
        changed
        notify_observers('error', @state)
      else
        new_state = eval(response.body)
        @state = Hash[new_state.map{ |k, v| [k.to_sym, v] }]
        update_game_phase(IN_PROGRESS)
      end
    end
  end

  def join_game(username, game_code)
    @my_turn = PLAYER_2_TURN
    uri = URI(@server_address + "join_game?game_id=#{game_code}&username=#{username}")
    response = Net::HTTP.post(uri, @state.to_json, 'Content-Type' => 'application/json')

    if response.body.start_with?('Failure')
      @state[:error_message] = response.body
      changed
      notify_observers('error', @state)
    else
      new_state = eval(response.body)
      @state = Hash[new_state.map{ |k, v| [k.to_sym, v] }]
      update_game_phase(IN_PROGRESS)
    end
  end

  def view_leaderboard
    response = Net::HTTP.get_response(URI(@server_address + 'leaderboard'))
    changed
    notify_observers('view_leaderboard', JSON.parse(response.body))
  end

  def back_to_main_menu
    @state[:turn] = PLAYER_1_TURN
    @state[:board_data] = Array.new(@state[:board_rows]) { Array.new(@state[:board_columns], 0) }
    @state[:result] = NO_RESULT_YET
    update_game_phase(MENU)
  end

  def update_game_phase(phase)
    @state[:phase] = phase
    @state[:error_message] = ''
    changed
    notify_observers('game_phase_updated', @state)
    if @state[:phase] == IN_PROGRESS || @state[:phase] == GAME_OVER
      update_turn(@state[:turn])
    end
  end

  def place_token(column_index)
    return if @state[:phase] == GAME_OVER

    if @state[:mode] == PLAYER_PLAYER_DISTRIBUTED && @state[:turn] != @my_turn
      update_turn(@state[:turn])
      return
    end

    token_played = board_place_token(column_index)

    result = game_result

    if result != NO_RESULT_YET
      @state[:result] = result
      @state[:phase] = GAME_OVER

      if @state[:mode] == PLAYER_PLAYER_LOCAL || @state[:mode] == PLAYER_PLAYER_DISTRIBUTED
        Net::HTTP.post(URI(@server_address + 'turn'), @state.to_json, 'Content-Type' => 'application/json')

        Thread.new do
          sleep(10)
          if @state[:result] == TIE
            uri = URI(@server_address + "game_over/tie?user1=#{@state[:username_1]}&user2=#{@state[:username_2]}")
            Net::HTTP.post(uri, @state.to_json, 'Content-Type' => 'application/json')
          elsif @state[:result] == PLAYER_1_WINS
            uri = URI(@server_address + "game_over/win?winner=#{@state[:username_1]}&loser=#{@state[:username_2]}")
            Net::HTTP.post(uri, @state.to_json, 'Content-Type' => 'application/json')
          elsif @state[:result] == PLAYER_2_WINS
            uri = URI(@server_address + "game_over/win?winner=#{@state[:username_2]}&loser=#{@state[:username_1]}")
            Net::HTTP.post(uri, @state.to_json, 'Content-Type' => 'application/json')
          end
        end
      end

      update_game_phase(GAME_OVER)
    elsif @state[:turn] == PLAYER_1_TURN && token_played
      if @state[:mode] == PLAYER_PLAYER_LOCAL || @state[:mode] == PLAYER_PLAYER_DISTRIBUTED
        @state[:turn] = PLAYER_2_TURN
        Net::HTTP.post(URI(@server_address + 'turn'), @state.to_json, 'Content-Type' => 'application/json')
      end

      update_turn(PLAYER_2_TURN)
    elsif @state[:turn] == PLAYER_2_TURN && token_played
      if @state[:mode] == PLAYER_PLAYER_LOCAL || @state[:mode] == PLAYER_PLAYER_DISTRIBUTED
        @state[:turn] = PLAYER_1_TURN
        Net::HTTP.post(URI(@server_address + 'turn'), @state.to_json, 'Content-Type' => 'application/json')
      end

      update_turn(PLAYER_1_TURN)
    elsif !token_played
      update_turn(@state[:turn]) # Column was full, try again
    end
  end

  def board_place_token(column_index)
    Matrix[*@state[:board_data]].column(column_index).to_a.reverse.each_with_index do |element, reverse_index|
      next unless element.zero?

      row_index = (@state[:board_data].length - 1) - reverse_index
      if @state[:type] == CONNECT_4
        @state[:board_data][row_index][column_index] = @state[:turn]
      elsif @state[:type] == TOOT_AND_OTTO
        if @state[:turn] == PLAYER_1_TURN && @state[:active_token] == TOKEN_T
          return false unless @state[:player_1_t] > 0
          @state[:player_1_t] -= 1
        elsif @state[:turn] == PLAYER_1_TURN && @state[:active_token] == TOKEN_O
          return false unless @state[:player_1_o] > 0
          @state[:player_1_o] -= 1
        elsif @state[:turn] == PLAYER_2_TURN && @state[:active_token] == TOKEN_T
          return false unless @state[:player_2_t] > 0
          @state[:player_2_t] -= 1
        elsif @state[:turn] == PLAYER_2_TURN && @state[:active_token] == TOKEN_O
          return false unless @state[:player_2_o] > 0
          @state[:player_2_o] -= 1
        end
        @state[:board_data][row_index][column_index] = @state[:active_token]
      end
      return true
    end
    false
  end

  def board_remove_token(column_index)
    Matrix[*@state[:board_data]].column(column_index).to_a.reverse.each_with_index do |element, reverse_index|
      next unless element.zero?

      row_index = @state[:board_data].length - reverse_index
      @state[:board_data][row_index][column_index] = 0
      return true
    end
    @state[:board_data][0][column_index] = 0
  end

  # CPU plays a turn
  def cpu_turn
    if @state[:type] == CONNECT_4
      cpu_progress unless cpu_attempt || cpu_prevent
    elsif @state[:type] == TOOT_AND_OTTO
      cpu_random
    end
  end

  # cpu_attempt works to try to win the game by placing a token in each column once and checking to see if any result in
  # a win condition. it clears all unsuccessful token attempts
  def cpu_attempt
    (0..(@state[:board_columns] - 1)).each do |c|
      token_placed = board_place_token(c)
      if game_result != NO_RESULT_YET # full send
        board_remove_token(c)
        place_token(c)
        return true
      elsif token_placed # make sure token was placed before force delete
        board_remove_token(c)
      end
    end
    false
  end

  # cpu_prevent works to try and stop the other player from winning the game by placing a token in each column once as
  # the other player and checking to see if any result in a win condition, if so then it places a token there as the cpu
  # to prevent the win. it clears all unsuccessful token attempts
  def cpu_prevent
    current_turn = @state[:turn]
    @state[:turn] = current_turn == PLAYER_1_TURN ? PLAYER_2_TURN : PLAYER_1_TURN # pretend to be other player
    (0..(@state[:board_columns] - 1)).each do |c|
      token_placed = board_place_token(c)
      if game_result != NO_RESULT_YET
        board_remove_token(c) # remove the winning move
        @state[:turn] = current_turn # change back
        place_token(c) # place token to block
        return true
      elsif token_placed # make sure token was placed before force delete
        board_remove_token(c)
      end
    end
    @state[:turn] = current_turn # remember to switch back
    false
  end

  # cpu_progress works to progress the cpu to victory. it iterates all possible moves going left to right until it finds
  # one that results in a win, it then erases all previous moves and places this move.
  def cpu_progress
    remove_array = []
    (0..3).each do |_|
      (0..(@state[:board_columns] - 1)).each do |c|
        token_placed = board_place_token(c)
        remove_array.push(c) if token_placed # add move for later deletion
        if game_result != NO_RESULT_YET
          remove_array.reverse_each do |r| # remove moves from our array 'stack'
            board_remove_token(r)
          end
          place_token(c)
          return true
        end
      end
    end
  end

  # Play a random move
  def cpu_random
    if @state[:type] == TOOT_AND_OTTO
      @state[:active_token] = rand(0..1).zero? ? TOKEN_T : TOKEN_O
    end
    place_token(rand(0..(@state[:board_columns] - 1)))
  end

  def game_result
    if @state[:type] == CONNECT_4
      connect_4_game_result
    elsif @state[:type] == TOOT_AND_OTTO
      toot_and_otto_game_result
    end
  end

  def connect_4_game_result
    return @state[:turn] if connect_4_horizontal? || connect_4_vertical? || connect_4_diagonal?

    return TIE if board_full?

    NO_RESULT_YET
  end

  def toot_and_otto_game_result
    return TIE if board_full?

    horizontal_result = toot_and_otto_horizontal
    return horizontal_result if horizontal_result == TIE

    vertical_result = toot_and_otto_vertical
    return vertical_result if vertical_result == TIE

    left_diagonal_result = toot_and_otto_left_diagonal
    return left_diagonal_result if left_diagonal_result == TIE

    right_diagonal_result = toot_and_otto_right_diagonal
    return right_diagonal_result if right_diagonal_result == TIE

    all_results = [horizontal_result, vertical_result, left_diagonal_result, right_diagonal_result]

    player_1_wins = all_results.count(PLAYER_1_WINS)
    player_2_wins = all_results.count(PLAYER_2_WINS)

    if player_1_wins > 0 && player_2_wins > 0
      TIE
    elsif player_1_wins > 0
      PLAYER_1_WINS
    elsif player_2_wins > 0
      PLAYER_2_WINS
    else
      NO_RESULT_YET
    end
  end

  def board_full?
    @state[:board_data].each do |row|
      return false if row.include?(0)
    end
    true
  end

  def connect_4_horizontal?
    @state[:board_data].each do |row|
      row_string = row.map { |elem| elem.to_s }.join
      return true if row_string.include?("#{@state[:turn]}" * 4)
    end
    false
  end

  def connect_4_vertical?
    Matrix[*@state[:board_data]].column_vectors.each do |column|
      column_string = column.to_a.map { |elem| elem.to_s }.join
      return true if column_string.include?("#{@state[:turn]}" * 4)
    end
    false
  end

  def connect_4_diagonal?
    connect_4_left_diagonal? || connect_4_right_diagonal?
  end

  def connect_4_left_diagonal?
    start_indices = [[2, 0], [1, 0], [0, 0], [0, 1], [0, 2], [0, 3]]
    start_indices.each do |index|
      left_diagonal = []
      i = index[0]
      j = index[1]

      until i == 6 || j == 7
        left_diagonal.push(@state[:board_data][i][j])
        i += 1
        j += 1
      end

      left_diagonal_string = left_diagonal.map { |elem| elem.to_s }.join
      return true if left_diagonal_string.include?("#{@state[:turn]}" * 4)
    end
    false
  end

  def connect_4_right_diagonal?
    start_indices = [[0, 3], [0, 4], [0, 5], [0, 6], [1, 6], [2, 6]]
    start_indices.each do |index|
      right_diagonal = []
      i = index[0]
      j = index[1]

      until i == 6 || j == -1
        right_diagonal.push(@state[:board_data][i][j])
        i += 1
        j -= 1
      end

      right_diagonal_string = right_diagonal.map { |elem| elem.to_s }.join
      return true if right_diagonal_string.include?("#{@state[:turn]}" * 4)
    end
    false
  end

  def toot_and_otto_horizontal
    @state[:board_data].each do |row|
      row_string = row.map { |elem| elem.to_s }.join
      return TIE if row_string.include?('1221') && row_string.include?('2112')
      return PLAYER_1_WINS if row_string.include?('1221')
      return PLAYER_2_WINS if row_string.include?('2112')
    end
    NO_RESULT_YET
  end

  def toot_and_otto_vertical
    Matrix[*@state[:board_data]].column_vectors.each do |column|
      column_string = column.to_a.map { |elem| elem.to_s }.join
      return TIE if column_string.include?('1221') && column_string.include?('2112')
      return PLAYER_1_WINS if column_string.include?('1221')
      return PLAYER_2_WINS if column_string.include?('2112')
    end
    NO_RESULT_YET
  end

  def toot_and_otto_left_diagonal
    start_indices = [[0, 0], [0, 1], [0, 2]]
    start_indices.each do |index|
      left_diagonal = []
      i = index[0]
      j = index[1]

      until i == 4 || j == 6
        left_diagonal.push(@state[:board_data][i][j])
        i += 1
        j += 1
      end

      left_diagonal_string = left_diagonal.map { |elem| elem.to_s }.join
      return TIE if left_diagonal_string.include?('1221') && left_diagonal_string.include?('2112')
      return PLAYER_1_WINS if left_diagonal_string.include?('1221')
      return PLAYER_2_WINS if left_diagonal_string.include?('2112')
    end
    NO_RESULT_YET
  end

  def toot_and_otto_right_diagonal
    start_indices = [[0, 3], [0, 4], [0, 5]]
    start_indices.each do |index|
      right_diagonal = []
      i = index[0]
      j = index[1]

      until i == 4 || j == -1
        right_diagonal.push(@state[:board_data][i][j])
        i += 1
        j -= 1
      end

      right_diagonal_string = right_diagonal.map { |elem| elem.to_s }.join
      return TIE if right_diagonal_string.include?('1221') && right_diagonal_string.include?('2112')
      return PLAYER_1_WINS if right_diagonal_string.include?('1221')
      return PLAYER_2_WINS if right_diagonal_string.include?('2112')
    end
    NO_RESULT_YET
  end
end
