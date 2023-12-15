

import 'dart:io';
import 'package:system_info2/system_info2.dart';

///класс данных о характеристиках устройства пользователя
class CurrentSystemInformation{
  ProcessorArchitecture? kernelArchitecture;
  int? kernelBitness;
  String? osName;
  String? osVersion;
  String? userDirectory;
  String? userId;
  String? userName;
  int? systemCores;
  int megaByte = 1024 * 1024;

  CurrentSystemInformation(){
    if (!(Platform.isIOS || Platform.isWindows)) getSysInfo();
  }

  bool getSysInfo(){
    kernelArchitecture = SysInfo.kernelArchitecture;
    kernelBitness = SysInfo.kernelBitness;
    osName = SysInfo.operatingSystemName;
    osVersion = SysInfo.operatingSystemVersion;
    userDirectory = SysInfo.userDirectory;
    userId = SysInfo.userId;
    userName = SysInfo.userName;
    systemCores = SysInfo.cores.length;

    print('Kernel architecture     : ${SysInfo.kernelArchitecture}');
    //print('Raw Kernel architecture : ${SysInfo.rawKernelArchitecture}');
    print('Битрейт процессора          : ${SysInfo.kernelBitness}');
    //print('Kernel name             : ${SysInfo.kernelName}');
    //print('Kernel version          : ${SysInfo.kernelVersion}');
    print('Operating system name   : ${SysInfo.operatingSystemName}');
    print('Operating system version: ${SysInfo.operatingSystemVersion}');
    print('User directory          : ${SysInfo.userDirectory}');
    print('User id                 : ${SysInfo.userId}');
    print('User name               : ${SysInfo.userName}');
    //print('User space bitness      : ${SysInfo.userSpaceBitness}');
    final cores = SysInfo.cores;
    print('Number of core    : ${cores.length}');
    // for (final core in cores) {
    //   print('  Architecture          : ${core.architecture}');
    //   print('  Name                  : ${core.name}');
    //   print('  Socket                : ${core.socket}');
    //   print('  Vendor                : ${core.vendor}');
    // }
    //print('Total physical memory   '': ${SysInfo.getTotalPhysicalMemory() ~/ megaByte} MB');
    //print('Free physical memory    '': ${SysInfo.getFreePhysicalMemory() ~/ megaByte} MB');
    //print('Total virtual memory    '': ${SysInfo.getTotalVirtualMemory() ~/ megaByte} MB');
    //print('Free virtual memory     '': ${SysInfo.getFreeVirtualMemory() ~/ megaByte} MB');
    //print('Virtual memory size     '
    //   ': ${SysInfo.getVirtualMemorySize() ~/ megaByte} MB');

    return true;
  }

}