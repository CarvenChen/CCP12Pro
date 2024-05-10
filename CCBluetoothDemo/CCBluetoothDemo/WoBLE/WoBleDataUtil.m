//
//  WoBleDataUtil.m
//  CCBluetoothDemo
//
//  Created by CarvenChen on 2021/2/7.
//

#import "WoBleDataUtil.h"

@interface WoBleDataUtil ()

@property(nonatomic, assign) int ticket; //0-15循环
@property(nonatomic, strong) NSMutableDictionary *baseCacheDict;
@property(nonatomic, strong) NSMutableArray *OTACacheArray;

@end

@implementation WoBleDataUtil

+ (instancetype)shareInstance {
    static WoBleDataUtil *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[WoBleDataUtil alloc] init];
        _sharedInstance.baseCacheDict = [NSMutableDictionary dictionary];
        _sharedInstance.OTACacheArray = [NSMutableArray array];
    });
    return _sharedInstance;
}

- (NSArray *)sliptData:(NSData *)data cmd:(Byte)cmd byBleVersion:(WoBLEVersion)bleVersion {
    int maxLength = WoBLEVersion40 - WoBleBaseHeaderLength;
    if (bleVersion == WoBLEVersion42AndLater) {
        maxLength = WoBLEVersion42AndLater - WoBleBaseHeaderLength;
    }
    
    NSMutableArray *sliptArray = [NSMutableArray array];
    //版本号
    Byte ticket = (self.ticket << 4) & 0xFF;
    Byte protocol = (0b000 << 1) & 0xFF;
    Byte encrypt = (0b0) & 0xFF;
    Byte version = ticket | protocol | encrypt;
    
    //数据包大小  数据包索引
    int pkgNum = ceilf(1.0 * data.length / maxLength);
    if (data == nil || data.length == 0) {
        pkgNum = 1;
    }
    Byte totalFrame = pkgNum - 1;//-1因为从0开始
    for (int i = 0; i < pkgNum; i++) {
        Byte size = 0x00;
        NSData *curentData = [NSData data];
        if (i == pkgNum - 1) {
            size = data.length - (pkgNum - 1) * maxLength;
            curentData = [data subdataWithRange:NSMakeRange(maxLength * i, data.length - maxLength * i)];
        } else {
            size = (Byte)maxLength;
            curentData = [data subdataWithRange:NSMakeRange(maxLength * i, maxLength)];
        }

        Byte byte[] = {cmd, version, size, totalFrame, i};
        NSMutableData *singlePackage = [NSMutableData dataWithBytes:&byte length:WoBleBaseHeaderLength];
        
//        Byte byte[] = {cmd};
//        NSMutableData *singlePackage = [NSMutableData dataWithBytes:&byte length:1];
        
        [singlePackage appendData:curentData];
        [sliptArray addObject:singlePackage];
    }
    
    self.ticket ++;
    self.ticket = self.ticket % 16;
    
    return sliptArray;
}

- (NSArray *)sliptOTAData:(NSData *)data cmd:(Byte)cmd byBleVersion:(WoBLEVersion)bleVersion {
    int maxLength = WoBLEVersion40 - WoBleOTAHeaderLength;
    if (bleVersion == WoBLEVersion42AndLater) {
        maxLength = WoBLEVersion42AndLater - WoBleOTAHeaderLength;
    }

    //数据包大小  数据包索引
    int pkgNum = ceilf(1.0 * data.length / maxLength);

    int maxSingleListLen = WoBleOTASinleLoopNum;//每个循环发送多少个包 0-15
    NSMutableArray *sliptArray = [NSMutableArray array];
    NSMutableArray *subArray;
    NSInteger index = 0;
    for (int i = 0; i < pkgNum; i++) {
        if (i % maxSingleListLen == 0) {
            subArray = [NSMutableArray array];
            [sliptArray addObject:subArray];
            index = i / maxSingleListLen;
        }
        
        NSInteger currentTotalNum = pkgNum - index * maxSingleListLen;
        if (currentTotalNum > maxSingleListLen) {
            currentTotalNum = maxSingleListLen;
        }
        Byte totalFrame = ((currentTotalNum - 1) << 4) & 0xFF;//-1因为从0开始

        Byte size = 0x00;
        NSData *curentData = [NSData data];
        if (pkgNum == 1 || i == (pkgNum - 1)) {
            size = data.length - (pkgNum - 1) * maxLength;
            curentData = [data subdataWithRange:NSMakeRange(maxLength * i, data.length - maxLength * i)];
        } else {
            size = (Byte)maxLength;
            curentData = [data subdataWithRange:NSMakeRange(maxLength * i, maxLength)];
        }
        Byte frameSeq = (i % 16) & 0xFF;
        Byte frame = totalFrame | frameSeq;
        Byte byte[] = {cmd, frame, size};
        NSMutableData *singlePackage = [NSMutableData dataWithBytes:&byte length:WoBleOTAHeaderLength];
        [singlePackage appendData:curentData];
        [subArray addObject:singlePackage];
    }
    
    return sliptArray;
}

