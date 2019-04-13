require 'observer'
require 'readline'

# A plain text version of the game board to be displayed in stdout
class CLIGameBoardView
  include(Observable)

  def init_layout(state)
    if state[:type] == AppModel::CONNECT_4
      @header = "\n1 2 3 4 5 6 7"
      @rows = [
        '_ _ _ _ _ _ _ ',
        '_ _ _ _ _ _ _ ',
        '_ _ _ _ _ _ _ ',
        '_ _ _ _ _ _ _ ',
        '_ _ _ _ _ _ _ ',
        '_ _ _ _ _ _ _ '
      ]
    elsif state[:type] == AppModel::TOOT_AND_OTTO
      @header = "\n1 2 3 4 5 6"
      @rows = [
        '_ _ _ _ _ _ ',
        '_ _ _ _ _ _ ',
        '_ _ _ _ _ _ ',
        '_ _ _ _ _ _ '
      ]
    end
  end

  def draw(state, _my_turn)
    (0..(state[:board_columns] - 1)).each do |col|
      (0..(state[:board_rows] - 1)).each do |row|
        if (state[:board_data][row][col]).zero?
          @rows[row][col * 2] = '_'
        elsif state[:board_data][row][col] == 1 && state[:type] == AppModel::CONNECT_4
          @rows[row][col * 2] = 'R'
        elsif state[:board_data][row][col] == 1 && state[:type] == AppModel::TOOT_AND_OTTO
          @rows[row][col * 2] = 'T'
        elsif state[:board_data][row][col] == 2 && state[:type] == AppModel::CONNECT_4
          @rows[row][col * 2] = 'Y'
        elsif state[:board_data][row][col] == 2 && state[:type] == AppModel::TOOT_AND_OTTO
          @rows[row][col * 2] = 'O'
        end
      end
    end

    puts(@header)
    @rows.each { |row| puts(row) }

    if state[:phase] == AppModel::GAME_OVER
      if state[:result] == AppModel::TIE
        puts("It's a tie!")
      else
        puts("Player #{state[:result]} wins!")
      end
      exit
    end

    puts(state[:player_turn])
    if state[:player_turn]
      valid_input = false
      until valid_input
        if state[:type] == AppModel::CONNECT_4
          input = Readline.readline("Player #{state[:turn]}:", true)
          if %w[1 2 3 4 5 6 7].include?(input)
            valid_input = true
            column_index = Integer(input) - 1
            changed
            notify_observers('column_clicked', column_index)
          else
            puts('Invalid command. Must input column number as: <integer> (1-7)')
          end
        elsif state[:type] == AppModel::TOOT_AND_OTTO
          if state[:turn] == 1 && state[:active_token] == AppModel::TOKEN_T
            input = Readline.readline("Player 1, [T] x#{state[:player_1_t]} | O x#{state[:player_1_o]}:", true)
          elsif state[:turn] == 1 && state[:active_token] == AppModel::TOKEN_O
            input = Readline.readline("Player 1, T x#{state[:player_1_t]} | [O] x#{state[:player_1_o]}:", true)
          elsif state[:turn] == 2 && state[:active_token] == AppModel::TOKEN_T
            input = Readline.readline("Player 2, [T] x#{state[:player_2_t]} | O x#{state[:player_2_o]}:", true)
          elsif state[:turn] == 2 && state[:active_token] == AppModel::TOKEN_O
            input = Readline.readline("Player 2, T x#{state[:player_2_t]} | [O] x#{state[:player_2_o]}:", true)
          end

          if %w[t T].include?(input)
            valid_input = true
            changed
            notify_observers('t_clicked')
          elsif %w[o O].include?(input)
            valid_input = true
            changed
            notify_observers('o_clicked')
          elsif %w[1 2 3 4 5 6].include?(input)
            valid_input = true
            column_index = Integer(input) - 1
            changed
            notify_observers('column_clicked', column_index)
          else
            puts('Invalid command. Options are: Column (1-6); T (case-insensitive); or O (case-insensitive)')
          end
        end
      end
    else
      changed
      notify_observers('cpu_turn')
    end
  end
end
