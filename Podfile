platform :ios, '12.0'

inhibit_all_warnings!

use_frameworks!

target 'DiscoExample' do
    pod 'Disco', path: '.'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
            config.build_settings.delete 'ARCHS'
        end
    end
end
