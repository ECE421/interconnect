require 'observer'

# View that represents the game board
class GameBoardView
  include Observable

  # This method sets up all unchanging (non-state-based) properties of the game board
  def initialize(window)
    @window = window # Reference to the application window

    @column_style = Gtk::CssProvider.new
    @column_style.load(data: 'button {background-image: image(grey); opacity: 0;} button:hover {opacity: 0.5;}')

    @empty_cell_style = Gtk::CssProvider.new
    @empty_cell_style.load(data: 'button {background-image: image(white);}')

    @mask_style = Gtk::CssProvider.new
    @mask_style.load(data: 'button {background-image: image(grey); opacity: 0.5;}')

    @player_1_token_style = Gtk::CssProvider.new
    @player_1_token_style.load(data: "button {background-image: image(#FF0000);}")

    @player_2_token_style = Gtk::CssProvider.new
    @player_2_token_style.load(data: "button {background-image: image(#FFFF00);}")

    @t_style = Gtk::CssProvider.new
    @t_style.load(data: 'button {background-image: url("./src/game_board/t.png");}')

    @t_selected_style = Gtk::CssProvider.new
    @t_selected_style.load(data: 'button {background-image: url("./src/game_board/t_selected.png");}')

    @o_style = Gtk::CssProvider.new
    @o_style.load(data: 'button {background-image: url("./src/game_board/o.png");}')

    @o_selected_style = Gtk::CssProvider.new
    @o_selected_style.load(data: 'button {background-image: url("./src/game_board/o_selected.png");}')
  end

  # This method is called at the start of a each game
  def init_layout(state)
    @cells = Array.new(state[:board_rows]) { Array.new(state[:board_columns], nil) }
    @layout = Gtk::FlowBox.new
    @layout.valign = :start
    @layout.max_children_per_line = 1
    @layout.selection_mode = :none
    @layout.set_row_spacing(10)

    @turn_indicator = Gtk::Label.new
    @layout.add(@turn_indicator)

    @fixed_layout = Gtk::Fixed.new
    @layout.add(@fixed_layout)

    cell_grid = Gtk::Grid.new
    @fixed_layout.put(cell_grid, 0, 0)

    (0..(state[:board_columns] - 1)).each do |col|
      (0..(state[:board_rows] - 1)).each do |row|
        cell = Gtk::Button.new
        cell.set_size_request(100, 100)
        @cells[row][col] = cell
        cell_grid.attach(cell, col, row, 1, 1)
      end
    end

    column_grid = Gtk::Grid.new
    @fixed_layout.put(column_grid, 0, 0)

    (0..(state[:board_columns] - 1)).each do |column_index|
      column = Gtk::Button.new
      column.set_size_request(100, 100 * state[:board_rows])
      column.style_context.add_provider(@column_style, Gtk::StyleProvider::PRIORITY_USER)
      column.signal_connect('clicked') do |_|
        changed
        notify_observers('column_clicked', column_index)
      end
      column_grid.attach(column, column_index, 0, 1, 1)
    end

    @tokens_indicator = Gtk::Label.new

    @t_button = Gtk::Button.new
    @t_button.set_size_request(100, 100)
    @t_button.signal_connect('clicked') do |_, _|
      changed
      notify_observers('t_clicked')
    end

    @o_button = Gtk::Button.new
    @o_button.set_size_request(100, 100)
    @o_button.signal_connect('clicked') do |_, _|
      changed
      notify_observers('o_clicked')
    end

    @winner = Gtk::Label.new
    @main_menu_button = Gtk::Button.new(label: 'Back to Main Menu')
    @main_menu_button.signal_connect('clicked') do |_, _|
      changed
      notify_observers('main_menu_clicked')
    end

    if state[:type] == AppModel::TOOT_AND_OTTO
      @token_button_box = Gtk::Box.new(:horizontal, 10)
      @layout.add(@tokens_indicator)
      @token_button_box.add(@t_button)
      @token_button_box.add(@o_button)
      @layout.add(@token_button_box)
    end

    @mask = Gtk::Button.new(label: 'Please wait for your turn...')
    @mask.set_size_request(100 * state[:board_columns], 100 * state[:board_rows])
    @mask.style_context.add_provider(@mask_style, Gtk::StyleProvider::PRIORITY_USER)

    @window.add(@layout)
  end

  def draw(state, my_turn)
    if state[:type] == AppModel::CONNECT_4
      if state[:turn] == AppModel::PLAYER_1_TURN
        @turn_indicator.set_markup("<span>Player 1's Turn (Red):</span>")
      elsif state[:turn] == AppModel::PLAYER_2_TURN
        @turn_indicator.set_markup("<span>Player 2's Turn (Yellow):</span>")
      end
    elsif state[:type] == AppModel::TOOT_AND_OTTO
      if state[:turn] == AppModel::PLAYER_1_TURN
        @turn_indicator.set_markup("<span>Player 1's Turn (TOOT):</span>")
        @tokens_indicator.set_markup("<span>T's Remaining: #{state[:player_1_t]} | O's Remaining: #{state[:player_1_o]}</span>")
      elsif state[:turn] == AppModel::PLAYER_2_TURN
        @turn_indicator.set_markup("<span>Player 2's Turn (OTTO):</span>")
        @tokens_indicator.set_markup("<span>T's Remaining: #{state[:player_2_t]} | O's Remaining: #{state[:player_2_o]}</span>")
      end

      if state[:active_token] == AppModel::TOKEN_T
        @t_button.style_context.add_provider(@t_selected_style, Gtk::StyleProvider::PRIORITY_USER)
        @o_button.style_context.add_provider(@o_style, Gtk::StyleProvider::PRIORITY_USER)
      elsif state[:active_token] == AppModel::TOKEN_O
        @t_button.style_context.add_provider(@t_style, Gtk::StyleProvider::PRIORITY_USER)
        @o_button.style_context.add_provider(@o_selected_style, Gtk::StyleProvider::PRIORITY_USER)
      end
    end

    (0..(state[:board_columns] - 1)).each do |col|
      (0..(state[:board_rows] - 1)).each do |row|
        if (state[:board_data][row][col]).zero?
          @cells[row][col].style_context.add_provider(@empty_cell_style, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 1 && state[:type] == AppModel::CONNECT_4
          @cells[row][col].style_context.add_provider(@player_1_token_style, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 1 && state[:type] == AppModel::TOOT_AND_OTTO
          @cells[row][col].style_context.add_provider(@t_style, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 2 && state[:type] == AppModel::CONNECT_4
          @cells[row][col].style_context.add_provider(@player_2_token_style, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 2 && state[:type] == AppModel::TOOT_AND_OTTO
          @cells[row][col].style_context.add_provider(@o_style, Gtk::StyleProvider::PRIORITY_USER)
        end
      end
    end

    if state[:phase] == AppModel::GAME_OVER
      winner = state[:result]
      @winner.set_markup(winner == AppModel::TIE ? "<span>It's a tie!</span>" : "<span>Player #{winner} wins!</span>")
      @layout.add(@winner)
      @layout.add(@main_menu_button)
    end

    if state[:mode] == AppModel::PLAYER_PLAYER_DISTRIBUTED && state[:turn] != my_turn && state[:result] == AppModel::NO_RESULT_YET
      @fixed_layout.put(@mask, 0, 0)

      Thread.new do
        while true
          sleep(3)
          response = Net::HTTP.get_response(URI('https://interconnect4-server.herokuapp.com/' + "game?_id=#{state[:_id]}"))
          new_state = eval(response.body)
          state = Hash[new_state.map{ |k, v| [k.to_sym, v] }]
          break if state[:turn] == my_turn || state[:result] != AppModel::NO_RESULT_YET
        end
        changed
        notify_observers('update_turn', state[:turn])
      end
    else
      @fixed_layout.remove(@mask)
    end

    @window.show_all

    unless state[:player_turn]
      changed
      notify_observers('cpu_turn')
    end
  end
end
