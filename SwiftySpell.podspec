Pod::Spec.new do |s|
  s.name                      = 'SwiftySpell'
  s.version                   = "0.9.6"
  s.summary                   = 'A tool for checking spelling in Swift code.'
  s.homepage                  = 'https://github.com/YassineLafryhi/SwiftySpell'
  s.license                   = { type: 'MIT', file: 'LICENSE.txt' }
  s.author                    = { 'Yassine Lafryhi' => 'y.lafryhi@gmail.com' }
  s.source                    = { http: "https://github.com/YassineLafryhi/SwiftySpell/releases/download/0.9.6/SwiftySpell-v0.9.6.zip" }
  s.preserve_paths            = 'SwiftySpell'
  s.platforms                  = { ios: '12.0', osx: '11.0' }
  s.requires_arc              = false
end
