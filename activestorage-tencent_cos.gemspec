Gem::Specification.new do |s|
  s.name        = 'activestorage-tencent_cos'
  s.version     = '0.0.2'
  s.summary     = 'Active Storage Serivce for Tencent COS'

  s.author      = 'Bin Xin'
  s.homepage    = 'https://github.com/YIIZ/activestorage-tencent_cos'
  s.license     = 'MIT'

  s.files        = Dir['README.md', 'lib/**/*']
  s.require_path = 'lib'

  s.add_dependency 'activestorage', '~> 5.2'
end
