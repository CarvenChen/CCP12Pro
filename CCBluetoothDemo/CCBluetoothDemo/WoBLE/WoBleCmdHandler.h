//
//  WoBleCmdHandler.h
//  CCBluetoothDemo
//
//  Created by CarvenChen on 2021/2/20.
//

#import <Foundation/Foundation.h>
#import "WoBleManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface WoBleCmdHandler : NSObject

- (void)handleWithData:(NSData *)data compeleteBloc:(void(^)(BOOL, NSData*))compeleteBloc;

@end

//===================基础传输协议======================
//0x11
@interface WoBleBaseCmdQueryHandler : WoBleCmdHandler

@end

//0x31
@interface WoBleBaseCmdSuccessHandler : WoBleCmdHandler

@end

//0x32
@interface WoBleBaseCmdFailedHandler : WoBleCmdHandler

@end


//===================快速传输协议======================
//0x41
@interface WoBleOTAPermissionHandler : WoBleCmdHandler

@end

//0x43
@interface WoBleOTALoopCheckHandler : WoBleCmdHandler

@end

//0x45
@interface WoBleOTAResultHandler : WoBleCmdHandler

@end


//===================LPA传输协议======================
//0x51
@interface WoBleLPAInitHandler : WoBleCmdHandler

@end

//0x53
@interface WoBleLPAAuthHandler : WoBleCmdHandler

@end

//0x55
@interface WoBleLPAPrepareHandler : WoBleCmdHandler

@end

//0x57
@interface WoBleLPAProfileHandler : WoBleCmdHandler

@end

NS_ASSUME_NONNULL_END
