---
title: Zookeeper简介
tags:
  - Zookeeper
categories:
  - Zookeeper
cover: 'https://img.jacian.com/note/img/20210524200352.jpg'
date: 2020-12-29 23:59:00
---

Zookeeper是⼀个开源的分布式协调服务，其设计⽬标是将那些复杂的且容易出错的分布式⼀致性服务封装起来，构成⼀个⾼效可靠的原语集，并以⼀些简单的接⼝提供给⽤户使⽤。

zookeeper是⼀个典型的分布式数据⼀致性的解决⽅案，分布式应⽤程序可以基于它实现诸如数据订阅/发布、负载均衡、命名服务、集群管理、分布式锁和分布式队列等功能。

## zookeeper基本概念

### 集群角色

 `Zookeeper`  中引入了了 `Leader` 、  `Follower` 、 `Observer` 三种⻆⾊。 `Leader` 服务器为客户端提供读和写服务，除 `Leader` 外，其他机器包括 `Follower` 和  `Observer`  都能提供读服务。唯⼀的区别在于 `Observer` 不参与 `Leader` 选举过程， 不参与写操作的过半写成功策略，因此 `Observer` 可以在不影响写性能的情况下提升集群的性能。

### 会话（session）

指客户端会话， **⼀个客户端连接是指客户端和服务端之间的⼀个TCP⻓连接** 

### 数据节点（Znode）

ZooKeeper将所有数据存储在内存中，数据模型是⼀棵树 （ `ZNode Tree` ），由斜杠（ `/` ）进⾏分割的路径，就是⼀个 `Znode` ，例如 `/app/path1` 。每个 `ZNode` 上都 会保存⾃⼰的数据内容，同时还会保存⼀系列属性信息。

### 版本

 `Zookeeper` 会为每个 `Znode` 维护 ⼀个叫作 `Stat `的数据结构， `Stat` 记录了这个 `ZNode` 的三个数据版本，分别是 `version` （当前 `ZNode` 的版 本）、 `cversion` （当前 `ZNode` ⼦节点的版本）、 `aversion` （当前 `ZNode` 的 `ACL` 版本）。

### 事件监听器（Watcher）

Wathcer（事件监听器），是Zookeeper中⼀个很重要的特性，Zookeeper允许⽤户在指定节点上注册 ⼀些Watcher，并且在⼀些特定事件触发的时候，Zookeeper服务端会将事件通知到感兴趣的客户端， 该机制是Zookeeper实现分布式协调服务的重要特性

### 权限控制（ACL）

Zookeeper采⽤ACL（Access Control Lists）策略来进⾏权限控制，其定义了如下五种权限：

1. **CREATE** ：创建⼦节点的权限。
2. **READ** ：获取节点数据和⼦节点列表的权限。
3. **WRITE** ：更新节点数据的权限。
4. **DELETE** ：删除⼦节点的权限。
5. **ADMIN** ：设置节点ACL的权限。 

> 其中需要注意的是， `CREATE` 和 `DELETE` 这两种权限都是针对⼦节点的权限控制

## 服务器角色（TODO）

### Leader

Leader服务器是Zookeeper集群工作的核心，主要工作有以下两个：

- 事务请求的唯一调度和矗立着，保证集群事务处理的顺序性
- 集群内部个服务器的调度者



### Follower

ollower服务器是Zookeeper集群状态中的跟随者，其主要⼯作有以下三个：

1. 处理客户端⾮事务性请求（读取数据），转发事务请求给Leader服务器。

2. 参与事务请求Proposal的投票。

3. 参与Leader选举投票。



### Observer

Observer是ZooKeeper⾃3.3.0版本开始引⼊的⼀个全新的服务器⻆⾊。从字⾯意思看，该服务器充当 了⼀个观察者的⻆⾊——其观察ZooKeeper集群的最新状态变化并将这些状态变更同步过来。

 Observer服务器在⼯作原理上和Follower基本是⼀致的，对于⾮事务请求，都可以进⾏独⽴的处理，⽽ 对于事务请求，则会转发给Leader服务器进⾏处理。 **和Follower唯⼀的区别在于，Observer不参与任何形式的投票** ，包括事务请求Proposal的投票和Leader选举投票。简单地讲，Observer服务器只提供 ⾮事务服务，通常⽤于在不影响集群事务处理能⼒的前提下提升集群的⾮事务处理能⼒。



## Zookeeper数据模型——Znode

 `Zookeeper` 中所有信息都被保存在一个个数据节点上，这些节点被称为 `Znode` 。 `Znode`  是 `Zookeeper` 中最小的存储单元，在 `Znode` 上又可以挂 `Znode` ，这样一层一层下去就形成了 Znode 树，称为 `Znode Tree` 。

![](Untitled.assets/img20201228161314.png)

### Znode 的类型

1. **持久节点：** 是Zookeeper中最常⻅的⼀种节点类型，所谓持久节点，就是指节点被创建后会⼀直存在务器，直到删除操作主动清除。

2. **持久顺序节点：** 就是有顺序的持久节点，节点特性和持久节点是⼀样的，只是额外特性表现在顺序上。 顺序特性实质是在创建节点的时候，会在节点名后⾯加上⼀个数字后缀，来表示其顺序。

