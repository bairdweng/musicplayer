//
//  BlueServerManager.h
//  pro
//
//  Created by Xiaowz on 16/9/26.
//  Copyright © 2016年 huaxia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class BlueServerManager;
@class CBPeripheral;
@protocol BlueServerManagerDelegate <NSObject>
@optional
- (void)blueServerManager: (BlueServerManager *)manager didDiscoverPeripherals: (NSArray <CBPeripheral *> *)peripherals;

- (void)blueServerManager: (BlueServerManager *)manager didConnectedPeripheral: (CBPeripheral *)peripheral;
- (void)blueServerManager: (BlueServerManager *)manager didSendQueryData: (Byte[])bytes;

@end

@interface BlueServerManager : NSObject
@property (nonatomic, weak) id<BlueServerManagerDelegate> delegate;
@property(nonatomic,strong)CBPeripheral *currentPeripheral;
@property (nonatomic, strong)CBCharacteristic *currentcharacteristic;


+ (instancetype)sharedInstance;
- (void)startScan;
- (void)stopScan;
- (void)connectPeripheral: (CBPeripheral *)peripheral;
- (void)disconnectPeripheral;
- (void)sendData: (NSData *)data;
- (void)sendQueryData: (NSData *)data;
@end
