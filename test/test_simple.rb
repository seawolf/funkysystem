require 'test/unit'
require 'funkysystem'

class TestFunkySystem < Test::Unit::TestCase
  def test_bc
    prg = FunkySystem.run(["bc"], "3+2\n4+23\nquit")
    assert ! prg.error?
    assert_equal "5\n27\n", prg.stdout
    #p prg, prg.error?
  end
  def test_false
    assert FunkySystem.run(['false']).error?
  end
  def test_true
    assert ! FunkySystem.run(['true']).error?
  end
end
