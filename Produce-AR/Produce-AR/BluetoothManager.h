//
//  BluetoothManager.h
//  Produce-AR
//
//  Created by Ankush Gola on 10/7/17.
//  Adapted from the swift library "SimpleBluetoothIO" by nebs
//  (https://github.com/nebs/hello-bluetooth)
//  Copyright © 2017 Ankush Gola. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BlueToothManagerDelegate

// Called with BluetoothManager receives a value
- (void)didReceiveValueFromBluetoothPeripheral:(NSData *)value;

@end

@interface BluetoothManager : NSObject

- (instancetype)initWithServiceUUID:(NSString *)serviceUUID
           bluetoothManagerDelegate:(id<BlueToothManagerDelegate>)delegate
                              queue:(dispatch_queue_t)queue;

- (void)writeValue:(NSData *)value;

@end
