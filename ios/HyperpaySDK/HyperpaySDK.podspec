Pod::Spec.new do |s|
  s.name                = 'HyperpaySDK'
  s.version             = '7.11.0'
  s.summary             = 'HyperPay mSDK vendored frameworks (OPPWAMobile + ipworks 3DS).'
  s.homepage            = 'https://wordpresshyperpay.docs.oppwa.com/'
  s.license             = { :type => 'Commercial', :text => 'HyperPay merchant license' }
  s.author              = 'HyperPay'
  s.source              = { :path => '.' }
  s.platform            = :ios, '13.0'
  s.vendored_frameworks = 'OPPWAMobile.xcframework', 'ipworks3ds_sdk.xcframework'
end
