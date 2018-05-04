require 'sequel'

module SoundManager
  # Adapter to handle the database interactions.
  class DBAdapter
    def create_sounds_table
      @db.create_table?(:sounds) do
        String   :sha256, primary_key: true
        String   :name
        String   :path
        String   :type
        Float    :duration
      end
    end

    def create_raw_sounds_table
      @db.create_table?(:raw_sounds) do
        foreign_key :sha256, :sounds, null: false, type: String
        DateTime :recorded_at
        String   :location, text: true
      end
    end

    def create_processed_sounds_table
      @db.create_table?(:processed_sounds) do
        foreign_key :sha256, :sounds, null: false, type: String
        Float       :intensity
        foreign_key :origin_sha256, :sounds, null: false, type: String
      end
    end

    def create_tags_table
      @db.create_table?(:tags) do
        primary_key  :id
        String       :name
      end
      @db.create_table?(:sounds_tags) do
        foreign_key :sound_sha256, :sounds, type: String
        foreign_key :tag_id, :tags
        primary_key %i[sound_sha256 tag_id]
        index %i[sound_sha256 tag_id]
      end
    end

    def create_tables
      create_sounds_table
      create_raw_sounds_table
      create_processed_sounds_table
      create_tags_table
    end

    def initialize(library_path, filename='sounds.sqlite')
      if filename.nil?
        @db = Sequel.sqlite
      else
        @db = Sequel.sqlite(File.join(library_path, filename))
      end
      create_tables
      require 'sound_manager/models'
    end
  end
end
