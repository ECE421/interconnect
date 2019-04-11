require_relative 'game_board/cli_game_board_view'
require_relative 'game_board/game_board_presenter'
require_relative 'game_board/game_board_view'
require_relative 'main_menu/cli_main_menu_view'
require_relative 'main_menu/main_menu_presenter'
require_relative 'main_menu/main_menu_view'

# Presenter class for the AppModel
class AppPresenter
  def initialize
    @last_phase = AppModel::MENU
  end

  def update(signal, *data)
    case signal
    when 'attach_model'
      attach_model(data[0])
    when 'init_views'
      init_views(data[0], data[1])
    when 'turn_updated'
      turn_updated(data[0])
    when 'game_phase_updated'
      game_phase_updated(data[0])
    when 'game_type_updated'
      redraw_main_menu(data[0])
    when 'game_network_changed'
      redraw_main_menu(data[0])
    when 'game_mode_updated'
      redraw_main_menu(data[0])
    else
      raise(ArgumentError)
    end
  end

  def attach_model(model)
    @model = model
  end

  def init_views(window, state)
    @window = window

    if state[:interface] == AppModel::GUI
      @main_menu_view = MainMenuView.new(@window)

      @game_board_view = GameBoardView.new(@window)
    elsif state[:interface] == AppModel::CLI
      @main_menu_view = CLIMainMenuView.new

      @game_board_view = CLIGameBoardView.new
    end

    @main_menu_presenter = MainMenuPresenter.new(@model)
    @main_menu_view.add_observer(@main_menu_presenter)

    @game_board_presenter = GameBoardPresenter.new(@model)
    @game_board_view.add_observer(@game_board_presenter)
  end

  def turn_updated(state)
    @game_board_view.draw(state)
  end

  def game_phase_updated(state)
    @window.each { |child| @window.remove(child) } if state[:interface] == AppModel::GUI

    if state[:phase] == AppModel::MENU
      @main_menu_view.draw(state)
    elsif state[:phase] == AppModel::IN_PROGRESS || state[:phase] == AppModel::GAME_OVER
      @game_board_view.init_layout(state)
      @game_board_view.draw(state)
    end
  end

  def redraw_main_menu(state)
    return unless state[:interface] == AppModel::GUI

    @window.each { |child| @window.remove(child) }
    @main_menu_view.draw(state)
  end
end
