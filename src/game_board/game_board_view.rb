require 'observer'

# View that represents the game board
class GameBoardView
  include Observable

  def initialize(window, settings)
    @window = window # Reference to the application window

    column_style = Gtk::CssProvider.new
    column_style.load(data: 'button {background-image: image(grey); opacity: 0;} button:hover {opacity: 0.5;}')

    @empty_cell = Gtk::CssProvider.new
    @empty_cell.load(data: 'button {background-image: image(white);}')

    @player_1_token = Gtk::CssProvider.new
    @player_1_token.load(data: "button {background-image: image(#{settings[:player_1_colour]});}")

    @player_2_token = Gtk::CssProvider.new
    @player_2_token.load(data: "button {background-image: image(#{settings[:player_2_colour]});}")

    @t_token = Gtk::CssProvider.new
    @t_token.load(data: 'button {background-image: url("./src/game_board/t.png");}')

    @o_token = Gtk::CssProvider.new
    @o_token.load(data: 'button {background-image: url("./src/game_board/o.png");}')

    @cells = Array.new(settings[:board_rows]) { Array.new(settings[:board_columns], nil) }
    @layout = Gtk::Fixed.new

    @turn_indicator = Gtk::Label.new
    @turn_indicator.set_markup("<span foreground='#{settings[:player_1_colour]}'>Player 1's Turn:</span>")
    @layout.put(@turn_indicator, 0, 0)

    cell_grid = Gtk::Grid.new
    @layout.put(cell_grid, 0, 40)

    (0..(settings[:board_columns] - 1)).each do |col|
      (0..(settings[:board_rows] - 1)).each do |row|
        cell = Gtk::Button.new
        cell.set_size_request(100, 100)
        @cells[row][col] = cell
        cell_grid.attach(cell, col, row, 1, 1)
      end
    end

    column_grid = Gtk::Grid.new
    @layout.put(column_grid, 0, 40)

    (0..(settings[:board_columns] - 1)).each do |column_index|
      column = Gtk::Button.new
      column.set_size_request(100, 100 * settings[:board_rows])
      column.style_context.add_provider(column_style, Gtk::StyleProvider::PRIORITY_USER)
      column.signal_connect('clicked') do |_|
        changed
        notify_observers('column_clicked', column_index)
      end
      column_grid.attach(column, column_index, 0, 1, 1)
    end

    @tokens_indicator = Gtk::Label.new

    @t_button = Gtk::Button.new
    @t_button.set_size_request(100, 100)
    @t_button.style_context.add_provider(@t_token, Gtk::StyleProvider::PRIORITY_USER)
    @t_button.signal_connect('clicked') do |_, _|
      changed
      notify_observers('t_clicked')
    end

    @o_button = Gtk::Button.new
    @o_button.set_size_request(100, 100)
    @o_button.style_context.add_provider(@o_token, Gtk::StyleProvider::PRIORITY_USER)
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
  end

  def bind_layout
    @window.add(@layout)
  end

  def draw(state)
    if state[:type] == AppModel::CONNECT_4
      if state[:turn] == AppModel::PLAYER_1_TURN
        @turn_indicator.set_markup("<span foreground='#{state[:settings][:player_1_colour]}'>Player 1's Turn:</span>")
      elsif state[:turn] == AppModel::PLAYER_2_TURN
        @turn_indicator.set_markup("<span foreground='#{state[:settings][:player_2_colour]}'>Player 2's Turn:</span>")
      end

      @layout.remove(@tokens_indicator)
      @layout.remove(@t_button)
      @layout.remove(@o_button)
    elsif state[:type] == AppModel::TOOT_AND_OTTO
      if state[:turn] == AppModel::PLAYER_1_TURN
        @turn_indicator.set_markup("<span>Player 1's Turn (TOOT):</span>")
        @tokens_indicator.set_markup("<span>T's Remaining: #{state[:player_1_t]} | O's Remaining: #{state[:player_1_o]}</span>")
      elsif state[:turn] == AppModel::PLAYER_2_TURN
        @turn_indicator.set_markup("<span>Player 2's Turn (OTTO):</span>")
        @tokens_indicator.set_markup("<span>T's Remaining: #{state[:player_2_t]} | O's Remaining: #{state[:player_2_o]}</span>")
      end

      @layout.put(@tokens_indicator, 0, 100 * state[:settings][:board_rows] + 60)
      @layout.put(@t_button, 0, 100 * state[:settings][:board_rows] + 100)
      @layout.put(@o_button, 100, 100 * state[:settings][:board_rows] + 100)
    end

    (0..(state[:settings][:board_columns] - 1)).each do |col|
      (0..(state[:settings][:board_rows] - 1)).each do |row|
        if (state[:board_data][row][col]).zero?
          @cells[row][col].style_context.add_provider(@empty_cell, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 1 && state[:type] == AppModel::CONNECT_4
          @cells[row][col].style_context.add_provider(@player_1_token, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 1 && state[:type] == AppModel::TOOT_AND_OTTO
          @cells[row][col].style_context.add_provider(@t_token, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 2 && state[:type] == AppModel::CONNECT_4
          @cells[row][col].style_context.add_provider(@player_2_token, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 2 && state[:type] == AppModel::TOOT_AND_OTTO
          @cells[row][col].style_context.add_provider(@o_token, Gtk::StyleProvider::PRIORITY_USER)
        end
      end
    end

    if state[:phase] == AppModel::GAME_OVER
      winner = state[:result]
      @winner.set_markup(winner == AppModel::TIE ? "<span>It's a tie!</span>" : "<span>Player #{winner} wins!</span>")
      @layout.put(@winner, 0, 100 * state[:settings][:board_rows] + 200)
      @layout.put(@main_menu_button, 0, 100 * state[:settings][:board_rows] + 240)
    else
      @layout.remove(@winner)
      @layout.remove(@main_menu_button)
    end

    @window.show_all
  end
end
