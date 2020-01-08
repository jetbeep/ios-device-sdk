Pod::Spec.new do |s|  
    s.name              = 'JetBeepDeviceSDK'
    s.version           = '1.0.0'
    s.summary           = 'JetBeep SDK.'
    s.homepage          = 'https://github.com/jetbeep/ios-device-sdk'

    s.author            = { "Oleh Hordiichuk" => "oleh.hordiichuk@jetbeep.com"  }
    s.license           = { :type => 'The MIT License (MIT)', :file => 'LICENSE' }
	s.source            = { :http => "https://github.com/jetbeep/ios-device-sdk/raw/master/JetBeepDeviceSDK.zip"}
    s.platform          = :ios
	s.swift_version     = '5.0'

    s.ios.deployment_target = '10.0'
    s.ios.vendored_frameworks = 'JetBeepDeviceSDK.framework'
end  