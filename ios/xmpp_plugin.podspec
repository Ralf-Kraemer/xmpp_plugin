Pod::Spec.new do |s|
  s.name             = 'xmpp_plugin'
  s.version          = '2.2.13'
  s.summary          = 'Flutter plugin for XMPP using native libraries on Android and iOS.'
  s.description      = <<-DESC
    A Flutter plugin that enables XMPP communication using native libraries.
    Android uses Smack, iOS uses XMPPFramework (Swift).
  DESC
  s.homepage         = 'https://github.com/Ralf-Kraemer/xmpp_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'hello@ralfkraemer.eu' }
  s.source           = { :path => '.' }

  # Source files for iOS plugin
  s.source_files     = 'Classes/**/*.{h,m,swift}'
  s.public_header_files = 'Classes/**/*.h'

  # Dependencies
  s.dependency 'Flutter'
  s.dependency 'XMPPFramework/Swift'

  # iOS platform and Swift version
  s.platform         = :ios, '11.0'
  s.swift_version    = '5.0'

  # Module and simulator configuration
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  # Allow modular headers for Swift integration
  s.prepare_command = <<-CMD
    echo "Preparing xmpp_plugin for Swift and Flutter integration"
  CMD
end
