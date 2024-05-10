//
//  NSData+Util.m
//  CCBluetoothDemo
//
//  Created by CarvenChen on 2021/2/3.
//

#import "NSData+Util.h"

@implementation NSData (Util)

+ (NSData *)dataWithByte:(Byte)byte
{
    NSData *data = [NSData dataWithBytes:&byte length:sizeof(Byte)];
    return data;
}

+ (NSData *)dataWithShort:(short)Short
{
    HTONS(Short);
    return [NSData dataWithBytes:&Short length:sizeof(short)];
}

+ (NSData *)dataWithInt:(int)Int
{
    HTONL(Int);
    return [NSData dataWithBytes:&Int length:sizeof(int)];
}

+ (NSData *)dataWithLong:(long)Long
{
    HTONLL(Long);
    return [NSData dataWithBytes:&Long length:sizeof(long)];
}

+ (NSData *)dataWithString:(NSString *)string
{
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData *)dataWithHexString:(NSString *)str
{
    if (!str || [str length] == 0)
    {
        return nil;
    }
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:0];
    NSRange range;
    if ([str length] % 2 == 0)
    {
        range = NSMakeRange(0, 2);
    }
    else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2)
    {
        unsigned int anInt;
        //取出range内的子字符串
        NSString *hexCharStr = [str substringWithRange:range];
        //扫描者对象，扫描对应字符串
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        //扫描16进制数返回给无符号整型anInt
        [scanner scanHexInt:&anInt];
        //把这个int类型数转成1个字节的NSdata类型
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];    //加到可变data类型hexData上
        
        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}

@end
