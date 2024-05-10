//
//  WoBleManager.m
//  CCBluetoothDemo
//
//  Created by CarvenChen on 2021/2/7.
//

#import "WoBleManager.h"
#import "WoBleDataUtil.h"
#import "WoBleCmdHandler.h"

static float WoBleWriteDelay = 0.02;

//static NSString *SERVICE_UDID = @"2616";
//static NSString *CHARACTERRISTIC_UDID = @"7F06";

NSString *SERVICE_UDID = @"2616";
NSString *CHARACTERRISTIC_UDID = @"7F06";


@interface WoBleManager ()

@property(nonatomic, strong) CBPeripheral *peripheral;
@property(nonatomic, strong) CBCharacteristic *readcharacteristic;
@property(nonatomic, strong) CBCharacteristic *writecharacteristic;

@property(nonatomic, strong) NSData *otaData;
@property(nonatomic, strong) NSArray *otaArray;
@property(nonatomic, assign) NSInteger otaIndex;
@property(nonatomic, assign) NSInteger otaLastLength;
@property(nonatomic, assign) NSInteger otaCancelCount;

@property(nonatomic, strong) NSDictionary *handlerDict;
@property(nonatomic, strong) NSTimer *timer;

@property(nonatomic, copy) void (^compeleteBloc)(BOOL result, NSData *data);


@end

@implementation WoBleManager

+ (instancetype)shareInstance {
    static WoBleManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[WoBleManager alloc] init];
        _sharedInstance.dataArray = [NSMutableArray array];
        _sharedInstance.handlerDict = @{
            [NSNumber numberWithInteger:TERMINAL_UPLOAD_PARAMS]         : [[WoBleBaseCmdQueryHandler alloc] init],
            [NSNumber numberWithInteger:TERMINAL_SUCCESS_PARAMS]        : [[WoBleBaseCmdSuccessHandler alloc] init],
            [NSNumber numberWithInteger:TERMINAL_FAILED_PARAMS]         : [[WoBleBaseCmdFailedHandler alloc] init],
            [NSNumber numberWithInteger:TERMINAL_0TA_PERMISSION]        : [[WoBleOTAPermissionHandler alloc] init],
            [NSNumber numberWithInteger:TERMINAL_OTA_LOOP_DATA_RESULT]  : [[WoBleOTALoopCheckHandler alloc] init],
            [NSNumber numberWithInteger:TERMINAL_OTA_DATA_RESULT]       : [[WoBleOTAResultHandler alloc] init],
            [NSNumber numberWithInteger:TERMINAL_LPA_INIT_RESULT]       : [[WoBleLPAInitHandler alloc] init],
            [NSNumber numberWithInteger:TERMINAL_LPA_AUTH_RESULT]       : [[WoBleLPAAuthHandler alloc] init],
            [NSNumber numberWithInteger:TERMINAL_LPA_PREPARE_RESULT]    : [[WoBleLPAPrepareHandler alloc] init],
            [NSNumber numberWithInteger:TERMINAL_LPA_Profile_RESULT]    : [[WoBleLPAProfileHandler alloc] init],
        };
    });
    return _sharedInstance;
}

- (void)scanPeripherals {
    BabyBluetooth *baby = [BabyBluetooth shareBabyBluetooth];
    [self configBabyBlutoothDelegate];
    baby.scanForPeripherals().begin();
}

- (void)stopScan {
    [[BabyBluetooth shareBabyBluetooth] cancelScan];
}


- (void)connenct:(CBPeripheral *)peripheral {
    [BabyBluetooth shareBabyBluetooth].having(peripheral).and.then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
    [self stopScan];
}

- (void)closeCurrentConnect {
    if (self.peripheral) {
        [[BabyBluetooth shareBabyBluetooth] cancelPeripheralConnection:self.peripheral];
    }
}

