# A presenter that converts actions in the GameBoardView to AppModel function calls
class GameBoardPresenter
  def initialize(model)
    @model = model
  end

  def update(signal, *data)
    case signal
    when 'column_clicked'
      column_index = data[0]
      @model.place_token(column_index)
    when 'main_menu_clicked'
      @model.back_to_main_menu
    when 't_clicked'
      @model.update_active_token(AppModel::TOKEN_T)
    when 'o_clicked'
      @model.update_active_token(AppModel::TOKEN_O)
    when 'cpu_turn'
      @model.cpu_turn
    when 'try_update_turn'
      @model.update_turn
    else
      raise(ArgumentError)
    end
  end
end
