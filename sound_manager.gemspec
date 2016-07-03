Gem::Specification.new do |s|
  s.name        = 'sound_manager'
  s.version     = '0.0.1'
  s.date        = '2016-01-03'
  s.summary     = "A tool to manage sounds"
  s.authors     = ["Thiébaud Weksteen"]
  s.email       = 'thiebaud@weksteen.fr'
  s.files       = ["lib/sound_manager.rb",] +
                  Dir["lib/sound_manager/*.rb"]
  s.executables << 'sm'
  s.homepage    = 'https://github.com/tweksteen/sound_manager'
  s.license     = 'MIT'
  s.add_runtime_dependency 'sequel'
  s.add_runtime_dependency 'sqlite3'
  s.add_runtime_dependency 'waveinfo'
end
