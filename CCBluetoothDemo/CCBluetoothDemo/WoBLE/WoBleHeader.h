//
//  WoBleHeader.h
//  CCBluetoothDemo
//
//  Created by CarvenChen on 2021/2/7.
//

//#import "WoBleManager.h"

#ifndef WoBleHeader_h
#define WoBleHeader_h

typedef NS_ENUM(NSInteger, WoBLEVersion) {
    WoBLEVersion40 = 20,
    WoBLEVersion42AndLater = 168,
};

#define WoBleBaseHeaderLength   5
#define WoBleOTAHeaderLength    3
#define WoBleOTASinleLoopNum    16

//包长相关的宏
//#define WO_MAX_PACK_LEN 2048
//#define WO_MAX_SEND_LEN 1024
//#define WO_MAX_SINGLE_PACKET_LEN_40 20
//#define WO_MAX_SINGLE_PACKET_LEN_42 244

/* 新协议2021-03-02 命令字 begin */
#define REQUEST_REMAIN_VERSION        0x01      //预留id
#define RESPONSE_REMAIN_VERSION       0x0F      //预留id

#define APP_QUERY_PARAMS              0x12      //查询设备信息
#define TERMINAL_UPLOAD_PARAMS        0x13      //回复查询信息
#define APP_OPERATION_PARAMS          0x20      //APP通知设备进行相关硬件操作

#define APP_SEND_CMD_DATA             0x30      //APP发送命令到设备
#define TERMINAL_SUCCESS_PARAMS       0x31      //成功，设备返回0x30对应结果
#define TERMINAL_FAILED_PARAMS        0x32      //失败，设备返回0x30对应结果

#define APP_OTA_PREPARE               0x40      // 发送OTA写入请求
#define TERMINAL_0TA_PERMISSION       0x41      // 回复是否允许OTA数据写入
#define APP_OTA_SEND_DATA_LOOP        0x42      // 循环发送数据
#define TERMINAL_OTA_LOOP_DATA_RESULT 0x43      // 回复每个循环的检查结果
#define APP_OTA_SEND_FINISH           0x44      // 数据传输完成
#define TERMINAL_OTA_DATA_RESULT      0x45      // 检查数据的完整性等结果上报

//LPA
#define APP_LPA_INIT                0x60      // 发送LPA初始化
#define TERMINAL_LPA_INIT_RESULT    0x61      // 回复LPA初始化结果
#define APP_LPA_AUTH                0x62      // 发送LPA认证
#define TERMINAL_LPA_AUTH_RESULT    0x63      // 回复LPA认证结果
#define APP_LPA_PREPARE             0x64      // 发送LPA下载准备
#define TERMINAL_LPA_PREPARE_RESULT 0x65      // 回复LPA下载准备结果
#define APP_LPA_Profile             0x66      // 发送LPA-profile文件
#define TERMINAL_LPA_Profile_RESULT 0x67      // 回复LPA-profile结果

/* 新协议2021-03-02 命令字 end */

#endif /* WoBleHeader_h */