3. **临时节点：** 就是会被⾃动清理掉的节点，它的⽣命周期和客户端会话绑在⼀起，客户端会话结束，节点会被删除掉。与持久性节点不同的是，临时节点不能创建⼦节点。

4. **临时顺序节点：** 就是有顺序的临时节点，和持久顺序节点相同，在其创建的时候会在名字后⾯加上数字后缀。

### Znode的状态信息

![](Untitled.assets/img20201228162420.png)

整个 ZNode 节点内容包括两部分：节点数据内容和节点状态信息。图中【持久节点顺序】 是数据内容，其他的属于状态信息。

- cZxid 就是 Create ZXID，表示节点被创建时的事务ID。 
- ctime 就是 Create Time，表示节点创建时间。 
- mZxid 就是 Modified ZXID，表示节点最后⼀次被修改时的事务ID。 
- mtime 就是 Modified Time，表示节点最后⼀次被修改的时间。 
- pZxid 表示该节点的⼦节点列表最后⼀次被修改时的事务 ID。只有⼦节点列表变更才会更新 pZxid， ⼦节点内容变更不会更新。 
- cversion 表示⼦节点的版本号。 
- dataVersion 表示内容版本号。 
- aclVersion 标识acl版本 ephemeralOwner 表示创建该临时节点时的会话 sessionID，如果是持久性节点那么值为 0 
- dataLength 表示数据⻓度。 
- numChildren 表示直系⼦节点数。

## Watcher-数据变更通知

Zookeeper使⽤Watcher机制实现分布式数据的发布/订阅功能。⼀个典型的发布/订阅模型系统定义了⼀种 ⼀对多的订阅关系，能够让多个订阅者同时监听某⼀个主题对象，当这个主题对象⾃身状态变化时，会通知所有订阅者，使它们能够做出相应的处理。

Zookeeper中引入了Watcher机制实现这种分布式的通知功能。Zookeeper允许客户端向服务端注册一个Watcher监听，当服务端的一些指定事件触发了这个Watcher，那么会向客户端发布一个事件通知来实现分布式的通知功能。

![](Untitled.assets/img20201228163122.png)

 `Zookeeper` 的 `Watcher` 机制主要包括**客户端线程、客户端WatcherManager、Zookeeper服务器**三部分。

具体⼯作流程为：

1. 客户端在向 `Zookeeper` 服务器注册的，同时会将 `Watcher` 对象存储在客户端的 `WatcherManager` 当中。
2. 当 `Zookeeper` 服务器触发 `Watcher` 事件后，会向客户端发送通知。
3. 客户端线程从 `WatcherManager` 中取出对应的 `Watcher` 对象来执⾏回调逻辑。

## ACL-保障数据的安全

从三个⽅⾯来理解ACL机制：**权限模式（Scheme）、授权对象（ID）、权限 （Permission）**，通常使⽤"scheme: id : permission"来标识⼀个有效的ACL信息。

### 权限模式：Scheme

1. IP：通过IP地址粒度来进⾏权限控制，如"ip:192.168.0.110"表示权限控制针对该IP地址， 同时IP模式可以⽀持按照⽹段⽅式进⾏配置，如 "ip:192.168.0.1/24" 表示针对 `192.168.0.*` 这个⽹段进⾏权限控制。

2. Digest：是最常⽤的权限控制模式，要更符合我们对权限控制的认识，其使 ⽤"username:password"形式的权限标识来进⾏权限配置，便于区分不同应⽤来进⾏权限控制。当我们通过“username:password”形式配置了权限标识后，Zookeeper会先后对其进⾏SHA-1加密 和BASE64编码。

3. World：是⼀种最开放的权限控制模式，这种权限控制⽅式⼏乎没有任何作⽤，数据节点的访问权限 对所有⽤户开放，即所有⽤户都可以在不进⾏任何权限校验的情况下操作ZooKeeper上的数据。 另外，World模式也可以看作是⼀种特殊的Digest模式，它只有⼀个权限标识，即“ `world:anyone` ”。

4. Super：顾名思义就是超级⽤户的意思，也是⼀种特殊的Digest模式。在Super模式下，超级 ⽤户可以对任意ZooKeeper上的数据节点进⾏任何操作。

**授权对象：ID**

| 权限模 式 | 授权对象                                                     |
| --------- | ------------------------------------------------------------ |
| IP        | 通常是⼀个IP地址或IP段：例如：192.168.10.110 或192.168.10.1/24 |
| Digest    | ⾃定义，通常是username:BASE64(SHA-1(username:password))例如： zm:sdfndsllndlksfn7c= |
| Digest    | 只有⼀个ID ：anyone                                          |
| Super     | 超级⽤户                                                     |

### 权限

权限就是指那些通过权限检查后可以被允许执⾏的操作。在ZooKeeper中，所有对数据的操作权限分为 以下五⼤类：

- CREATE（C）：数据节点的创建权限，允许授权对象在该数据节点下创建⼦节点。
- DELETE（D）：⼦节点的删除权限，允许授权对象删除该数据节点的⼦节点。
- READ（R）：数据节点的读取权限，允 许授权对象访问该数据节点并读取其数据内容或⼦节点列表等。
- WRITE（W）：数据节点的更新权 限，允许授权对象对该数据节点进⾏更新操作。
- ADMIN（A）：数据节点的管理权限，允许授权对象 对该数据节点进⾏ ACL 相关的设置操作。