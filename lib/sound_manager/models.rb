require 'sequel'

module SoundManager
  # The base class for all type of sounds
  class Sound < Sequel::Model
    plugin :class_table_inheritance, key: :type
    many_to_many :tags, left_key: :sound_sha256, right_key: :tag_id,
                        join_table: :sounds_tags
    one_to_many :processed_sounds, key: :origin

    # Find a sound by either its file or its digest value.
    def self.find(ref)
      if File.exist?(ref)
        s = Sound[Digest::SHA256.file(ref).hexdigest]
        raise 'File not in the database!' if s.nil?
        return s
      end
      s = Sound.where(Sequel.ilike(:sha256, "#{ref}%"))
      raise 'Too many matches' if s.count > 1
      raise 'Hash not found' if s.count.zero?
      s.first
    end

    def self.search(keyword)
      Sound.where(Sequel.ilike(:name, "%#{keyword}%"))
           .or(tags: Tag.where(name: keyword))
    end

    def short_sha
      sha256[0..6]
    end

    def short_name
      name[0..31]
    end

    def to_s
      d = format('%.2fs', duration)
      format('%s  %-32s  %7s', short_sha, short_name, d)
    end

    def info
      tag_s = tags.collect(&:name).join(', ')
      ["Name: #{name}", "Hash: #{sha256}",
       "Path: #{path}", "Type: #{type}",
       "Tags: #{tag_s}"].join("\n")
    end

    def abs_path(library_path)
      File.join(library_path, path)
    end

    # Plays a sound directly using Sox. If an interrupt is raised,
    # we make sure Sox has time to reset the terminal in a sane mode.
    def play(library_path)
      pid = spawn("sox #{abs_path(library_path)} -d")
      Process.wait pid
    rescue Interrupt
      Process.wait pid
    end

    def edit(library_path)
      `audacity #{abs_path(library_path)} 2>/dev/null`
    end

    def stats(library_path)
      `sox #{abs_path(library_path)} -n stats 2>&1`
    end
  end

  # Raw sound, directly from a capture.
  class RawSound < Sound
    def self.search(keyword)
      RawSound.where(Sequel.ilike(:location, "%#{keyword}%"))
    end

    def to_s
      d = format('%.2fs', duration)
      format('%s  %-32s  %7s  %s', short_sha, short_name, d,
             recorded_at.strftime('%Y-%m-%d %H:%M:%S'))
    end

    def info
      [super, "Recorded at: #{recorded_at}",
       "Location: #{location}"].join("\n")
    end
  end

  # Processed sounds, reference a raw sound.
  class ProcessedSound < Sound
    many_to_one :origin, key: :origin_sha256, class: Sound
    def to_s
      d = format('%.2fs', duration)
      format('%s  %-32s  %7s  %s', short_sha, short_name, d,
             tags.collect(&:name).join(','))
    end

    def info
      [super, "Origin: #{origin_sha256}"].join("\n")
    end
  end

  # Tag associated with a sound. May contain an arbitrary string.
  class Tag < Sequel::Model
    many_to_many :sounds, right_key: :sound_sha256, left_key: :tag_id,
                          join_table: :sounds_tags
  end
end