- (NSData *)otaMsgWithCMD:(Byte)cmd andData:(NSData *)data {
    Byte frame = 0x00;
    NSUInteger length = data ? data.length : 0;
    Byte byte[] = {cmd, frame, length};
    NSMutableData *singlePackage = [NSMutableData dataWithBytes:&byte length:3];
    [singlePackage appendData:data];
    return singlePackage;
}

#pragma mark - Base返回
- (void)handleData:(NSData *)data completeBloc:(void(^)(BOOL finish, int cmd, NSData *result))completeBloc {
    if (!data || data.length < WoBleBaseHeaderLength) {
        return;
    }
    
    NSData *cmd_data = [data subdataWithRange:NSMakeRange(0, 1)];
    NSData *sec_data = [data subdataWithRange:NSMakeRange(1, 1)];
    NSData *data_len = [data subdataWithRange:NSMakeRange(2, 1)];
    NSData *total_data = [data subdataWithRange:NSMakeRange(3, 1)];
    NSData *seq_data = [data subdataWithRange:NSMakeRange(4, 1)];

    const char* cmd_byte = [cmd_data bytes];
    int cmd;
    memcpy(&cmd, cmd_byte, sizeof(int));
    
    const char* sec_byte = [sec_data bytes];
    int sec;
    memcpy(&sec, sec_byte, sizeof(int));
    NSInteger ticket = (sec & 0xF0) >> 4;
    
    const char* len_byte = [data_len bytes];
    int length;
    memcpy(&length, len_byte, sizeof(int));
    
    const char* total_byte = [total_data bytes];
    int total;
    memcpy(&total, total_byte, sizeof(int));
    total = total + 1;//total+1是因为总数从0开始
    
    const char* seq_byte = [seq_data bytes];
    int index;
    memcpy(&index, seq_byte, sizeof(int));
    
    NSData *src_data = [NSData data];
    if (data.length >= length + WoBleBaseHeaderLength) {
        src_data = [data subdataWithRange:NSMakeRange(WoBleBaseHeaderLength, length)];
    }
    
    NSNumber *key = [NSNumber numberWithInteger:ticket];
    NSNumber *subKey = [NSNumber numberWithInteger:index];
    NSMutableDictionary *dataDict = [self.baseCacheDict objectForKey:key];
    
    if (!dataDict) {
        dataDict = [NSMutableDictionary dictionary];
    }
    if (!src_data) {
        src_data = [NSData data];
    }
    [dataDict setObject:src_data forKey:subKey];
    [self.baseCacheDict setObject:dataDict forKey:key];
    
    if (dataDict.allKeys.count == total) {
        NSData *result = [self combineBaseData:key cmd:cmd totalNumber:total];
        [self.baseCacheDict removeObjectForKey:key];
        if (completeBloc) {
            if (data) {
                completeBloc(YES, cmd, result);
            } else {
                completeBloc(NO, cmd, nil);
            }
        }
    } else {
        completeBloc(NO, cmd, nil);
    }
}

- (NSData *)combineBaseData:(NSNumber *)key cmd:(NSInteger)cmd totalNumber:(NSInteger)total {
    NSDictionary *srcDict = [self.baseCacheDict objectForKey:key];
    
    NSMutableData *resultData = [NSMutableData data];
    for (NSInteger i = 0; i < total; i++) {
        NSData *src_data = [srcDict objectForKey:[NSNumber numberWithInteger:i]];
        [resultData appendData:src_data];
    }
    
    NSString *str = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    NSLog(@"--%@", str);
    [CClogManager printLog:[NSString stringWithFormat:@"--%@", str]];

    return resultData;
}

