//
//  ViewController.m
//  SDBluetoothDemo
//
//  Created by 管理员 on 16/6/20.
//  Copyright © 2016年 shendong. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>


//特性标识符
static NSString *const kConstDeviceName                      = @"eBlood-Pressure";//指定连接设备
static NSString *const kBluetoothCharacteristic_read_uuid    = @"fff4";//读
static NSString *const kBluetoothCharacteristic_write_uuid   = @"fff3";//写
static NSString *const kBluetoothCharacteristic_service_uuid = @"fff0";//

@interface ViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate>

/** <#summary#> */
@property (nonatomic,strong) CBCentralManager *manager; //蓝牙中央(即手机)
/** <#summary#> */
@property (nonatomic,strong) CBPeripheral *peripheral; //蓝牙周边（即蓝牙设备）
@property (nonatomic, strong) CBCharacteristic *writeCharacteistic;


@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController{
    dispatch_queue_t privatequeue;
    int bpResultCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

#pragma mark - lazy load
- (CBCentralManager *)manager{
    if (!_manager) {
        //将蓝牙传输过程放在一个全局并发队列中,
        privatequeue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:privatequeue];
    }
    return _manager;
}
#pragma mark - private method -

- (IBAction)startScan:(id)sender{
    [self.manager scanForPeripheralsWithServices:nil options:nil];
    [self addlog:@"开始扫描"];
}
- (IBAction)stopScan:(id)sender{
    if (_peripheral) {
        [self.manager cancelPeripheralConnection:_peripheral];
    }
    if ([self.manager isScanning]) {
        [self.manager stopScan];
    }
    [self addlog:@"停止扫描"];
}
- (IBAction)clearAction:(id)sender {
    self.textView.text = @"";
}
- (void)addlog:(NSString *)log{
    __weak typeof(self)weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakself.textView.text = [NSString stringWithFormat:@"%@\n%@",weakself.textView.text,log];
        NSRange range = NSMakeRange(weakself.textView.text.length-1, 1);
        [weakself.textView scrollRangeToVisible:range];
    });
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}
#pragma mark - CBCentralManager bluetooth delegate -
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            [self addlog:@"state = CBCentralManagerStateUnknown"];
            break;
        case CBCentralManagerStateResetting:
            [self addlog:@"state = CBCentralManagerStateResetting"];
            break;
        case CBCentralManagerStateUnsupported:
            [self addlog:@"state = CBCentralManagerStateUnsupported"];
            break;
        case CBCentralManagerStateUnauthorized:
            [self addlog:@"state = CBCentralManagerStateUnauthorized"];
            break;
        case CBCentralManagerStatePoweredOff:
            [self addlog:@"state = CBCentralManagerStatePoweredOff"];
            break;
        case CBCentralManagerStatePoweredOn:
            [self addlog:@"state = CBCentralManagerStatePoweredOn"];
            break;
        default:
            break;
    }
}
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    [self addlog:[NSString stringWithFormat:@"发现了设备:name = %@",peripheral.name]];
    //3, 在这里连接指定设备
    if ([peripheral.name containsString:kConstDeviceName]) {
        //建立连接
        self.peripheral = peripheral;
        [self.manager connectPeripheral:self.peripheral options:nil];
    }
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{;
    [self addlog:[NSString stringWithFormat:@"连接了设备,name= %@",peripheral.name]];
    //4.连接设备后,强持有设备peripheral,并设置delegate
    [self.manager stopScan];       //停止扫描
    self.peripheral          = peripheral;//持有设备
    self.peripheral.delegate = self;//设置delegate
    [self.peripheral discoverServices:nil]; //扫描特征值

}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self addlog:[NSString stringWithFormat:@"断开了设备,name= %@",peripheral.name]];
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self addlog:[NSString stringWithFormat:@"连接设备失败,name= %@",peripheral.name]];
}
#pragma mark - CBCentralPerialDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    //5.发现该设备下的所有服务service
    for (CBService *service in peripheral.services) {
        [self addlog:[NSString stringWithFormat:@"service = %@",service.UUID]];
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kBluetoothCharacteristic_service_uuid]]) {
            [service.peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    //6.发现特性服务下的特性
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kBluetoothCharacteristic_service_uuid]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            [self addlog:[NSString stringWithFormat:@"特性ID:%@",characteristic.UUID]];
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kBluetoothCharacteristic_read_uuid]]) {
                [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kBluetoothCharacteristic_write_uuid]]){
                self.writeCharacteistic = characteristic;
            }
        }
    }
    
}
//蓝牙设备更新数据(关键函数)
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    if (characteristic.isNotifying) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kBluetoothCharacteristic_read_uuid]]) {
            NSData *data = characteristic.value;
            Byte *testResult = (Byte *)[data bytes];
            NSLog(@"data.length = %lu,bpResultCount = %d",(unsigned long)data.length,bpResultCount);
            if (data.length == 2) {
              [self addlog:[NSString stringWithFormat:@"血压 = %d",testResult[1]]];
            }else if (data.length == 12 && bpResultCount == 0) {
                [self tellDeviceStopSendData];
                bpResultCount = 1;
                NSString *result = [NSString stringWithFormat:@"最终测量:收缩压：%@,舒张压：%@,心率：%@",[NSString stringWithFormat:@"%d", (testResult[2] + testResult[1] * 255)],[NSString stringWithFormat:@"%d", (testResult[4] + testResult[3] * 255)],[NSString stringWithFormat:@"%d", (testResult[8] + testResult[7] * 255)]];
                [self addlog:result];
            }
        }
        
    }
}
/**
 *  告诉设备停止发送数据
 */
- (void)tellDeviceStopSendData{
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:0];
    int8_t byte0 = 0xFF;
    [data appendBytes:&byte0 length:sizeof(byte0)];
    int8_t byte1 = 0xFD;
    [data appendBytes:&byte1 length:sizeof(byte1)];
    int8_t byte2 = 0x02;
    [data appendBytes:&byte2 length:sizeof(byte2)];
    int8_t byte3 = 0x05;
    [data appendBytes:&byte3 length:sizeof(byte3)];
    NSLog(@"发送的指令为：%@", data);
    if (self.peripheral && self.writeCharacteistic) {
        [self.peripheral writeValue:data forCharacteristic:self.writeCharacteistic type:CBCharacteristicWriteWithResponse];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (characteristic.isNotifying) {
        [self addlog:[NSString stringWithFormat:@"开始监听特征值变化,uuid=%@",characteristic]];
    }else{
        [self addlog:@"停止监听特征值变化"];
    }
}
@end
