require 'matrix'
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

  # CPU Difficulty (percentage chance of playing random)
  EASY = 0.75
  MEDIUM = 0.25
  HARD = 0

  def initialize(app, presenter, interface = GUI)
    # Initial game state
    @state = {
      interface: interface,
      turn: PLAYER_1_TURN,
      player_turn: true,
      type: CONNECT_4,
      mode: PLAYER_PLAYER_LOCAL,
      phase: MENU,
      board_data: Array.new(6) { Array.new(7, 0) },
      result: NO_RESULT_YET,
      player_1_t: 6,
      player_1_o: 6,
      player_2_t: 6,
      player_2_o: 6,
      board_columns: 7,
      board_rows: 6,
      active_token: TOKEN_T,
      cpu_difficulty: EASY
    }

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

    changed
    notify_observers('turn_updated', @state)
  end

  def update_game_type(type)
    @state[:type] = type
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

  def start_league_game(username_1, username_2)
    puts(username_1, username_2)
    # TODO: Implement
  end

  def host_game(username, game_code)
    puts(username, game_code)
    # TODO: Implement
  end

  def join_game(username, game_code)
    puts(username, game_code)
    # TODO: Implement
  end

  def back_to_main_menu
    @state[:turn] = PLAYER_1_TURN
    @state[:board_data] = Array.new(@state[:board_rows]) { Array.new(@state[:board_columns], 0) }
    @state[:result] = NO_RESULT_YET
    update_game_phase(MENU)
  end

  def update_game_phase(phase)
    @state[:phase] = phase
    changed
    notify_observers('game_phase_updated', @state)
  end

  def place_token(column_index)
    return if @state[:phase] == GAME_OVER

    token_played = board_place_token(column_index)

    result = game_result

    if result != NO_RESULT_YET
      @state[:result] = result
      update_game_phase(GAME_OVER)
    elsif @state[:turn] == PLAYER_1_TURN && token_played
      update_turn(PLAYER_2_TURN)
    elsif @state[:turn] == PLAYER_2_TURN && token_played
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
    cpu_random
  end

  # cpu_attempt works to try to win the game by placing a token in each column once and checking to see if any result in
  # a win condition. it clears all unsuccessful token attempts
  def cpu_attempt
    (0..(@state[:board_columns] - 1)).each do |c|
      token_placed = board_place_token(c)
      if game_result != NO_RESULT_YET # full send
        @state[:result] = game_result
        update_game_phase(GAME_OVER)
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
        board_place_token(c) # place token to block
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
        if game_result != NO_RESULT_YET
          remove_array.reverse_each do |r| # remove moves from our array 'stack'
            board_remove_token(r)
          end
          return true
        end
        remove_array.push(c) if token_placed # add move for later deletion
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

    return TIE if connect_4_tie?

    NO_RESULT_YET
  end

  def toot_and_otto_game_result
    result = toot_and_otto_horizontal
    return result unless result == NO_RESULT_YET

    result = toot_and_otto_vertical
    return result unless result == NO_RESULT_YET

    result = toot_and_otto_left_diagonal
    return result unless result == NO_RESULT_YET

    toot_and_otto_right_diagonal
  end

  def connect_4_tie?
    @state[:board_data].each do |row|
      row.each do |element|
        return false if element.zero?
      end
    end
    true
  end

  def connect_4_horizontal?
    @state[:board_data].each do |row|
      chain = 0
      row.each do |element|
        if element != @state[:turn]
          chain = 0
          next
        end

        chain += 1
        return true if chain == 4
      end
    end
    false
  end

  def connect_4_vertical?
    Matrix[*@state[:board_data]].column_vectors.each do |column|
      chain = 0
      column.each do |element|
        if element != @state[:turn]
          chain = 0
          next
        end

        chain += 1
        return true if chain == 4
      end
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

      chain = 0
      left_diagonal.each do |element|
        if element != @state[:turn]
          chain = 0
          next
        end

        chain += 1
        return true if chain == 4
      end
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

      chain = 0
      right_diagonal.each do |element|
        if element != @state[:turn]
          chain = 0
          next
        end

        chain += 1
        return true if chain == 4
      end
    end
    false
  end

  def toot_and_otto_horizontal
    @state[:board_data].each do |row|
      chain_toot = ''
      chain_otto = ''
      row.each do |element|
        chain_toot, chain_otto = toot_and_otto_increment(chain_toot, chain_otto, element)
        return TIE if chain_toot == 'toot' && chain_otto == 'otto'
        return PLAYER_1_WINS if chain_toot == 'toot'
        return PLAYER_2_WINS if chain_otto == 'otto'
      end
    end
    NO_RESULT_YET
  end

  def toot_and_otto_vertical
    Matrix[*@state[:board_data]].column_vectors.each do |column|
      chain_toot = ''
      chain_otto = ''
      column.each do |element|
        chain_toot, chain_otto = toot_and_otto_increment(chain_toot, chain_otto, element)
        return TIE if chain_toot == 'toot' && chain_otto == 'otto'
        return PLAYER_1_WINS if chain_toot == 'toot'
        return PLAYER_2_WINS if chain_otto == 'otto'
      end
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

      chain_toot = ''
      chain_otto = ''
      left_diagonal.each do |element|
        chain_toot, chain_otto = toot_and_otto_increment(chain_toot, chain_otto, element)
        return TIE if chain_toot == 'toot' && chain_otto == 'otto'
        return PLAYER_1_WINS if chain_toot == 'toot'
        return PLAYER_2_WINS if chain_otto == 'otto'
      end
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

      chain_toot = ''
      chain_otto = ''
      right_diagonal.each do |element|
        chain_toot, chain_otto = toot_and_otto_increment(chain_toot, chain_otto, element)
        return TIE if chain_toot == 'toot' && chain_otto == 'otto'
        return PLAYER_1_WINS if chain_toot == 'toot'
        return PLAYER_2_WINS if chain_otto == 'otto'
      end
    end
    NO_RESULT_YET
  end

  def toot_and_otto_increment(chain_toot, chain_otto, element)
    return ['', ''] if element.zero?

    if element == TOKEN_T
      if ['', 'too'].include?(chain_toot)
        chain_toot += 't'
      else
        chain_toot = 't'
      end

      if %w[o ot].include?(chain_otto)
        chain_otto += 't'
      else
        chain_otto = ''
      end
    elsif element == TOKEN_O
      if %w[t to].include?(chain_toot)
        chain_toot += 'o'
      else
        chain_toot = ''
      end

      if ['', 'ott'].include?(chain_otto)
        chain_otto += 'o'
      else
        chain_otto = 'o'
      end
    end

    [chain_toot, chain_otto]
  end
end
