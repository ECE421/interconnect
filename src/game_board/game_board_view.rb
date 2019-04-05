require 'observer'

# View that represents the game board
class GameBoardView
  include Observable

  def initialize(window)
    @window = window # Reference to the application window

    @column_style = Gtk::CssProvider.new
    @column_style.load(data: 'button {background-image: image(grey); opacity: 0;} button:hover {opacity: 0.5;}')

    @empty_cell = Gtk::CssProvider.new
    @empty_cell.load(data: 'button {background-image: image(white);}')

    @red_token = Gtk::CssProvider.new
    @red_token.load(data: 'button {background-image: image(red);}')

    @yellow_token = Gtk::CssProvider.new
    @yellow_token.load(data: 'button {background-image: image(yellow);}')

    @t_token = Gtk::CssProvider.new
    @t_token.load(data: 'button {background-image: url("./src/game_board/t.png");}')

    @o_token = Gtk::CssProvider.new
    @o_token.load(data: 'button {background-image: url("./src/game_board/o.png");}')

    @cells = Array.new(6) { Array.new(7, nil) }
    @layout = Gtk::Fixed.new

    cell_grid = Gtk::Grid.new
    @layout.put(cell_grid, 0, 0)

    (0..6).each do |col|
      (0..5).each do |row|
        cell = Gtk::Button.new
        cell.set_size_request(100, 100)
        @cells[row][col] = cell
        cell_grid.attach(cell, col, row, 1, 1)
      end
    end

    column_grid = Gtk::Grid.new
    @layout.put(column_grid, 0, 0)

    (0..6).each do |column_index|
      column = Gtk::Button.new
      column.set_size_request(100, 600)
      column.style_context.add_provider(@column_style, Gtk::StyleProvider::PRIORITY_USER)
      column.signal_connect('clicked') do |_|
        changed
        notify_observers('column_clicked', column_index)
      end
      column_grid.attach(column, column_index, 0, 1, 1)
    end
  end

  def bind_layout
    @window.add(@layout)
  end

  def draw(state)
    (0..6).each do |col|
      (0..5).each do |row|
        if (state[:board_data][row][col]).zero?
          @cells[row][col].style_context.add_provider(@empty_cell, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 1 && state[:type] == AppModel::CONNECT_4
          @cells[row][col].style_context.add_provider(@red_token, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 1 && state[:type] == AppModel::TOOT_AND_OTTO
          @cells[row][col].style_context.add_provider(@t_token, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 2 && state[:type] == AppModel::CONNECT_4
          @cells[row][col].style_context.add_provider(@yellow_token, Gtk::StyleProvider::PRIORITY_USER)
        elsif state[:board_data][row][col] == 2 && state[:type] == AppModel::TOOT_AND_OTTO
          @cells[row][col].style_context.add_provider(@o_token, Gtk::StyleProvider::PRIORITY_USER)
        end
      end
    end

    if state[:phase] == AppModel::GAME_OVER
      winner = state[:result]
      title = winner == AppModel::TIE ? Gtk::Label.new("It's a tie!") : Gtk::Label.new("Player #{winner} wins!")
      @layout.put(title, 0, 700)

      main_menu_button = Gtk::Button.new(label: 'Back to Main Menu')
      main_menu_button.signal_connect('clicked') do |_, _|
        changed
        notify_observers('main_menu_clicked')
      end
      @layout.put(main_menu_button, 0, 800)
    end

    @window.show_all
  end
end
