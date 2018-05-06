require 'tmpdir'
require 'test/unit'

require 'sound_manager'

class ControllerTest < Test::Unit::TestCase
  # Sequel does not allow multiple SQLite in-memory at the same time.
  # We create a shared directory and DB for all the tests. Its content
  # is rolled back between each test (see run method).
  def self.startup
    @@tmpdir = Dir.mktmpdir
    tmpdb = SoundManager::DBAdapter.new(@@tmpdir, filename=nil)
    @@controller = SoundManager::Controller.new(@@tmpdir, tmpdb)
  end

  def self.shutdown
    FileUtils.remove_entry_secure @@tmpdir
  end

  def setup
    location = File.dirname(__FILE__)
    @test_file = File.join(location, 'test.wav')
  end

  def run(*args, &block)
    Sequel::Model.db.transaction(:rollback=>:always, :auto_savepoint=>true){super}
  end
  
  def test_empty_ls
    @@controller.parse(%w(ls))
  end

  def test_add_wav
    f = File.join(@@tmpdir, '180101-123456.wav')
    FileUtils.cp(@test_file, f)
    @@controller.parse(%W(add #{f} My\ sound Zurich))
  end

  def test_add_non_existing
    assert_raise(RuntimeError) do
      @@controller.parse(%w(add does_not_exist My\ sound Zurich))
    end
  end
end