#pragma mark - 基础发送
- (void)sendDataWithCMD:(NSInteger)cmd andData:(NSData *)data compeleteBloc:(void(^)(BOOL result, NSData *data))compeleteBloc {
    [SVProgressHUD showWithStatus:@"发送数据。。。"];
    
    if (self.writecharacteristic == nil) {
        NSLog(@"--write特征为空");
        [CClogManager printLog:@"--write特征为空"];
        
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:@"写特征为空"];
        return;
    }
    
    self.compeleteBloc = compeleteBloc;
    //使用基础模式传输
    NSArray *spliteArray = [[WoBleDataUtil shareInstance] sliptData:data cmd:cmd byBleVersion:WoBLEVersion42AndLater];
    for (NSData *package in spliteArray) {
        
        NSString *str = [WoBleDataUtil hexDecimal2String:package];
        NSLog(@"--发送十六进制 %@", str);
        [CClogManager printLog:[NSString stringWithFormat:@"--发送十六进制 %@", str]];

        [self.peripheral writeValue:package forCharacteristic:self.writecharacteristic type:CBCharacteristicWriteWithoutResponse];
        [NSThread sleepForTimeInterval:WoBleWriteDelay];
    }
    
    [self cancelTimer];
    [self fireTimerWithTime:30];
    
    [SVProgressHUD dismiss];
    [SVProgressHUD showSuccessWithStatus:@"发送成功"];
}

#pragma mark - 发送OTA
- (void)sendOTAData:(NSData *)data compeleteBloc:(void(^)(BOOL result, NSData *data))compeleteBloc {
    if (!data || data.length == 0) {
        return;
    }
    
    if (self.writecharacteristic == nil) {
        NSLog(@"--write特征为空");
        [CClogManager printLog:@"--write特征为空"];
        return;
    }
    
    self.compeleteBloc = compeleteBloc;
    
    //发送ota请求
    NSData *size_data = [WoBleDataUtil bytesFromUInt32:(UInt32)data.length];
    [self sendOTASinglePackageWithCMD:APP_OTA_PREPARE andData:size_data];
    
    //初始化OTA参数
    NSArray *spliteArray = [[WoBleDataUtil shareInstance] sliptOTAData:data cmd:APP_OTA_SEND_DATA_LOOP byBleVersion:WoBLEVersion42AndLater];
    self.otaData = data;
    self.otaArray = spliteArray;
    self.otaIndex = 0;
    self.otaLastLength = 0;
    self.otaCancelCount = 0;
}

- (void)sendOTASinglePackageWithCMD:(NSInteger)cmd andData:(NSData *)data {
    NSData *sendData = [[WoBleDataUtil shareInstance] otaMsgWithCMD:cmd andData:data];
    [self.peripheral writeValue:sendData forCharacteristic:self.writecharacteristic type:CBCharacteristicWriteWithoutResponse];
    
    [self cancelTimer];
    [self fireTimerWithTime:10];
}

- (void)sendOTAWithSubIndex:(NSInteger)subIndex currentLength:(NSInteger)length {
    NSArray *subArray = nil;
    if (length == 0) {
        //第一个包就失败了
        subArray = [self.otaArray firstObject];
    } else if (length == self.otaData.length) {
        //传输结束
        NSLog(@"--OTA传输结束");
        [CClogManager printLog:@"--OTA传输结束"];

        self.otaData = nil;
        self.otaArray = nil;
        self.otaIndex = 0;
        self.otaCancelCount = 0;
        self.otaLastLength = 0;
        [self sendOTASinglePackageWithCMD:APP_OTA_SEND_FINISH andData:[NSData data]];
        [self cancelTimer];
        [self fireTimerWithTime:10];
    } else {
        subArray = [self.otaArray objectAtIndex:self.otaIndex];
    }
    
    if (subArray && subArray.count > 0) {
        for (NSInteger i = subIndex; i < subArray.count; i++) {
            NSData *package = [subArray objectAtIndex:i];
            [self.peripheral writeValue:package forCharacteristic:self.writecharacteristic type:CBCharacteristicWriteWithoutResponse];
            [NSThread sleepForTimeInterval:WoBleWriteDelay];
        }
        NSLog(@"--OTA传输第%zd个循环结束", self.otaIndex);
        [CClogManager printLog:[NSString stringWithFormat:@"--OTA传输第%zd个循环结束", self.otaIndex]];

        [self cancelTimer];
        [self fireTimerWithTime:subArray.count];
    }
}

- (void)readData {
    [self.peripheral readValueForCharacteristic:self.readcharacteristic];
}

