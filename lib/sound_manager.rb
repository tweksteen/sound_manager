require 'rubygems'
require 'time'
require 'sequel'
require 'digest'
require 'waveinfo'
WaveInfo.debug = false

require 'sound_manager/db_adapter'

module SoundManager
  # High-level manager to handle commands.
  class Controller
    COMMANDS = { add: :add_raw, edit: :edit, info: :info, link: :link,
                 ls: :list, play: :play, rename: :rename, 
                 search: :search, stats: :stats, tag: :tag }.freeze
    # Returns the relative path of the file within the library.
    def relative_path(filename)
      abs_path = File.absolute_path(filename)
      unless File.exist?(abs_path)
        raise 'File not found'
      end
      unless abs_path.include? @library_path
        raise 'File not in the library folder'
      end
      File.join('.', abs_path.gsub(@library_path, ''))
    end

    def add_raw(argv)
      if argv.length != 3
        puts 'usage: sm.rb add <raw.wav> <name> <location>'
        return
      end
      filename, name, location = argv
      r = RawSound.new
      r.path = relative_path(filename)
      r.sha256 = Digest::SHA256.file(filename).hexdigest
      r.name = name
      r.duration = WaveInfo.new(filename).duration
      r.location = location
      begin
        d = File.basename(filename).gsub(/.wav/i, '')
        r.recorded_at = Time.strptime(d, '%y%m%d-%H%M%S')
      rescue ArgumentError
        puts 'Unable to parse the date in filename'
        raise
      end
      begin
        r.save
      rescue Sequel::UniqueConstraintViolation
        puts 'This sample is already in the database!'
      end
    end

    def edit(argv)
      if argv.length != 1
        puts 'usage: sm.rb edit <hash|filename>'
        return
      end
      Sound.find(argv.first).edit(@library_path)
    end

    def info(argv)
      if argv.length != 1
        puts 'usage: sm.rb info <hash|filename>'
        return
      end
      puts Sound.find(argv.first).info
    end

    def link(argv)
      if argv.length != 3
        puts 'usage: sm.rb link <processed.wav> <hash|raw.wav> <name>'
        return
      end
      processed_filename, raw_ref, name = argv
      rs = Sound.find raw_ref
      ps = ProcessedSound.new
      ps.path = relative_path(filename)
      ps.sha256 = Digest::SHA256.file(processed_filename).hexdigest
      ps.origin = rs
      ps.duration = WaveInfo.new(processed_filename).duration
      ps.name = name
      ps.save
    end

    def list(argv)
      if argv.length > 1
        puts 'usage: sm.rb list [expression]'
        return
      elsif argv.length == 1
        ds = Sound.where(Sequel.ilike(:name, argv.first))
      else
        ds = Sound
      end
      ds.order(:name).each { |s| puts s }
    end

    def play(argv)
      if argv.length != 1
        puts 'usage: sm.rb play <hash>'
        return
      end
      Sound.find(argv.first).play(@library_path)
    end

    def tag(argv)
      if argv.length < 2
        puts 'usage: sm.rb tag <hash|filename> <tag1> [<tag2>...]'
        return
      end
      ref = argv.shift
      s = Sound.find ref
      tags.each do |tag|
        t = Tag.find_or_create(name: tag)
        s.add_tag(t)
      end
    end

    def rename(argv)
      if argv.length != 2
        puts 'usage: sm.rb rename <hash|filename> <new name>'
        return
      end
      ref, new_name = argv
      s = Sound.find ref
      s.name = new_name
      s.save
    end

    def search(argv)
      if argv.length != 1
        puts 'usage: sm.rb search <keyword>'
        return
      end
      keyword = argv
      qs = Sound.search(keyword)
      qrs = RawSound.search(keyword).select(*Sound.columns)
      puts qs.union(qrs).order(:name).all
    end

    def stats(argv)
      if argv.length != 1
        puts 'usage: sm.rb stats <hash|filename>'
        return
      end
      puts Sound.find(argv.first).stats(@library_path)
    end

    def parse(argv)
      command = argv.shift
      unless command.nil?
        cf = COMMANDS[command.to_sym]
        unless cf.nil?
          send(cf, argv)
          return
        end
      end
      puts "usage: sm.rb <#{COMMANDS.keys.join('|')}>"
    end

    def initialize(library_path, db)
      @library_path = library_path
      @db = db
    end

    def self.build(library_path)
      db = DBAdapter.new(library_path)
      Controller.new(library_path, db)
    end
  end
end
