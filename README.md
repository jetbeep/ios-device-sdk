# JetBeepDeviceSDK 

JetBeepDeviceSDK is a library for iOS. It's built to manage communication and payment transferring between two smartphones "Merchant" and "Client" using JetBeep device. Using this library you can create your own application to handle Merchant part. If you wanna test full flow you can install for example EasyWallet UA https://apps.apple.com/ua/app/easywallet-ua/id1234239068 it contains real "Client" implementation that we will simulate on this example of implementation.

### Installation
JetBeepDeviceSDK supports installation the library at your project via CocoaPods

### Installation with CocoaPods
[CocoaPods](http://cocoapods.org/) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like JetBeepDeviceSDK in your projects. See the ["Getting Started"](https://guides.cocoapods.org/using/getting-started.html) guide for more information. You can install it with the following command:
`gem install cocoapods`

#### Podfile
To integrate JetBeepDeviceSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

	platform :ios, '10.0'
	target 'TargetName' do
	  use_frameworks!
	  pod 'JetBeepDeviceSDK'
	end

### Usage
The best way to understand how everything work is just to open `Demo Project` that you can find on the separate folder.
If you wanna make your own project from scratch, you need to follow next steps:

1. Get a JetBeep device and secret merchant key. To do that please contact us via <oleh.hordiichuk@jetbeep.com> email.
2. Add `JetBeepDeviceSDK` to your project via CocoaPods
3. Don't forget to write `import JetBeepDeviceSDK` at file that gonna use SDK.
4. At your `Info.plist` file you need to add `NSBluetoothPeripheralUsageDescription` < iOS 13
     `NSBluetoothAlwaysUsageDescription` iOS 13 and later
5. Let's move on to code implementation.

Setup chip id that you wanna to connect with. This id you can find at our admin portal. If you need more details, please contact us via <oleh.hordiichuk@jetbeep.com> 
Secret merchant key we will provide you after signing of agreement between both sides.

	Storage.shared.chipID = deviceChipID
	Storage.shared.merchantSecretKey = merchantSecretKey

Now when you are ready, you can start to advertise an info for custom device that we specify previously using it's own chip id.

    private func startAdvertising() {
		/// 1:
           if !Storage.shared.chipID.isChipIDValid {
               return
           }
		   ///2: 
           gatt = Advertiser()
           do {
			   /// 3:
               try gatt?.start()
               subscriptionID = gatt!.subscribe { [weak self] event in
				   /// 4:
                   self?.updateStateEvent(event)
               }
           } catch let  error {
               Log.e(error)
           }
       }
       
1. Simple check if that chip id is valid
2. Create an instance of "Advertiser" that supports communication with JetBeepDevice
3. Try to start advertising info that our device is waiting for subscribers. 
4. After subscription to JetBeep device, you will start to get events that you can parse
>Don't forget to connect your device using USB

At first you need to handle `subscribeOnCharacteristics` event. After that you can send commands to JetBeep device. First of all you need to open a session:
`gatt?.send(DeviceEvent.openSession)`

>List of all events that we support during communication with device you can find at `DeviceEvent` description

After response from device with `openSession` event and status `OK` you are ready to create payment.

#### Payment creation process
	let amount = 1 //Amount that you wanna debit from client account this value should be in coins, so if you need 1$ amount should be 100
	let merchantTransactionId = generateMerchantTransactionId() //Uniq transaction ID
	let details = " \(amount) \(merchantTransactionId) \(Storage.shared.cashierID)" //detailed part of payment command specify payment parameters that we send on device
	gatt?.send(DeviceEvent.createPaymentToken, with: details)
​
	/// MerchantTransactionId
	
	    private func generateMerchantTransactionId() -> String {
	        var uuid = UUID().uuidString
	        uuid.removeAll { $0 == "-"}
	        return uuid
	    }

After this step you need to use "Client" app e.g: `EasyWallet UA` app.
Using this app you on connect it will connect to JetBeep device and you will get `mobileConnected` event after that, you can via this application and on yours "Merchant" app you'll receive `paymentToken` event. If this event with status `OK` you can parse a binary data that contains payment token, device id, signature box (binary data is one of fields that we get on event model).
To get all of that fields you can use `PaymentTokenModel`
>`let model = PaymentTokenModel(data: data)`

Next step could be send this parameters at your backend side to finish and verify this payment process.
On success scenario you should send next event on device: 

    let deviceInfo = DeviceInfo(event: .confirmPayment)
    gatt?.notify(with: deviceInfo)

On failure scenario, you should send:

	let deviceInfo = DeviceInfo(event: .paymentFailure(error), status: .error)
	gatt?.notify(with: deviceInfo)

As a result device will send to you `confirmPayment` or `paymentFailure` response events.
That's all!
Now you have a connection with device and you can make new payments, close session or open a new session with another device.
