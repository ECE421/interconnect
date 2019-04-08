require 'gtk3'
require_relative 'src/app_model'
require_relative 'src/app_presenter'

# GUI Version
app = Gtk::Application.new('interconnect4.com', :flags_none)
model = AppModel.new(app, AppPresenter.new, AppModel::GUI)
if ARGV.include?('cli')
  AppModel.new(nil, AppPresenter.new, AppModel::CLI) # CLI Version
else
  puts(model.app.run([$PROGRAM_NAME] + ARGV)) # GUI Version
end

