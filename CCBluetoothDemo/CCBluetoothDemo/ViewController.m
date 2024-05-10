//
//  ViewController.m
//  CCBluetoothDemo
//
//  Created by CarvenChen on 2020/12/22.
//

#import "ViewController.h"
#import "WoBleManager.h"
#import "CClogManager.h"
#import "CCLogViewController.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) NSMutableArray *dataSourceArray;
@property(nonatomic, strong) NSArray *cmdArray;

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UITableView *cmdTableView;
@property(nonatomic, strong) CBPeripheral *connPeripheral;
@property (weak, nonatomic) IBOutlet UITextField *serviceTF;
@property (weak, nonatomic) IBOutlet UITextField *characteristicTF;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSourceArray = [NSMutableArray array];
    self.cmdArray = @[
        @"0x12",
        @"0x60",
//        @"0x30",
//        @"0x40",
//        @"0x42",
//        @"0x44",
    ];
    
    self.tableview.dataSource = self;
    self.tableview.delegate = self;
    
    self.cmdTableView.dataSource = self;
    self.cmdTableView.delegate = self;
    
    __weak typeof(self) weakSelf = self;
    [[WoBleManager shareInstance] scanPeripherals];
    [[WoBleManager shareInstance] setFindUpdateBloc:^(NSArray * _Nonnull dataArray) {
        [weakSelf.dataSourceArray removeAllObjects];
        [weakSelf.dataSourceArray addObjectsFromArray:dataArray];
        [weakSelf.tableview reloadData];
    }];
    [[WoBleManager shareInstance] setConnectedBloc:^(CBPeripheral * _Nonnull peripheral) {
        weakSelf.connPeripheral = peripheral;
        [weakSelf.tableview reloadData];
    }];
    [[WoBleManager shareInstance] setDisConnectBloc:^(CBPeripheral * _Nonnull peripheral) {
        if (weakSelf.connPeripheral == peripheral) {
            weakSelf.connPeripheral = nil;
            [weakSelf.tableview reloadData];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *serviceUUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"serviceUUID"];
    NSString *characteristicUUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"characteristicUUID"];
    
    if (serviceUUID.length > 0) {
        SERVICE_UDID = serviceUUID;
    }
    if (characteristicUUID.length > 0) {
        CHARACTERRISTIC_UDID = characteristicUUID;
    }
    
    self.serviceTF.text = SERVICE_UDID;
    self.characteristicTF.text = CHARACTERRISTIC_UDID;
}

- (IBAction)connect:(id)sender {
    CCLogViewController *vc = [[CCLogViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)sendMsg:(id)sender {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"json"];
    NSData *content_data = [NSData dataWithContentsOfFile:path];
    
    [[WoBleManager shareInstance] sendDataWithCMD:APP_SEND_CMD_DATA andData:content_data compeleteBloc:^(BOOL result, NSData *data) {
        
    }];

    
//    NSString *string = @"RK";
//    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
//
//    void *sendProtobufLen = malloc(8);
//    memset(sendProtobufLen, 0, data.length);
//    memcpy(sendProtobufLen, [data bytes], data.length);
//
//    Byte b = 0x02;
//    Byte byte[] = {b};
//    NSData *lenthData = [[NSData alloc] initWithBytes:byte length:1];
//    memcpy(sendProtobufLen + 2, [lenthData bytes], lenthData.length);
//    NSData *sendData = [NSData dataWithBytes:sendProtobufLen length:8];
    
    
    
    
//    void *sendProtobufLen = malloc(1);
//    memset(sendProtobufLen, 0, 1);
//    int number = 88;
//    NSData *lenthData = [NSData dataWithBytes:&number length:1];
//    memcpy(sendProtobufLen, [lenthData bytes], lenthData.length);
//    NSData *sendData = [NSData dataWithBytes:sendProtobufLen length:1];
//
//    [self.peripheral writeValue:sendData forCharacteristic:self.writecharacteristic type:CBCharacteristicWriteWithResponse];
//
//    free(sendProtobufLen);
//    sendProtobufLen = nil;
    
        
    
//    Byte b = 0x02;
//    Byte byte[] = {b};
//    NSData *lenthData = [[NSData alloc] initWithBytes:byte length:1];
//    [self.peripheral writeValue:lenthData forCharacteristic:self.writecharacteristic type:CBCharacteristicWriteWithoutResponse];
    
    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"json"];
//    NSData *content_data = [NSData dataWithContentsOfFile:path];
//    NSString *content = [NSJSONSerialization JSONObjectWithData:content_data options:kNilOptions error:nil];
//
//    NSArray *array =  [WoBleDataUtil sliptData:content_data cmd:APP_SEND_DATA byBleVersion:WoBLEVersion42AndLater];
//
//    for (NSData *package in array) {
//        [self.peripheral writeValue:package forCharacteristic:self.writecharacteristic type:CBCharacteristicWriteWithoutResponse];
//    }
//
//    NSMutableData *total = [NSMutableData data];
//    for (NSData *package in array) {
//        NSData *subData = [package subdataWithRange:NSMakeRange(4, package.length - 4)];
//        [total appendData:subData];
//    }
//    NSString *str = [[NSString alloc] initWithData:total encoding:NSUTF8StringEncoding];
//    NSLog(@"");
}

- (IBAction)readMsg:(UIButton *)sender {
//    [self.peripheral readValueForCharacteristic:self.readcharacteristic];
    [[WoBleManager shareInstance] readData];
}

- (IBAction)saveButtonClicked:(UIButton *)sender {
    [self.view endEditing:YES];
    
    if (self.serviceTF.text.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:[self.serviceTF.text uppercaseString] forKey:@"serviceUUID"];
        SERVICE_UDID = [self.serviceTF.text uppercaseString];
    }
    
    if (self.characteristicTF.text.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.characteristicTF.text forKey:@"characteristicUUID"];
        CHARACTERRISTIC_UDID = [self.characteristicTF.text uppercaseString];
    }
}

#pragma mark -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableview) {
        return self.dataSourceArray.count;
    }
    return self.cmdArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellID"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (tableView == self.tableview) {
        CBPeripheral *peripheral = [self.dataSourceArray objectAtIndex:indexPath.row];
        cell.textLabel.text = peripheral.name;
        
        if (peripheral == self.connPeripheral) {
            cell.textLabel.textColor = [UIColor blueColor];
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
        }
    } else {
        cell.textLabel.text = [self.cmdArray objectAtIndex:indexPath.row];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableview) {
        CBPeripheral *peripheral = [self.dataSourceArray objectAtIndex:indexPath.row];
        [[WoBleManager shareInstance] connenct:peripheral];
        
        [SVProgressHUD showWithStatus:@"连接中"];
    } else {

        int cmd = 0;
        NSData *data = [NSData data];
        switch (indexPath.row) {
            case 0:
                cmd = APP_QUERY_PARAMS;
                break;
            case 1: {
                cmd = APP_LPA_INIT;
                NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"json"];
                data = [NSData dataWithContentsOfFile:path];
            }
                break;
            case 2:
                cmd = APP_SEND_CMD_DATA;
                break;
            case 3:
                cmd = APP_OTA_PREPARE;
                break;
            case 4:
                cmd = APP_OTA_SEND_DATA_LOOP;
                break;
            case 5:
                cmd = APP_OTA_SEND_FINISH;
                break;
            default:
                break;
        }
        
        [[WoBleManager shareInstance] sendDataWithCMD:cmd andData:data compeleteBloc:^(BOOL result, NSData *data) {
            
        }];
    }
}


@end
