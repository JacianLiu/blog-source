---
title: Spring Bean 生命周期
tags:
  - Spring
categories:
  - Spring
toc: true
cover: 'https://img.jacian.com/note/img/20200826163449.png'
article-thumbnail: 'false'
date: 2020-11-19 12:38:47
---



1. 实例化`Bean`
2. 设置`Bean`属性值
3. 判断是否实现`BeanNameAware`，如果实现调用其setBeanName方法
4. 判断是否实现`BeanFactoryAware`，如果实现调用其`setBeanFactory`方法<!--more-->
5. 判断是否实现`ApplicationContextAware`，如果实现调用其`setApplicationContext`方法
6. 调用`BeanPostProcessor`的预初始化方法
7. 判断是否标注`@PostConstruct`注解，如果有则执行
8. 判断是否实现`InitializingBean`，如果实现调用其`afterPropertiesSet`方法
9. 判断是否配置初始化方法（`init-method`）
10. 调用`BeanPostProcessor`的后初始化方法
11. 是否为`singleton`
    1. singleton: 将Bean放入SpringIOC的缓存池中
    2. prototype: 将Bean交给调用者，后续不进行管理（不参与后续步骤）
12. 执行`@PreDestory`标注的方法
13. 调⽤`DisposableBean的destory`⽅法
14. 调⽤属性配置的销毁⽅法（`destory-method`）

![](https://img.jacian.com/note/img/20201119124023.jpg)