#pragma mark - OTA返回
- (void)handleOTAData:(NSData *)data completeBloc:(void(^)(BOOL finish, int cmd, NSData *result, int index, NSInteger size))completeBloc {
    if (!data || data.length < WoBleOTAHeaderLength) {
        return;
    }
    
    NSData *cmd_data = [data subdataWithRange:NSMakeRange(0, 1)];
    NSData *data_len = [data subdataWithRange:NSMakeRange(1, 1)];
    NSData *seq_data = [data subdataWithRange:NSMakeRange(2, 1)];

    const char* cmd_byte = [cmd_data bytes];
    int cmd;
    memcpy(&cmd, cmd_byte, sizeof(int));

    const char* len_byte = [data_len bytes];
    int length;
    memcpy(&length, len_byte, sizeof(int));

    const char* seq_byte = [seq_data bytes];
    int seq;
    memcpy(&seq, seq_byte, sizeof(int));
    NSInteger total = (seq & 0xF0) >> 4;
    total = total + 1;//total+1是因为总数从0开始
    NSInteger index = (seq & 0x0F);

    NSData *src_data = [NSData data];
    if (data.length >= length + 3) {
        src_data = [data subdataWithRange:NSMakeRange(3, length)];
    }
    
    NSMutableArray *subArray = [self.OTACacheArray lastObject];
    if (subArray && subArray.count == total) {
        subArray = [NSMutableArray array];
        [self.OTACacheArray addObject:subArray];
    }

    if (!src_data) {
        src_data = [NSData data];
    }
    
    if (index == subArray.count) {
        //index能够对应上
        [subArray addObject:src_data];
    } else {
        //index无法对应上，返回报错信息
        
    }
}

- (NSData *)combineOTAData:(NSNumber *)key cmd:(NSInteger)cmd totalNumber:(NSInteger)total {
    NSDictionary *srcDict = [self.baseCacheDict objectForKey:key];
    
    NSMutableData *resultData = [NSMutableData data];
    for (NSInteger i = 0; i < total; i++) {
        NSData *src_data = [srcDict objectForKey:[NSNumber numberWithInteger:i]];
        [resultData appendData:src_data];
    }
    
    NSString *str = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    NSLog(@"--%@", str);
    [CClogManager printLog:[NSString stringWithFormat:@"---%@", str]];

    return resultData;
}

//将传入的NSData类型转换成NSString并返回
+ (NSString*)hexDecimal2String:(NSData *)data {
    NSString* result;
    const unsigned char* dataBuffer = (const unsigned char*)[data bytes];
    if(!dataBuffer){
        return nil;
    }
    NSUInteger dataLength = [data length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength; i++){
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    result = [NSString stringWithString:hexString];
    return result;
}

//NSData转Uint32
+ (uint32_t)uint32FromBytes:(NSData *)fData
{
    NSAssert(fData.length == 4, @"uint32FromBytes: (data length != 4)");
    NSData *data = [self dataWithReverse:fData];
    
    uint32_t val0 = 0;
    uint32_t val1 = 0;
    uint32_t val2 = 0;
    uint32_t val3 = 0;
    [data getBytes:&val0 range:NSMakeRange(0, 1)];
    [data getBytes:&val1 range:NSMakeRange(1, 1)];
    [data getBytes:&val2 range:NSMakeRange(2, 1)];
    [data getBytes:&val3 range:NSMakeRange(3, 1)];
    
    uint32_t dstVal = (val0 & 0xff) + ((val1 << 8) & 0xff00) + ((val2 << 16) & 0xff0000) + ((val3 << 24) & 0xff000000);
    return dstVal;
}

//uint32 转NSData（占八位）
+ (NSData *)bytesFromUInt32:(uint32_t)val
{
    NSMutableData *valData = [[NSMutableData alloc] init];
    
    unsigned char valChar[4];
    valChar[0] = 0xff & val;
    valChar[1] = (0xff00 & val) >> 8;
    valChar[2] = (0xff0000 & val) >> 16;
    valChar[3] = (0xff000000 & val) >> 24;
    [valData appendBytes:valChar length:4];
    
    return [self dataWithReverse:valData];
}

+ (NSData *)dataWithReverse:(NSData *)srcData
{
    NSUInteger byteCount = srcData.length;
    NSMutableData *dstData = [[NSMutableData alloc] initWithData:srcData];
    NSUInteger halfLength = byteCount / 2;
    for (NSUInteger i=0; i<halfLength; i++) {
        NSRange begin = NSMakeRange(i, 1);
        NSRange end = NSMakeRange(byteCount - i - 1, 1);
        NSData *beginData = [srcData subdataWithRange:begin];
        NSData *endData = [srcData subdataWithRange:end];
        [dstData replaceBytesInRange:begin withBytes:endData.bytes];
        [dstData replaceBytesInRange:end withBytes:beginData.bytes];
    }
    
    return dstData;
}

@end
