---
title: Zookeeper环境搭建
tags:
  - Zookeeper
categories:
  - Zookeeper
cover: 'http://img.jacian.com/note/img/20210524201258.jpg'
date: 2020-12-31 15:07:00
---

## 下载源码

本文以 `Zookeeper 3.5.4` 为例，源码下载地址：https://github.com/apache/zookeeper/tree/release-3.5.4

## 源码编译

在命令行使用 `ant` 编译的时候出现了一些问题，在网上没有找到解决方案，所以使用 idea 进行编译，希望有知道原因的大佬指点迷津，下图为执行 `ant eclipse` 后的报错信息

![image-20201231150258597](https://img.jacian.com/note/img20201231150258.png)



> 下边是具体操作步骤

首先使用 idea 打开项目

![image-20201231142101629](https://img.jacian.com/note/img20201231142101.png)

右击 `build.xml` ，选择 `Add as Ant Build File` 

![image-20201231142149848](https://img.jacian.com/note/img20201231142149.png)

展开右侧 `Ant` 侧边栏，双击 `eclipse` 

![image-20201231142311413](https://img.jacian.com/note/img20201231142311.png)

等待 build 完成，时间根据自身网络环境而定

![image-20201231142347703](https://img.jacian.com/note/img20201231142347.png)

编译完成后会产生eclipse 的配置文件

![image-20201231142516118](https://img.jacian.com/note/img20201231142516.png)



## 源码导入

这时关掉项目窗口，选择 `File --> New --> Project from Existing Sources...`

![image-20201231142808610](https://img.jacian.com/note/img20201231142808.png)



选择项目目录，选择导入Eclipse项目，然后一路 Next 

![image-20201231142924975](https://img.jacian.com/note/img20201231142925.png)

这时候源码就导入成功了~

## 启动Zookeeper服务端

针对单机版本和集群版本，分别对应两个启动类：

- 单机：ZooKeeperServerMain
- 集群：QuorumPeerMain

这里只做单机版测试

在 `conf` 目录下复制一份 `zoo_sample.cfg` 并重命名为 `zoo.cfg`

![image-20201231143409237](https://img.jacian.com/note/img20201231143409.png)

配置主启动类，选择 `Add Configuration`

![image-20201231143511158](https://img.jacian.com/note/img20201231143511.png)

选择添加一个 `Application` 

![image-20201231143604156](https://img.jacian.com/note/img20201231143604.png)

> 图中 `1` 为 `VM options` ； `2` 为 `Main Class` ； `3` 为 `Program arguments` 
>
> 如果2020 版本找不到` VM options` 点击右上方的 `Modify options --> Add VM options` 即可
>
> 如果2020 版本找不到` VM options` 点击右上方的 `Modify options --> Add VM options` 即可
>
> 如果2020 版本找不到` VM options` 点击右上方的 `Modify options --> Add VM options` 即可

具体配置如下

![image-20201231144252187](https://img.jacian.com/note/img20201231144252.png)

```tex
主类全路径： org.apache.zookeeper.server.quorum.QuorumPeerMain
```



运行配置好的 Application，看到日志输出代表启动成功

![image-20201231144447861](https://img.jacian.com/note/img20201231144447.png)

## 启动Zookeeper客户端

通过运行 `QuorumPeerMain` 得到的日志，可以得知ZooKeeper服务端已经启动，服务的地址为`127.0.0.1:2182`。启动客户端来进行连接测试。

客户端的启动类为`org.apache.zookeeper.ZooKeeperMain`，进行如下配置：

同样的增加一个 `Application`

![image-20201231145312089](https://img.jacian.com/note/img20201231145312.png)

运行配置好的 Application

![image-20201231145443172](https://img.jacian.com/note/img20201231145443.png)

可以看到已经连接成功，并且可以键入命令；