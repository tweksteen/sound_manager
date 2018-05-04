require 'tmpdir'
require 'test/unit'

require 'sound_manager'

class ControllerTest < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir
    @tmpdb = SoundManager::DBAdapter.new(@tmpdir, filename=nil)
    @controller = SoundManager::Controller.new(@tmpdir, @tmpdb)
    location = File.dirname(__FILE__)
    @test_file = File.join(location, 'test.wav')
  end

  def teardown
    FileUtils.remove_entry_secure @tmpdir
  end
  
  def test_empty_ls
    @controller.parse(['ls'])
  end

  def test_add_wav
    f = File.join(@tmpdir, '180101-123456.wav')
    FileUtils.cp(@test_file, f)
    @controller.parse(['add', f, 'My sound', 'Zurich'])
  end
end
