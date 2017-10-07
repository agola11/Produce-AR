//
//  BluetoothManager.m
//  Produce-AR
//
//  Created by Ankush Gola on 10/7/17.
//  Adapted from the swift library "SimpleBluetoothIO" by nebs
//  (https://github.com/nebs/hello-bluetooth)
//  Copyright © 2017 Ankush Gola. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

#import "BluetoothManager.h"

@interface BluetoothManager () <CBCentralManagerDelegate, CBPeripheralDelegate>
@end

@implementation BluetoothManager
{
    NSString *_serviceUUID;
    __weak id<BlueToothManagerDelegate> _blueToothManagerDelegate;
    
    CBCentralManager *_centralManager;
    CBPeripheral *_peripheral;
    CBService *_targetService;
    CBCharacteristic *_writableCharacteristic;
}

- (instancetype)initWithServiceUUID:(NSString *)serviceUUID
           bluetoothManagerDelegate:(id<BlueToothManagerDelegate>)delegate
                              queue:(dispatch_queue_t)queue
{
    if (self = [super init]) {
        _serviceUUID = serviceUUID;
        _blueToothManagerDelegate = delegate;

        _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:queue];
    }
    return self;
}

- (void)writeValue:(NSData *)value
{
    if (!_peripheral || !_writableCharacteristic) {
        return;
    }
    
    if (value) {
        [_peripheral writeValue:value
              forCharacteristic:_writableCharacteristic
                           type:CBCharacteristicWriteWithResponse];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    if ([peripheral.name isEqualToString:@"Adafruit Bluefruit LE"]) {
        _peripheral = peripheral;
        _peripheral.delegate = self;
        [_centralManager connectPeripheral:_peripheral
                                   options:nil];
        [_centralManager stopScan];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBManagerStatePoweredOn) {
        CBUUID *uuid = [CBUUID UUIDWithString:_serviceUUID];
        (void)uuid;
        [_centralManager scanForPeripheralsWithServices:nil
                                                options:nil];
    }
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    if (!peripheral.services) {
        return;
    }
//    CBService *topService = peripheral.services[0];
//    if (topService) {
//        _targetService = topService;
//        [peripheral discoverCharacteristics:nil
//                                 forService:topService];
//    }
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (!service.characteristics) {
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if (characteristic.properties & CBCharacteristicPropertyWrite ||
            characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse)
        {
            _writableCharacteristic = characteristic;
        }
        [peripheral setNotifyValue:YES
                 forCharacteristic:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic
             error:(nullable NSError *)error
{
    if (characteristic.value) {
        [_blueToothManagerDelegate didReceiveValueFromBluetoothPeripheral:characteristic.value];
    }
}

@end
