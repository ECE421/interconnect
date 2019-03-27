require 'observer'
require 'readline'

# View that represents the main menu screen
class MainMenuView
  include(Observable)

  def initialize(window)
    @window = window # Reference to the application window
  end

  def draw(type, mode)
    layout = Gtk::FlowBox.new
    layout.valign = :start
    layout.max_children_per_line = 1
    layout.selection_mode = :none

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
    game_mode_combo_box.append_text('Player vs. Player')

    if type == AppModel::CONNECT_4
      game_mode_combo_box.append_text('Player vs. CPU')
      game_mode_combo_box.append_text('CPU vs. Player')
    end

    game_mode_combo_box.set_active(mode)
    game_mode_combo_box.signal_connect('changed') do |_, _|
      changed
      notify_observers('game_mode_changed', game_mode_combo_box.active)
    end
    layout.add(game_mode_combo_box)

    start_game_button = Gtk::Button.new(label: 'Start Game')
    start_game_button.signal_connect('clicked') do |_, _|
      changed
      notify_observers('start_game', nil)
    end
    layout.add(start_game_button)

    @window.add(layout)
    @window.show_all
  end
end
