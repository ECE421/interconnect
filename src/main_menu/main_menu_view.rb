require 'observer'
require 'readline'

# View that represents the main menu screen
class MainMenuView
  include(Observable)

  def initialize(window)
    @window = window # Reference to the application window
  end

  def draw(state)
    type = state[:type]
    mode = state[:mode]

    layout = Gtk::FlowBox.new
    layout.valign = :start
    layout.max_children_per_line = 1
    layout.selection_mode = :none
    layout.set_row_spacing(10)

    title = Gtk::Label.new('Ruby Connect Games')
    layout.add(title)

    game_type_combo_box = Gtk::ComboBoxText.new
    game_type_combo_box.append_text('Connect 4')
    game_type_combo_box.append_text('Toot and Otto')
    game_type_combo_box.set_active(type)
    game_type_combo_box.signal_connect('changed') do |_, _|
      changed
      notify_observers('game_type_changed', game_type_combo_box.active)
    end
    layout.add(game_type_combo_box)

    game_mode_combo_box = Gtk::ComboBoxText.new
    game_mode_combo_box.append_text('Player vs. Player (Local)')
    game_mode_combo_box.append_text('Player vs. Player (Distributed)')
    game_mode_combo_box.append_text('Player vs. CPU (Local)')
    game_mode_combo_box.append_text('CPU vs. Player (Local)')
    game_mode_combo_box.append_text('CPU vs. CPU (Local)')

    game_mode_combo_box.set_active(mode)
    game_mode_combo_box.signal_connect('changed') do |_, _|
      changed
      notify_observers('game_mode_changed', game_mode_combo_box.active)
    end
    layout.add(game_mode_combo_box)

    horizontal_separator = Gtk::Separator.new(:horizontal)
    layout.add(horizontal_separator)

    player_1_label = Gtk::Label.new('Player 1:')
    player_1_username_label = Gtk::Label.new('Username:')
    player_1_username_entry = Gtk::Entry.new

    if mode == AppModel::PLAYER_PLAYER_LOCAL
      layout.add(player_1_label)
      player_1_username_box = Gtk::Box.new(:horizontal, 10)
      player_1_username_box.add(player_1_username_label)
      player_1_username_box.add(player_1_username_entry)
      player_1_username_box.set_child_packing(player_1_username_entry, :expand => true)
      layout.add(player_1_username_box)

      horizontal_separator = Gtk::Separator.new(:horizontal)
      layout.add(horizontal_separator)

      player_2_label = Gtk::Label.new('Player 2:')
      player_2_username_label = Gtk::Label.new('Username:')
      player_2_username_entry = Gtk::Entry.new

      layout.add(player_2_label)
      player_2_username_box = Gtk::Box.new(:horizontal, 10)
      player_2_username_box.add(player_2_username_label)
      player_2_username_box.add(player_2_username_entry)
      player_2_username_box.set_child_packing(player_2_username_entry, :expand => true)
      layout.add(player_2_username_box)

      game_code_label = Gtk::Label.new('Game code:')
      layout.add(game_code_label)
      game_code_entry = Gtk::Entry.new
      layout.add(game_code_entry)

      horizontal_separator = Gtk::Separator.new(:horizontal)
      layout.add(horizontal_separator)

      start_game_button = Gtk::Button.new(label: 'New Game')
      start_game_button.signal_connect('clicked') do |_, _|
        changed
        notify_observers('start_league_game', player_1_username_entry.text, player_2_username_entry.text, game_code_entry.text)
      end
      layout.add(start_game_button)

      load_game_button = Gtk::Button.new(label: 'Load Game')
      load_game_button.signal_connect('clicked') do |_, _|
        changed
        notify_observers('load_game', player_1_username_entry.text, game_code_entry.text)
      end
      layout.add(load_game_button)
    elsif mode == AppModel::PLAYER_PLAYER_DISTRIBUTED
      player_1_username_box = Gtk::Box.new(:horizontal, 10)
      player_1_username_box.add(player_1_username_label)
      player_1_username_box.add(player_1_username_entry)
      player_1_username_box.set_child_packing(player_1_username_entry, :expand => true)
      layout.add(player_1_username_box)

      horizontal_separator = Gtk::Separator.new(:horizontal)
      layout.add(horizontal_separator)

      game_code_label = Gtk::Label.new('Game code:')
      game_code_entry = Gtk::Entry.new
      game_code_box = Gtk::Box.new(:horizontal, 10)
      game_code_box.add(game_code_label)
      game_code_box.add(game_code_entry)
      game_code_box.set_child_packing(game_code_entry, :expand => true)
      layout.add(game_code_box)

      host_game_button = Gtk::Button.new(label: 'Host Game')
      host_game_button.signal_connect('clicked') do |_, _|
        changed
        notify_observers('host_game', player_1_username_entry.text, game_code_entry.text)
      end
      join_game_button = Gtk::Button.new(label: 'Join Game')
      join_game_button.signal_connect('clicked') do |_, _|
        changed
        notify_observers('join_game', player_1_username_entry.text, game_code_entry.text)
      end
      game_button_box = Gtk::Box.new(:horizontal, 10)
      game_button_box.add(host_game_button)
      game_button_box.set_child_packing(host_game_button, :expand => true)
      game_button_box.add(join_game_button)
      game_button_box.set_child_packing(join_game_button, :expand => true)
      layout.add(game_button_box)

      load_game_button = Gtk::Button.new(label: 'Load Game')
      load_game_button.signal_connect('clicked') do |_, _|
        changed
        notify_observers('load_game', player_1_username_entry.text, game_code_entry.text)
      end
      layout.add(load_game_button)
    else
      start_game_button = Gtk::Button.new(label: 'Start Game')
      start_game_button.signal_connect('clicked') do |_, _|
        changed
        notify_observers('start_game')
      end
      layout.add(start_game_button)
    end

    view_leaderboard_button = Gtk::Button.new(label: 'View Leaderboard')
    view_leaderboard_button.signal_connect('clicked') do |_, _|
      changed
      notify_observers('view_leaderboard')
    end
    layout.add(view_leaderboard_button)

    error_label = Gtk::Label.new
    error_label.set_markup("<span foreground='#FF0000'>#{state[:error_message]}</span>")
    layout.add(error_label)

    @window.add(layout)
    @window.show_all
  end
end
