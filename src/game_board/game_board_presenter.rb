# A presenter that converts actions in the GameBoardView to AppModel function calls
class GameBoardPresenter
  def initialize(model)
    @model = model
  end

  def update(signal, column_index)
    raise ArgumentError unless signal == 'column_clicked'

    @model.place_token(column_index)
  end
end
