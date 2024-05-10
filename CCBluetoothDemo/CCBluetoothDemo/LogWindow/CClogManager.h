//
//  CClogManager.h
//  CCBluetoothDemo
//
//  Created by Carven on 2022/9/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCLogModel : NSObject
/**
 log 产生的时间戳，单位为 秒
 */
@property (nonatomic, assign) double timestamp;

/**
 log 文本
 */
@property (nonatomic, strong) NSString* log;
@end


@interface CClogManager : NSObject

@property (atomic, strong) NSMutableArray<CCLogModel *> *logs;

+ (instancetype)sharedInstance;
+ (void)printLog:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
