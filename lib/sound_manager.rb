require 'rubygems'
require 'time'
require 'sequel'
require 'digest'
require 'waveinfo'
WaveInfo.debug = false

require 'sound_manager/config'

module SoundManager

  def create_tables(db)
    db.create_table?(:sounds) do
      String   :sha256, :primary_key=>true
      String   :name
      String   :path
      String   :type
      Float    :duration
    end
    db.create_table?(:raw_sounds) do
      foreign_key :sha256, :sounds, :null=>false, :type=>String
      DateTime :recorded_at
      String   :location, :text=>true
    end
    db.create_table?(:processed_sounds) do
      foreign_key :sha256, :sounds, :null=>false, :type=>String
      Float    :intensity
      foreign_key :origin_sha256, :sounds, :null=>false, :type=>String
    end
    db.create_table?(:tags) do
      primary_key  :id
      String   :name
    end
    db.create_table?(:sounds_tags) do
      foreign_key :sound_sha256, :sounds, :type=>String
      foreign_key :tag_id, :tags
      primary_key [:sound_sha256, :tag_id]
      index [:sound_sha256, :tag_id]
    end
  end

  def init_db
    db = Sequel.sqlite(File.join(SOUND_LIBRARY_PATH, 'sounds.sqlite'))
    create_tables(db)
    require 'sound_manager/models'
  end

  def add_raw(filename, name, location)
    abs_path = File.absolute_path(filename)
    if not File.exist?(abs_path)
      raise 'File not found'
    end
    if not abs_path.include? SOUND_LIBRARY_PATH
      raise 'File not in the library folder'
    end
    r = RawSound.new
    r.sha256 = Digest::SHA256.file(filename).hexdigest
    r.name = name
    r.duration = WaveInfo.new(filename).duration
    r.path = File.join(".", abs_path.gsub(SOUND_LIBRARY_PATH, ''))
    begin
      d = File.basename(filename).gsub(/.wav/i, "")
      r.recorded_at = Time.strptime(d, '%y%m%d-%H%M%S')
    rescue ArgumentError
      puts 'Unable to parse the date'
      raise
    end
    r.location = location
    r.save
  end

  def link(processed_filename, raw_ref, name)
    rs = Sound.find raw_ref
    abs_path = File.absolute_path(processed_filename)
    if not File.exist?(abs_path)
      raise 'File not found'
    end
    if not abs_path.include? SOUND_LIBRARY_PATH
      raise 'File not in the library folder'
    end
    ps = ProcessedSound.new
    ps.sha256 = Digest::SHA256.file(processed_filename).hexdigest
    ps.origin = rs
    ps.duration = WaveInfo.new(processed_filename).duration
    ps.name = name
    ps.path = File.join(".", abs_path.gsub(SOUND_LIBRARY_PATH, ''))
    ps.save
  end

  def tag(ref, tags)
    s = Sound.find ref
    tags.each do |tag|
      t = Tag.find_or_create(:name => tag)
      s.add_tag(t)
    end
  end

  def rename(ref, new_name)
    s = Sound.find ref
    s.name = new_name
    s.save
  end

  def search(keyword)
    qs = Sound.search(keyword)
    #qrs = RawSound.search(keyword).select_all(:sounds)
    #puts qs.union(qrs).order(:name).all
    puts qs.order(:name).all
  end

  def main
    init_db
    command = ARGV.shift
    case command
    when 'add'
      if ARGV.length != 3
        puts 'usage: sm.rb add <raw.wav> <name> <location>'
      else
        begin
          add_raw *ARGV
        rescue Sequel::UniqueConstraintViolation
          puts 'This sample is already in the database!'
        end
      end
    when 'edit'
      Sound.find(ARGV.first).edit
    when 'link'
      if ARGV.length != 3
        puts 'usage: sm.rb link <processed.wav> <hash|raw.wav> <name>'
      else
        link *ARGV
      end
    when 'ls', 'list'
      if ARGV.length > 1
        puts 'usage: sm.rb list [regex]'
      elsif ARGV.length == 1
        ds = Sound.where(Sequel.ilike(:name, ARGV.first))
      else
        ds = Sound
      end
      ds.order(:name).each { |s| puts s }
    when 'play'
      if ARGV.length != 1
        puts 'usage: sm.rb play <hash>'
      else
        Sound.find(ARGV.first).play
      end
    when 'rename'
      if ARGV.length != 2
        puts 'usage: sm.rb rename <hash|filename> <new name>'
      else
        rename *ARGV
      end
    when 'search'
      if ARGV.length != 1
        puts 'usage: sm.rb search <keyword>'
      else
        search *ARGV
      end
    when 'show'
      if ARGV.length != 1
        puts 'usage: sm.rb show <hash|filename>'
      else
        Sound.find(ARGV.first).show
      end
    when 'stats'
      puts Sound.find(ARGV.first).stats
    when 'tag'
      if ARGV.length < 2
        puts 'usage: sm.rb tag <hash|filename> <tag1> [<tag2>...]'
      else
        ref = ARGV.shift
        tag(ref, ARGV)
      end
    else
      puts 'usage: sm.rb <add|edit|link|ls|play|rename|search|show|stats|tag>'
    end
  end
end
