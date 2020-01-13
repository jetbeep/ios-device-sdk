//
//  DemoViewController.swift
//  JetBeepDeviceSDKDemo
//
//  Created by Max Tymchii on 11.01.2020.
//  Copyright © 2020 JetBeep. All rights reserved.
//

import Foundation
import UIKit
import JetBeepDeviceSDK

/*
Don't forget at yours project
NSBluetoothPeripheralUsageDescription < iOS 13
NSBluetoothAlwaysUsageDescription iOS 13 and later
 
deviceChipID value you can find on demo panel
merchantSecretKey gonna be provided after contact with our sales managers.
 */

final class DemoViewController: UIViewController {
  
    private var deviceChipID = ""
    private var merchantSecretKey = ""
    
    @IBOutlet private weak var logs: UITextView!
    private var gatt: Advertiser?
    private var subscriptionID = defaultEventSubscribeID
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configUI()
        configSettings()
        startAdvertising()
        
    }
    
    private func configSettings() {
        Storage.shared.chipID = deviceChipID
        Storage.shared.merchantSecretKey = merchantSecretKey
    }
    
    private func startAdvertising() {
        if !Storage.shared.chipID.isChipIDValid {
            Log.e("Chip id is is not valid!")
            return
        }
        
        if Storage.shared.merchantSecretKey.isEmpty || Storage.shared.merchantSecretKey.count == 0 {
            Log.e("Merchant secret key is not valid!")
            return
        }
        
        gatt = Advertiser()
        do {
            try gatt?.start()
            subscriptionID = gatt!.subscribe { [weak self] event in
                self?.updateStateEvent(event)
            }
        } catch let  error {
            Log.e(error)
        }
    }
    
    private func configUI() {
        Log.logCompletion = { [weak self] log in
            var messages = self?.logs.text
            messages?.append(contentsOf: (log ?? "") + "\n")
            self?.logs.text = messages
        }
    }
    
    private func unsubscribe() {
        gatt?.unsubscribe(subscriptionID)
        do {
            try gatt?.stop()
        } catch let error {
            Log.e(error)
        }
    }
    
    private func updateStateEvent(_ info: DeviceInfo) {
        switch info.event {
        case .bluetoothTurnedOff:
            Log.e("Please tur on bluetooth")
        case .connectionEstablished:
            Log.i("Connection established")
        case .createPayment:
            Log.i("CreatePayment")
            Log.i("Data:\(info.data.toHexString())")
        case .dissconnect:
            Log.i("Dissconnect")
        case .openSession:
            Log.i("Open session")
        case .closeSession:
            Log.i("Close session")
        case .confirmPayment:
            Log.i("Confirm payment")
        case .paymentSuccessful:
            Log.i("Payment successful")
            gatt?.send(DeviceEvent.confirmPayment)
        case .createPaymentToken:
            Log.i("Create Payment Token")
            
            if info.status == .error {
                Log.e("Status \(info.status.textRepresentation)")
            }
            
        case .cancelPayment:
            Log.i("Cancel payments")
        case .paymentToken:
            Log.i("Payment token")
            Log.i("Data:\(info.data.toHexString())")
            Log.i("Status: \(info.status.textRepresentation)")
        //Call payment process
        case .mobileConnected:
            Log.i("Mobile connected")
        case .subscribeOnCharacteristics:
            Log.i("Device have found us.")
            gatt?.send(DeviceEvent.openSession)
        case .unsubscribeOnCharacteristics:
            Log.v("unsubscribeOnCharacteristics")
            unsubscribe()
        case .paymentFailure(let error):
            Log.e("Payment failure: \(error)")
        }
    }
    
    @IBAction func tapOnPayButton(_ sender: Any) {
        /// Amount type - coins // 1 - 1 coin
        let amount = 1
        let merchantTransactionId = generateMerchantTransactionId()
        let commandTail = " \(amount) \(merchantTransactionId) \(Storage.shared.cashierID)"
        gatt?.send(DeviceEvent.createPaymentToken, with: commandTail)
        
        /*
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
        */
    }
    
    /// MerchantTransactionId
    private func generateMerchantTransactionId() -> String {
        var uuid = UUID().uuidString
        uuid.removeAll { $0 == "-"}
        return uuid
    }
    
    
}
