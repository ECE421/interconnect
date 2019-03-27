require 'observer'

# View that represents the game over screen
class GameOverView
  include Observable

  def initialize(window)
    @window = window # Reference to the application window
  end

  def draw(winner)
    layout = Gtk::FlowBox.new
    layout.valign = :start
    layout.max_children_per_line = 1
    layout.selection_mode = :none

    title = winner == AppModel::TIE ? Gtk::Label.new("It's a tie!") : Gtk::Label.new("Player #{winner} wins!")
    layout.add(title)

    main_menu_button = Gtk::Button.new(label: 'Back to Main Menu')
    main_menu_button.signal_connect('clicked') do |_, _|
      changed
      notify_observers('main_menu_clicked')
    end
    layout.add(main_menu_button)

    @window.add(layout)
    @window.show_all
  end
end
