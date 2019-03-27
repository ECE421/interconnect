# A presenter that converts actions in the GameOverView to AppModel function calls
class GameOverPresenter
  def initialize(model)
    @model = model
  end

  def update(_)
    @model.back_to_main_menu
  end
end
