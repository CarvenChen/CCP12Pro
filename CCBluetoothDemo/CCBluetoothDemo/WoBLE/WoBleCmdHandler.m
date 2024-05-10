//
//  WoBleCmdHandler.m
//  CCBluetoothDemo
//
//  Created by CarvenChen on 2021/2/20.
//

#import "WoBleCmdHandler.h"

@implementation WoBleCmdHandler
- (void)handleWithData:(NSData *)data compeleteBloc:(void(^)(BOOL, NSData*))compeleteBloc {
    if (compeleteBloc) {
        compeleteBloc(YES, data);
    }
}
@end

//Base
@implementation WoBleBaseCmdQueryHandler

@end


@implementation WoBleBaseCmdSuccessHandler

@end

@implementation WoBleBaseCmdFailedHandler

- (void)handleWithData:(NSData *)data compeleteBloc:(void(^)(BOOL, NSData*))compeleteBloc {
    if (compeleteBloc) {
        compeleteBloc(NO, nil);
    }
}

@end


//OTA
@implementation WoBleOTAPermissionHandler

@end

@implementation WoBleOTALoopCheckHandler

@end

@implementation WoBleOTAResultHandler

@end


//LPA
@implementation WoBleLPAInitHandler

@end

@implementation WoBleLPAAuthHandler

@end

@implementation WoBleLPAPrepareHandler

@end

@implementation WoBleLPAProfileHandler

@end
