require 'test/unit'
require_relative '../src/app_model'

class AppModelTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @model = AppModel.new(nil, nil)
  end

  def test_update_turn
    assert_equal(AppModel::PLAYER_1_TURN, @model.state[:turn])
    @model.update_turn(AppModel::PLAYER_2_TURN)
    assert_equal(AppModel::PLAYER_2_TURN, @model.state[:turn])
  end

  def test_update_type
    assert_equal(AppModel::CONNECT_4, @model.state[:type])
    @model.update_game_type(AppModel::TOOT_AND_OTTO)
    assert_equal(AppModel::TOOT_AND_OTTO, @model.state[:type])
  end

  def test_update_mode
    assert_equal(AppModel::PLAYER_PLAYER, @model.state[:mode])
    @model.update_game_mode(AppModel::PLAYER_CPU)
    assert_equal(AppModel::PLAYER_CPU, @model.state[:mode])
    @model.update_game_mode(AppModel::CPU_PLAYER)
    assert_equal(AppModel::CPU_PLAYER, @model.state[:mode])
  end

  def test_update_phase
    assert_equal(AppModel::MENU, @model.state[:phase])
    @model.update_game_phase(AppModel::IN_PROGRESS)
    assert_equal(AppModel::IN_PROGRESS, @model.state[:phase])
    @model.update_game_phase(AppModel::GAME_OVER)
    assert_equal(AppModel::GAME_OVER, @model.state[:phase])
  end

  def test_column_full
    6.times do
      @model.place_token(0)
    end
    assert_equal(AppModel::PLAYER_1_TURN, @model.state[:turn])
    @model.place_token(0)
    assert_equal(AppModel::PLAYER_1_TURN, @model.state[:turn])
  end

  def test_c4_vert
    3.times do
      @model.place_token(0)
      @model.place_token(1)
    end
    @model.board_place_token(0)
    assert_true(@model.connect_4_vertical?)
  end

  def test_c4_horiz
    3.times do |i|
      @model.place_token(i)
      @model.place_token(i)
    end
    @model.board_place_token(3)
    assert_true(@model.connect_4_horizontal?)
  end

  def test_c4_right_diag
    @model.place_token(0) #1
    @model.place_token(1) #2
    @model.place_token(1) #1
    @model.place_token(2) #2
    @model.place_token(3) #1
    @model.place_token(2) #2
    @model.place_token(2) #1
    @model.place_token(3) #2
    @model.place_token(3) #1
    @model.place_token(4) #2
    @model.board_place_token(3) #
    assert_true(@model.connect_4_right_diagonal?)
  end

  def test_c4_left_diag
    @model.place_token(0) #1
    @model.place_token(0) #2
    @model.place_token(0) #1
    @model.place_token(1) #2
    @model.place_token(0) #1
    @model.place_token(1) #2
    @model.place_token(1) #1
    @model.place_token(2) #2
    @model.place_token(2) #1
    @model.place_token(4) #2
    @model.board_place_token(3) #1
    assert_true(@model.connect_4_left_diagonal?)
  end

  def test_ot_horiz
    @model.place_token(0)
    @model.place_token(1)
    @model.place_token(3)
    @model.board_place_token(2)
    assert_equal(AppModel::PLAYER_1_WINS, @model.toot_and_otto_horizontal)
  end

  def test_ot_vert
    @model.place_token(0)
    @model.place_token(0)
    @model.place_token(1)
    @model.place_token(0)
    @model.board_place_token(0)
    assert_equal(AppModel::PLAYER_1_WINS, @model.toot_and_otto_vertical)
  end

  def test_ot_right_diag
    @model.place_token(0) #1
    @model.place_token(2) #2
    @model.place_token(1) #1
    @model.place_token(1) #2
    @model.place_token(2) #1
    @model.place_token(2) #2
    @model.place_token(3) #1
    @model.place_token(3) #2
    @model.place_token(3) #1
    @model.place_token(4) #2
    @model.board_place_token(3)
    assert_equal(AppModel::PLAYER_1_WINS, @model.toot_and_otto_right_diagonal)
  end

  def test_ot_left_diag
    @model.place_token(0) #1
    @model.place_token(0) #2
    @model.place_token(0) #1
    @model.place_token(1) #2
    @model.place_token(0) #1
    @model.place_token(1) #2
    @model.place_token(2) #1
    @model.place_token(1) #2
    @model.place_token(3) #1
    @model.board_place_token(2)
    assert_equal(AppModel::PLAYER_1_WINS, @model.toot_and_otto_left_diagonal)
  end
end
