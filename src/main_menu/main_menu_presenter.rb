# A presenter that converts actions in the MainMenuView to AppModel function calls
class MainMenuPresenter
  def initialize(model)
    @model = model
  end

  def update(signal, *data)
    case signal
    when 'game_type_changed'
      @model.update_game_type(data[0])
    when 'game_mode_changed'
      @model.update_game_mode(data[0])
    when 'start_game'
      @model.start_game
    when 'start_league_game'
      @model.start_league_game(data[0], data[1], data[2])
    when 'host_game'
      @model.host_game(data[0], data[1])
    when 'join_game'
      @model.join_game(data[0], data[1])
    when 'view_leaderboard'
      @model.view_leaderboard
    when 'load_game'
      @model.load_game(data[0], data[1])
    else
      raise(ArgumentError)
    end
  end
end
