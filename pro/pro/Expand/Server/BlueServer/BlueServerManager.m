//
//  BlueServerManager.m
//  pro
//
//  Created by Xiaowz on 16/9/26.
//  Copyright © 2016年 huaxia. All rights reserved.
//

#import "BlueServerManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "MainMacos.h"

#import "CMDModel.h"


static BlueServerManager *_instance;
static NSString *const name = @"SH-HC-08";

@interface BlueServerManager()<CBCentralManagerDelegate, CBPeripheralDelegate> {
    
    
}
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) NSMutableArray<CBPeripheral *> *peripherals;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;
@end

@implementation BlueServerManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [BlueServerManager new];
    });
    return _instance;
}

- (void)startScan {
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
}

- (void)stopScan {
    [_manager stopScan];
}

- (void)connectPeripheral: (CBPeripheral *)peripheral {
   
//    if (!peripheral) {
////        [UIAlertController alertControllerWithTitle:@"tip" message:@"此设备不存在" preferredStyle:UIAlertControllerStyleAlert];
//    }
//    if (!([peripheral.name isEqualToString:name])) {
////        [UIAlertController alertControllerWithTitle:@"tip" message:@"此设备不匹配" preferredStyle:UIAlertControllerStyleAlert];
//    }
       _peripheral = peripheral;
        _peripheral.delegate = self;
        [self connect:peripheral];
}

- (void)disconnectPeripheral {
    if (!_peripheral) {
        return;
    }
    [_manager cancelPeripheralConnection:_peripheral];
}
- (void)sendData: (NSData *)data {
    if (!_peripheral) {
        return;
    }
    if (!_characteristic) {
        return;
    }
    [_peripheral writeValue:data forCharacteristic:_characteristic type:CBCharacteristicWriteWithoutResponse];
    
    //NSLog(@"send data");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kBluServerSendData" object:nil userInfo:@{@"data": data}];
    
    
    
//    [_peripheral readValueForCharacteristic:_characteristic];
}


#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"%ld",(long)central.state);
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [_manager scanForPeripheralsWithServices:nil options:nil];
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if (!peripheral) {
        return;
    }
   
    if (self.peripherals.count > 0) {
        if (![self isContain:peripheral]) {
            [_peripherals addObject:peripheral];
        }
        
    }
    else {
        [_peripherals addObject:peripheral];
    }
    NSLog(@"能发现设备:%@",peripheral.name);
    [_delegate blueServerManager:self didDiscoverPeripherals:[_peripherals copy]];
 //   _peripheral = peripheral;
//    _peripheral.delegate = self;
//    [self connect:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    if (!peripheral) {
        return;
    }
    if (peripheral != _peripheral) {
        return;
    }
    [_manager stopScan];
    [_peripheral discoverServices:nil];
    _peripheral.delegate = self;
    NSLog(@"connect successful");
    [_delegate blueServerManager:self didConnectedPeripheral:peripheral];

    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSData *data = [[CMDModel sharedInstance] queryCMD];
//        [self sendData1:data];
//    });
    
}

- (void)sendQueryData: (NSData *)data {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendData1:data];
    });
}

- (void)sendData1: (NSData *)data {
   // NSLog(@"sdfsa");
    if (!_peripheral) {
        return;
    }
    if (!_characteristic) {
        return;
    }
    [_peripheral writeValue:data forCharacteristic:_characteristic type:CBCharacteristicWriteWithoutResponse];
    
   // [[NSNotificationCenter defaultCenter] postNotificationName:@"kBluServerSendData" object:nil userInfo:@{@"data": data}];
    [_peripheral readValueForCharacteristic:_characteristic];
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:isConnectted];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _peripherals = nil;
    _manager = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BluServerDidDisconnected" object:nil userInfo:nil];
   
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if (peripheral != _peripheral) {
        return;
    }
    if (error) {
        return;
    }
    NSArray<CBService *> *services;
    services = peripheral.services;
    if (!(services && services.count > 0)) {
        return;
    }
    [services enumerateObjectsUsingBlock:^(CBService * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [peripheral discoverCharacteristics:nil forService:obj];
        
    }];
    
}
#pragma  mark - 回调方法 —— 订阅状态改变
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"%@",error);
        return;
    }
//    NSLog(@"使能通知完成,开始写入数据");
//    NSLog(@"peripheral :%@",peripheral);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        return;
    }
    NSArray<CBCharacteristic *> *characteristics;
    characteristics = service.characteristics;
    if (!(characteristics && characteristics.count > 0)) {
        return;
    }
    //NSLog(@"service:%@",service.UUID.UUIDString);
    
    [characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [_peripheral setNotifyValue:YES forCharacteristic:obj];
//        NSLog(@"characteristic:%@",obj.UUID.UUIDString);
//        if (idx == 2) {
//            _characteristic = characteristics[5];
//        }
       // [_peripheral setNotifyValue:YES forCharacteristic:obj];
        if ([service.UUID.UUIDString isEqualToString:@"FFE0"] && [obj.UUID.UUIDString isEqualToString:@"FFE1"]) {
            self.characteristic = obj;
            [_peripheral setNotifyValue:YES forCharacteristic:obj];
        }
    }];
    
//        for (CBCharacteristic *characteristic in service.characteristics) {
//            
////            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE0"]]) {
//                //开启订阅
//                CBUUID *sUUID = [CBUUID UUIDWithString:@"FFE0"];
//                CBUUID *cUUID = [CBUUID UUIDWithString:@"FFE1"];
//                [BLEUtility setNotificationForCharacteristic:peripheral sCBUUID:sUUID cCBUUID:cUUID enable:YES];
//            
//                NSLog(@"%@",characteristic);
////            }
//        }

    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        return;
    }
    NSData *data = characteristic.value;
    Byte result[20] = {0x00};
    [data getBytes:&result length:data.length];
//    NSLog(@"%s",result);
    NSLog(@" %@",characteristic.value);

    if (data.length == 6 && !(result[0] == 0xea && result[1] == 0x0a)) {
//        for(int i = 0; i < data.length; i++) {
//            NSLog(@"%d",result[i]);
//        }
        [_delegate blueServerManager:self didSendQueryData:result];
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //NSLog(@"%@",characteristic.value);
    
    
}






#pragma mark - private
- (void) connect: (CBPeripheral *)periepheral {
    [_manager connectPeripheral:periepheral options:nil];
}

- (BOOL)isContain: (CBPeripheral *)peripheral {
    for (CBPeripheral *obj in self.peripherals) {
        if ([obj.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - getter

- (NSMutableArray<CBPeripheral *> *)peripherals {
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

#pragma mark - setter


- (void)setCharacteristic:(CBCharacteristic *)characteristic {
    _characteristic = characteristic;
//    NSData *sendData = [[CMDModel sharedInstance] singleColors][0];
//    [[BlueServerManager sharedInstance] sendData:sendData];
}

@end
