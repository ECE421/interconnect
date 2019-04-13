class GameListPresenter
  def initialize(model)
    @model = model
  end

  def update(signal)
    if signal == 'main_menu_clicked'
      @model.back_to_main_menu
    else
      raise(ArgumentError)
    end
  end
end