#pragma mark - Delegate
-(void)configBabyBlutoothDelegate {

    __weak typeof(self) weakSelf = self;
    //设置扫描到设备的委托
    [[BabyBluetooth shareBabyBluetooth] setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"--搜索到了设备:%@",peripheral.name);
        [CClogManager printLog:[NSString stringWithFormat:@"--搜索到了设备:%@",peripheral.name]];

        if (![weakSelf.dataArray containsObject:peripheral]) {
            [weakSelf.dataArray addObject:peripheral];
        }
        
        if (weakSelf.findUpdateBloc) {
            weakSelf.findUpdateBloc(weakSelf.dataArray);
        }
    }];
    
    //过滤器-设置查找设备的过滤器
    [[BabyBluetooth shareBabyBluetooth] setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        //最常用的场景是查找某一个前缀开头的设备 most common usage is discover for peripheral that name has common prefix
//        if ([peripheralName hasPrefix:@"ZTE"] ) {
//            return YES;
//        }
//        return NO;
        //设置查找规则是名称大于1
        if (peripheralName.length >1) {
            return YES;
        }
        return NO;
    }];
    
    //设置设备连接成功的委托
    [[BabyBluetooth shareBabyBluetooth] setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        NSLog(@"--连接成功%@",peripheral.name);
        [CClogManager printLog:[NSString stringWithFormat:@"--连接成功%@",peripheral.name]];
        [SVProgressHUD dismiss];
        [SVProgressHUD showSuccessWithStatus:@"连接成功"];
        
        if (weakSelf.connectedBloc) {
            weakSelf.connectedBloc(peripheral);
        }
    }];
    
    //设置连接的设备的过滤器
     __block BOOL isFirst = YES;
     [[BabyBluetooth shareBabyBluetooth] setFilterOnConnectToPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
         //这里的规则是：连接第一个SK打头的设备
         if(isFirst && [peripheralName isEqualToString:self.peripheral.name]){
             isFirst = NO;
             return YES;
         }
         return NO;
     }];
    
    //设置发现设备的Services的委托
    [[BabyBluetooth shareBabyBluetooth] setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        for (CBService *service in peripheral.services) {
            NSLog(@"--搜索到服务:%@",service.UUID.UUIDString);
            [CClogManager printLog:[NSString stringWithFormat:@"--搜索到服务:%@",service.UUID.UUIDString]];

        }
    }];
    
    //设置发现设service的Characteristics的委托
    [[BabyBluetooth shareBabyBluetooth] setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"--服务 UUID is :%@",service.UUID.UUIDString);
        [CClogManager printLog:[NSString stringWithFormat:@"--服务 UUID is :%@",service.UUID.UUIDString]];
        
        if ([service.UUID.UUIDString isEqualToString:SERVICE_UDID]) {
            weakSelf.peripheral = peripheral;
            
            NSLog(@"--服务 UUID 匹配成功");
            [CClogManager printLog:[NSString stringWithFormat:@"--服务 UUID 匹配成功"]];
            
            for (CBCharacteristic *c in service.characteristics) {
                NSLog(@"--服务 的 charateristic UUID is :%@",c.UUID.UUIDString);
                [CClogManager printLog:[NSString stringWithFormat:@"--服务 的 charateristic UUID is :%@",c.UUID.UUIDString]];

                if ([c.UUID.UUIDString isEqualToString:CHARACTERRISTIC_UDID]) {
                    weakSelf.readcharacteristic = c;
                    [weakSelf notifyCharacteristic:c];
                    
                    NSLog(@"--读取特征 UUID 匹配成功");
                    [CClogManager printLog:[NSString stringWithFormat:@"--读取特征 UUID 匹配成功"]];
                }
                
                if ([c.UUID.UUIDString isEqualToString:CHARACTERRISTIC_UDID]) {
                    weakSelf.writecharacteristic = c;
                    
                    NSLog(@"--写入特征 UUID 匹配成功");
                    [CClogManager printLog:[NSString stringWithFormat:@"--写入特征 UUID 匹配成功"]];
                }
            }
        }
    }];
    
    //设置读取characteristics的委托
    [[BabyBluetooth shareBabyBluetooth] setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSLog(@"--读取 UUID为:%@的characteristic value is:%@",characteristics.UUID.UUIDString, characteristics.value);
        [CClogManager printLog:[NSString stringWithFormat:@"--读取 UUID为:%@的characteristic value is:%@",characteristics.UUID.UUIDString, characteristics.value]];

    }];
    
    //设置发现characteristics的descriptors的委托
    [[BabyBluetooth shareBabyBluetooth] setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"--service UUID:%@",characteristic.service.UUID.UUIDString);
        [CClogManager printLog:[NSString stringWithFormat:@"--service UUID:%@",characteristic.service.UUID.UUIDString]];

        for (CBDescriptor *d in characteristic.descriptors) {
            NSLog(@"--service 为%@ 的 CBDescriptor UUID is :%@", characteristic.service.UUID.UUIDString, d.UUID.UUIDString);
            [CClogManager printLog:[NSString stringWithFormat:@"--service 为%@ 的 CBDescriptor UUID is :%@", characteristic.service.UUID.UUIDString, d.UUID.UUIDString]];
        }
    }];
    
    //设置读取Descriptor的委托
    [[BabyBluetooth shareBabyBluetooth] setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"--characteristic UUID:%@  读取 value is:%@",descriptor.characteristic.UUID.UUIDString, descriptor.value);
        [CClogManager printLog:[NSString stringWithFormat:@"--characteristic UUID:%@  读取 value is:%@",descriptor.characteristic.UUID.UUIDString, descriptor.value]];
    }];
    
    //写数据回调
    [[BabyBluetooth shareBabyBluetooth] setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"--完成写入数据到特性 UUID %@", characteristic.UUID);
        [CClogManager printLog:[NSString stringWithFormat:@"--完成写入数据到特性 UUID %@", characteristic.UUID]];
    }];
    
    //在没有订阅的情况下，读蓝牙数据在此回调，设置订阅之后，统一走订阅回调
