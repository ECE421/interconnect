require 'observer'

class LeaderboardView
  include(Observable)

  def initialize(window)
    @window = window # Reference to the application window
  end

  def draw(leaderboard)
    scroll_window = Gtk::ScrolledWindow.new
    content_box = Gtk::Box.new(:vertical, 10)
    grid = Gtk::Grid.new
    grid.set_column_homogeneous(true)

    username_header = Gtk::Label.new
    username_header.set_markup('<b>Username</b>')
    grid.attach(username_header, 0, 0, 1, 1)

    wins_header = Gtk::Label.new
    wins_header.set_markup('<b>Wins</b>')
    grid.attach(wins_header, 1, 0, 1, 1)

    losses_header = Gtk::Label.new
    losses_header.set_markup('<b>Losses</b>')
    grid.attach(losses_header, 2, 0, 1, 1)

    ties_header = Gtk::Label.new
    ties_header.set_markup('<b>Ties</b>')
    grid.attach(ties_header, 3, 0, 1, 1)

    leaderboard.each_with_index do |row, i|
      row.each_with_index do |entry, j|
        next if j.zero?

        label = Gtk::Label.new("#{entry[1]}")
        grid.attach(label, j - 1, i + 1, 1, 1)
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
