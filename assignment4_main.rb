require 'gtk3'
require_relative 'src/app_model'
require_relative 'src/app_presenter'

# GUI Version
app = Gtk::Application.new('disconnect.four.hahaha', :flags_none)
model = AppModel.new(app, AppPresenter.new, AppModel::GUI)
puts(model.app.run([$PROGRAM_NAME] + ARGV))

# CLI Version
# AppModel.new(nil, AppPresenter.new, AppModel::CLI)
