platform :ios, '18.0'

target 'FillarGym' do
  use_frameworks!
  
  # Firebase Analytics追加
  pod 'FirebaseCore'
  pod 'FirebaseAnalytics'
  
  target 'FillarGymTests' do
    inherit! :search_paths
  end

  target 'FillarGymUITests' do
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
    end
  end
end