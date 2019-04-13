require 'observer'

class GameListView
  include(Observable)

  def initialize(window)
    @window = window # Reference to the application window
  end

  def draw(available_games)
    scroll_window = Gtk::ScrolledWindow.new
    content_box = Gtk::Box.new(:vertical, 10)
    grid = Gtk::Grid.new
    grid.set_column_homogeneous(true)

    game_code_header = Gtk::Label.new
    game_code_header.set_markup('<b>Game Code</b>')
    grid.attach(game_code_header, 0, 0, 1, 1)

    available_games.each_with_index do |row, i|
      row.each_with_index do |entry, j|
        next unless j.zero?

        label = Gtk::Label.new("#{entry[1]}")
        grid.attach(label, j, i + 1, 1, 1)
      end
    end

    main_menu_button = Gtk::Button.new(label: 'Back to Main Menu')
    main_menu_button.signal_connect('clicked') do |_, _|
      changed
      notify_observers('main_menu_clicked')
    end

    content_box.add(grid)
    content_box.set_child_packing(grid, :expand => true)
    content_box.add(main_menu_button)
    scroll_window.add(content_box)
    @window.add(scroll_window)
    @window.show_all
  end
end

