# A presenter that converts actions in the GameBoardView to AppModel function calls
class GameBoardPresenter
  def initialize(model)
    @model = model
  end

  def update(signal, column_index)
    if signal == 'column_clicked'
      @model.place_token(column_index)
    elsif signal == 'main_menu_clicked'
      @model.back_to_main_menu
    end
  end
end
