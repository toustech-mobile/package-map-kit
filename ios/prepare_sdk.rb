# CocoaPods uses Flutter plugins as local pods, so prepare_command is skipped.
# Download the official binary before CocoaPods resolves vendored_frameworks.
require 'digest'
require 'fileutils'
require 'tmpdir'

module MapKitNeshanSDK
  VERSION = '6.28.0'.freeze
  URL = "https://static.neshan.org/sdk/maplibre/ios/MapLibre-#{VERSION}.zip".freeze
  SHA256 = 'd93047723546fa76a8936095dda76b5b405ae8262c8cb7eb4d7b339ca9617845'.freeze

  def self.prepare!
    destination = File.join(__dir__, 'Frameworks')
    framework = File.join(destination, 'MapLibre.xcframework')
    stamp = File.join(destination, 'sdk.sha256')
    FileUtils.mkdir_p(destination)
    File.open(File.join(destination, '.download.lock'), 'w') do |lock|
      lock.flock(File::LOCK_EX)
      return if File.file?(File.join(framework, 'Info.plist')) &&
                File.file?(stamp) && File.read(stamp).strip == SHA256

      Dir.mktmpdir('neshan-', destination) do |staging|
        archive = File.join(staging, 'MapLibre.zip')
        puts "map_kit: downloading Neshan MapLibre #{VERSION}"
        unless system('curl', '--fail', '--location', '--retry', '2', '--silent', '--show-error',
                      URL, '--output', archive)
          raise 'map_kit: Neshan SDK download failed; check network access to static.neshan.org'
        end
        unless Digest::SHA256.file(archive).hexdigest == SHA256
          raise 'map_kit: Neshan SDK checksum mismatch; refusing to use the downloaded binary'
        end
        raise 'map_kit: SDK extraction failed' unless system('unzip', '-q', archive, '-d', staging)
        extracted = File.join(staging, 'MapLibre.xcframework')
        raise 'map_kit: archive has no MapLibre.xcframework' unless File.file?(File.join(extracted, 'Info.plist'))

        FileUtils.rm_rf(framework)
        FileUtils.mv(extracted, framework)
        File.write(stamp, SHA256 + "\n")
      end
    end
  end
end

MapKitNeshanSDK.prepare! if $PROGRAM_NAME == __FILE__
