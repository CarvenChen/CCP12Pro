//
//  WoBleManager.h
//  CCBluetoothDemo
//
//  Created by CarvenChen on 2021/2/7.
//

#import <Foundation/Foundation.h>
#import "BabyBluetooth.h"
#import "WoBleHeader.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ClickRedeemBlock)(void);
typedef BOOL(^WoBleCMDFinishBloc)(void);

//static NSString *SERVICE_UDID = @"2616";
//static NSString *CHARACTERRISTIC_UDID = @"7F06";

extern NSString *SERVICE_UDID;
extern NSString *CHARACTERRISTIC_UDID;

@interface WoBleManager : NSObject

@property(nonatomic, copy) void (^findUpdateBloc)(NSArray *dataArray);
@property(nonatomic, copy) void (^connectedBloc)(CBPeripheral *peripheral);
@property(nonatomic, copy) void (^disConnectBloc)(CBPeripheral *peripheral);

@property(nonatomic, strong) NSMutableArray *dataArray;

+ (instancetype)shareInstance;

- (void)scanPeripherals;
- (void)stopScan;
- (void)closeCurrentConnect;

- (void)connenct:(CBPeripheral *)peripheral;

- (void)sendDataWithCMD:(NSInteger)cmd andData:(NSData *)data compeleteBloc:(void(^)(BOOL result, NSData *data))compeleteBloc;
- (void)sendOTAData:(NSData *)data compeleteBloc:(void(^)(BOOL result, NSData *data))compeleteBloc;;

- (void)readData;
@end

NS_ASSUME_NONNULL_END
