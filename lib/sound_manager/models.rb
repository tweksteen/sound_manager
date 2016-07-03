require 'sequel'

module SoundManager
  class Sound < Sequel::Model
    plugin :class_table_inheritance, :key=>:type
    many_to_many :tags, :left_key=>:sound_sha256,
                 :right_key=>:tag_id, :join_table=>:sounds_tags
    one_to_many :processed_sounds, :key=>:origin

    def self.find(ref)
      if File.exist?(ref)
        s = Sound[Digest::SHA256.file(ref).hexdigest]
        raise 'File not in the database!' if s.nil?
        return s
      else
        s = Sound.where(Sequel.ilike(:sha256, "#{ref}%"))
        if s.count > 1
          raise 'Too many matches'
        elsif s.count == 1
          s.first
        else
          raise 'Hash not found'
        end
      end
    end

    def self.search(keyword)
      Sound.where(Sequel.ilike(:name, "%#{keyword}%"))
    end

    def to_s
      "%s  %-32s  %.2fs" % [sha256[0..6], name[0..31], duration]
    end

    def show
      puts "Name: #{name}"
      puts "Hash: #{sha256}"
      puts "Path: #{path}"
      puts "Type: #{type}"
    end

    def abs_path
      File.join(SOUND_LIBRARY_PATH, path)
    end

    def play
      %x[sox #{abs_path} -d]
    end

    def edit
      %x[audacity #{abs_path} 2>/dev/null]
    end

    def stats
      %x[sox #{abs_path} -n stats 2>&1]
    end
  end

  class RawSound < Sound

    def self.search(keyword)
      qs = RawSound.where(Sequel.ilike(:location, "%#{keyword}%"))
      #qs = qs.exclude(Sequel.ilike(:name, "%#{keyword}%"))
      qs
    end

    def to_s
      d = "%.2fs" % duration
      "%s  %-32s  %7s  %s" %
       [sha256[0..6], name[0..31], d,
        recorded_at.strftime("%Y-%m-%d %H:%M:%S")]
    end

    def show
      super
      puts "Recorded at: #{recorded_at}"
      puts "Location: #{location}"
    end
  end

  class ProcessedSound < Sound
    many_to_one :origin, :key=>:origin_sha256, :class=>Sound

    def to_s
      d = "%.2fs" % duration
      "%s  %-32s  %7s  %s" %
       [sha256[0..6], name[0..31], d,
        tags.collect(&:name).join(",")
       ]
    end

    def show
      super
      puts "Origin: #{origin_sha256}"
    end
  end

  class Tag < Sequel::Model
    many_to_many :sounds, :right_key=>:sound_sha256,
                 :left_key=>:tag_id, :join_table=>:sounds_tags
  end
end