//    [[BabyBluetooth shareBabyBluetooth] setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
//        if ([characteristic.UUID.UUIDString isEqualToString:CHARACTERRISTIC_UDID]) {
//            NSData *data = characteristic.value;
//            NSString *value = [WoBleDataUtil hexDecimal2String:data];
//
//            NSLog(@"--接收到数据: %@", value);
//        }
//    }];
    
    [[BabyBluetooth shareBabyBluetooth] setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"--断开连接 %@", peripheral.name);
        [CClogManager printLog:[NSString stringWithFormat:@"--断开连接 %@", peripheral.name]];

        if (peripheral == weakSelf.peripheral) {
            [weakSelf.dataArray removeObject:weakSelf.peripheral];
            if (weakSelf.findUpdateBloc) {
                weakSelf.findUpdateBloc(weakSelf.dataArray);
            }
            if (weakSelf.disConnectBloc) {
                weakSelf.disConnectBloc(peripheral);
            }
            weakSelf.peripheral = nil;
            weakSelf.readcharacteristic = nil;
            weakSelf.writecharacteristic = nil;
            
            [weakSelf scanPeripherals];
        }
    }];
}

static int i = 0;
- (void)notifyCharacteristic:(CBCharacteristic *)characteristic {
    [[BabyBluetooth shareBabyBluetooth] notify:self.peripheral characteristic:characteristic block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        
        NSData *data = characteristics.value;
        if (!data || data.length == 0) {
            NSLog(@"--数据为空");
            [CClogManager printLog:[NSString stringWithFormat:@"--数据为空"]];

            return;
        }
        
        NSData *cmd_data = [data subdataWithRange:NSMakeRange(0, 1)];
        const char* cmd_byte = [cmd_data bytes];
        int cmd;
        memcpy(&cmd, cmd_byte, sizeof(int));

        
        NSLog(@"--第%d个包", i++);
        [CClogManager printLog:[NSString stringWithFormat:@"--第%d个包", i]];
        
        NSString *str = [WoBleDataUtil hexDecimal2String:data];
        
        NSLog(@"--cmd 0x%@", [str substringWithRange:NSMakeRange(0, 2)]);
        [CClogManager printLog:[NSString stringWithFormat:@"--cmd 0x%@", [str substringWithRange:NSMakeRange(0, 2)]]];


        NSLog(@"--十六进制数据 %@", str);
        [CClogManager printLog:[NSString stringWithFormat:@"--十六进制数据 %@", str]];

        //接收到的为OTA命令
        __weak typeof(self) weakSelf = self;
        if (cmd == TERMINAL_OTA_LOOP_DATA_RESULT) {
            
            //取消定时器
            [self cancelTimer];
            
            if (data.length < 8) {
                return;
            }
            
            NSData *pkgNum_data = [data subdataWithRange:NSMakeRange(3, 1)];
            const char* pkgNum_byte = [pkgNum_data bytes];
            int pkgNum;
            memcpy(&pkgNum, pkgNum_byte, sizeof(int));
            NSInteger index = (pkgNum & 0x0F);
            
            NSData *length_data = [data subdataWithRange:NSMakeRange(4, 4)];
            int length = [WoBleDataUtil uint32FromBytes:length_data];
            
            if (weakSelf.otaLastLength == length) {
                weakSelf.otaCancelCount++;
            }
            self.otaLastLength = length;
            if (weakSelf.otaCancelCount == 6) {
                [weakSelf closeCurrentConnect];
                return;
            }
            [weakSelf updateOtaCurrentLoopIndex:length];
            [weakSelf sendOTAWithSubIndex:index currentLength:length];
            
        } else if (cmd == TERMINAL_0TA_PERMISSION) {
            //取消定时器
            [self cancelTimer];
            
            if (data.length < 4) {
                return;
            }
            
            NSData *permission_data = [data subdataWithRange:NSMakeRange(3, 1)];
            const char* permission_byte = [permission_data bytes];
            int permission;
            memcpy(&permission, permission_byte, sizeof(int));
            if (permission == 0) {
                //允许
                [weakSelf sendOTAWithSubIndex:0 currentLength:0];
            } else if (permission == 1) {
                //禁止
                weakSelf.otaData = nil;
                weakSelf.otaArray = nil;
                weakSelf.otaIndex = 0;
                weakSelf.otaLastLength = 0;
                weakSelf.otaCancelCount = 0;
#warning TODO
                [weakSelf closeCurrentConnect];
            }
            
        } else {

            //基础协议收到的消息
            [[WoBleDataUtil shareInstance] handleData:data completeBloc:^(BOOL finish, int cmd, NSData * _Nonnull result) {
                if (finish) {
                    //取消定时器
                    [self cancelTimer];
                    
                    if (result) {
                        //处理命令 + 秘钥校验
                        [weakSelf handleReceiveCmd:cmd data:result];
                    }
                }
            }];
        }
    }];
}

