//
//  ViewController.h
//  SDBluetoothDemo
//
//  Created by 管理员 on 16/6/20.
//  Copyright © 2016年 shendong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@end
/*  iOS蓝牙开发
1. 参考资料
  1.1 http://blog.csdn.net/m372897500/article/details/50662976
  1.2 http://www.jianshu.com/p/760f042a1d81
  1.3 蓝牙开发中有两个重要的概念:中央(CBCentralManager)和周边设备(CBPeripheral);通俗的理解，中央就是接收并处理的设备,周边是发送蓝牙并和中央通信的设备

2. 流程
    2.2建立连接过程
      2.2.1建立蓝牙中央(CBCentralManager)，并设置delegate, 开始蓝牙扫描
      2.2.2 delegate反射当前蓝牙的连接状态CBCentralManager.state
      2.2.3 centralManager:(CBCentralManager *)central didDiscoverPeripheral 发现了当前正在广播的蓝牙数据,从中挑选并连接
      2.2.4 centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral显示连接请求是否被正常建立
      2.2.5 蓝牙连接后,强持有周边设备(CBPeripheral),并设置delegate,查询周边的service
      2.2.6 peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService 周边设备查询service后,继续查询每个服务的特征值(CBCharacteristic),找到对应的特征值后监听该特征值的状态，此过程需要将特征值持有，以便在获取监听状态后匹配
 
  2.3  数据交互过程
      2.3.1 peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
          根据监听到的特征值的变化,实时获取数据
          2.3.1.1 此处可以对“读数据”, "写数据"根据不同的CBCharacteristic监听
          2.3.1.2 可根据指定的数据，对设备发送命令，即写数据到设备[self.peripheral writeValue:data forCharacteristic:self.writeCharacteistic type:CBCharacteristicWriteWithResponse];
      2.3.2所有数据的操作,需根据设备厂家提供的文档进行替换。

*/