# Définir la version minimale d'iOS
platform :ios, '13.0'

# Utiliser une installation standard de CocoaPods
install! 'cocoapods'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Ajouter manuellement les dépendances Firebase
  pod 'Firebase/Core'
  pod 'Firebase/Firestore'
  # Ajouter d'autres pods si nécessaire
end

# Post-installation pour ajuster les configurations
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end