- (void)updateOtaCurrentLoopIndex:(NSInteger)currentLength {
    if (!self.otaArray || self.otaArray.count == 1) {
        return;
    }
    
    NSInteger length = 0;
    for (NSInteger i = 0; i < self.otaArray.count; i++) {
        NSArray *array = [self.otaArray objectAtIndex:i];
        for (NSData *pkg in array) {
            length = length + pkg.length - 3;
        }
        NSLog(@"--计算length %zd", length);
        [CClogManager printLog:[NSString stringWithFormat:@"--计算length %zd", length]];

        if (length > currentLength) {
            self.otaIndex = i;
            break;
        }
    }
}

- (void)handleReceiveCmd:(NSInteger)cmd data:(NSData *)body {
    WoBleCmdHandler *handler = [self.handlerDict objectForKey:[NSNumber numberWithInteger:cmd]];
    [handler handleWithData:body compeleteBloc:self.compeleteBloc];
}

#pragma mark - Timer
- (void)fireTimerWithTime:(NSInteger)time {
    NSLog(@"-- 启动Timer %ld", (long)time);
    [CClogManager printLog:[NSString stringWithFormat:@"--启动Timer %ld", (long)time]];
    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:time repeats:NO block:^(NSTimer * _Nonnull timer) {
        [weakSelf closeCurrentConnect];
    }];
}

- (void)cancelTimer {
    
    NSLog(@"-- 关闭Timer");
    [CClogManager printLog:[NSString stringWithFormat:@"--关闭Timer"]];

    [self.timer invalidate];
    self.timer = nil;
}
    
@end
