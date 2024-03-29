---
title: 什么是 IoC？什么是 DI？它们之间是什么关系？
tags:
  - Spring
categories:
  - Spring
toc: true
cover: 'https://img.jacian.com/note/img/20200826163449.png'
article-thumbnail: 'false'
date: 2020-05-19 16:43:58
---

## 什么是控制反转（IOC）
Ioc—Inversion of Control，即“控制反转”，它是一种设计思想，并不是什么技术；在 Java 中，IOC 意味着将我们设计好的对象交给容器控制，而不是传统的需要时在内部构造直接控制；
<!-- more -->

#### 谁控制谁？控制了什么？

-  **谁控制了谁：** IoC 控制了对象；
-  **控制了什么：** 主要控制了外部资源的获取，不仅限于对象，包括文件等资源；


### 什么为正转？什么为反转？

- **正转：**在我们需要某个对象的时候，需要自己主动的去构建对象以及其所依赖的对象；
- **反转：**在我们需要某个对象的时候，只需要在 IoC 容器中获取所需对象，无需关心创建过程以及其中的依赖对象；全盘由 IoC 容器帮我们创建对象以及注入其所依赖的对象，在这里我们把对象的控制权反转给了 IoC 容器，所以称为反转；


### 举个例子
在现实生活中，当我们要用到一样东西的时候，第一反应是去找到这样东西，当我们想吃红烧肉的时候，如果没有饭店的支持，我们需要准备：肉、油、白砂糖、佐料等等一系列东西，然后自己去做，在这个过程中，所有的东西都是自己创造的这个过程称为正转；

然而到了今天，生活变好了加上互联网的兴起，当我们想吃红烧肉的时候，第一反应是去外卖平台描述出我们的需求，通过提供联系方式和送货地址，最后下订单，过一会儿就会有人给我们把红烧肉送过来，在这个过程中，我们并没有主动的去创造红烧肉，红烧肉是外卖平台上的商家创造的，但也完全达到了我们的需求，这个过程称为反转。

## 什么是依赖注入（DI）
DI-Dependency Injection，即"依赖注入"，就是由容器动态的将某个依赖注入到组件中。通过依赖注入机制，我们只需要简单的配置，无需任何代码就可以指定目标所需要的资源，从而完成自身的业务逻辑；我们无需关心具体的资源来自何处，提升了系统灵活性和可扩展性。
<a name="oUXjU"></a>
## IOC和DI的关系
DI 可以看作是 IoC 的一种实现方式，IoC 是一种思想，而 DI 是一种设计模式，是一种实现 IoC 的模式。
<a name="HgQHh"></a>
## 依赖注入的三种方式

1. **构造方法注入：** 被注入的对象可以通过在其构造方法中声明参数列表，让 IoC 容器知道它需要依赖哪些对象
1. **setter 注入：** 为其需要依赖的对象增加 setter 方法，可以通过 setter 方法将其依赖的对象注入到对象中
1. **接口注入：** 对于接口注入来说，如果被注入对象想要 IoC 容器为其注入依赖对象，就必须实现某个接口，这个接口提供了一个方法，用来为其注入依赖对象。但是从注入方式的使用来说，接口注入是现在不提倡的一种方式，基本处于"退役"状态，因为它强制被注入实现对象不必要的依赖。