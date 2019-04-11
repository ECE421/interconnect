# A presenter that converts actions in the MainMenuView to AppModel function calls
class MainMenuPresenter
  def initialize(model)
    @model = model
  end

  def update(signal, *data)
    case signal
    when 'game_type_changed'
      @model.update_game_type(data[0])
    when 'game_network_changed'
      @model.update_game_network(data[0])
    when 'game_mode_changed'
      @model.update_game_mode(data[0])
    when 'start_game'
      @model.start_game
    else
      raise(ArgumentError)
    end
  end
end
