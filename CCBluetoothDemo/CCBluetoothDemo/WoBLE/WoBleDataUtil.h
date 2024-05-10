//
//  WoBleDataUtil.h
//  CCBluetoothDemo
//
//  Created by CarvenChen on 2021/2/7.
//

#import <Foundation/Foundation.h>
#import "WoBleHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface WoBleDataUtil : NSObject

+ (instancetype)shareInstance;

- (NSArray *)sliptData:(NSData *)data cmd:(Byte)cmd byBleVersion:(WoBLEVersion)bleVersion;
- (NSArray *)sliptOTAData:(NSData *)data cmd:(Byte)cmd byBleVersion:(WoBLEVersion)bleVersion;
- (NSData *)otaMsgWithCMD:(Byte)cmd andData:(NSData *)data;

+ (NSString*)hexDecimal2String:(NSData *)data;
+ (uint32_t)uint32FromBytes:(NSData *)fData;
+ (NSData *)bytesFromUInt32:(uint32_t)val;

- (void)handleData:(NSData *)data completeBloc:(void(^)(BOOL finish, int cmd, NSData *result))completeBloc;
- (void)handleOTAData:(NSData *)data completeBloc:(void(^)(BOOL finish, int cmd, NSData *result, int index, NSInteger size))completeBloc;


@end

NS_ASSUME_NONNULL_END
