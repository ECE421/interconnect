require 'observer'

# View that represents the game over screen for CLI
class CLIGameOverView
  include Observable

  def draw(winner)
    puts("Player #{winner} wins!")
    exit
  end
end
