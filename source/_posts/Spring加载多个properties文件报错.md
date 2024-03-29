---
title: Spring加载多个properties文件报错
tags:
  - Spring
categories:
  - Java
toc: true
category: java
date: 2019-02-20 22:09:41
---

## 1. 问题描述
启动web项目时保存 , 该问题出现的原因为 spring 加载 properties 文件时无法找到对应的属性值 ; 
> Caused by : java.lang.IllegalArgumentException: Could not resolve placeholder 'xxx' in string value "${xxx}"
<!-- more -->

## 2. 问题分析

![bug](http://upload-images.jianshu.io/upload_images/13970177-f01066c5dc943cb8.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

提示我无法解析占位符 , 导入 log4j 配置文件之后 , 发现并没有加载到所对应的properties文件 ;

![redis-config.properties](http://upload-images.jianshu.io/upload_images/13970177-c5231718e04de51a.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这里只是解析了 "redis-config.properties" 但是并没有加载 , 所以导致找不到对应的属性值 ;
## 3. 问题解决及原因
查了下资料发现 spring 容器中仅允许且最多只会扫描一个 properties 文件 , 当扫描到 properties 时 , 后边的 properties 文件会被忽略掉 ;
### 解决方案一
在每个 **<context:property-placeholder>** 中添加 **ignore-unresolvable="true"** 属性 ;
![解决方案一](http://upload-images.jianshu.io/upload_images/13970177-4529ceea1d5a5e7a.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 解决方案二
将 properties 所在的文件夹名称改为一致 ;
![解决方案二](http://upload-images.jianshu.io/upload_images/13970177-a41fdcb3d1cf056d.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)