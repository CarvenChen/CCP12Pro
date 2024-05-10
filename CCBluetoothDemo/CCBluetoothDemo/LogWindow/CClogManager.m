//
//  CClogManager.m
//  CCBluetoothDemo
//
//  Created by Carven on 2022/9/28.
//

#import "CClogManager.h"

/**
 用来保存 log 的 Model 类
 */
@interface CCLogModel()



@end


@implementation CCLogModel

+ (instancetype)logWithText:(NSString*)logText {
    CCLogModel* log = [CCLogModel new];
    log.timestamp = [[NSDate date] timeIntervalSince1970];
    log.log = logText;
    return log;
}

@end


@interface CClogManager ()


@end

@implementation CClogManager

static CClogManager __strong * logManager = nil;

+ (instancetype)sharedInstance {
    if (logManager == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            logManager = [[CClogManager alloc] init];
            logManager.logs = [NSMutableArray array];
        });
    }
    return logManager;
}

+ (void)printLog:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(),^{
        [[self sharedInstance] printLog:text];
    });
}

- (void)printLog:(NSString*)newLog {
    if (newLog.length == 0) {
        return;
    }
    
    @synchronized (self) {
        newLog = [NSString stringWithFormat:@"%@", newLog ?: @""]; // add new line
        CCLogModel* log = [CCLogModel logWithText:newLog];
        
        // data
        if (!log) {
            return;
        }
        [self.logs addObject:log];
    }
}

@end
