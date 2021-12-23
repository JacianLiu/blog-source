---
title: Zookeeper一致性协议——ZAB
tags:
  - Zookeeper
categories:
  - Zookeeper
cover: 'https://img.jacian.com/note/img/20210524201258.jpg'
date: 2020-12-30 17:07:00
---
## ZAB协议简介

Zookeeper通过ZAB保证分布式事务的最终一致性。

ZAB全称Zookeeper Atomic Broadcast（ZAB，Zookeeper原子消息广播协议）

1. ZAB是一种专门为Zookeeper设计的一种支持 **崩溃恢复** 的 **原子广播协议** ，是Zookeeper保证数据一致性的核心算法。ZAB借鉴了Paxos算法，但它不是通用的一致性算法，是特别为Zookeeper设计的。

2. 基于ZAB协议，Zookeeper实现了⼀种主备模式的系统架构来保持集群中各副本之间的数据的⼀致性，表现形式就是使⽤⼀个单⼀的主进程（Leader服务器）来接收并处理客户端的所有事务请求（写请求），并采⽤ZAB的原⼦⼴播协议，将服务器数据的状态变更为事务 Proposal的形式⼴播到所有的Follower进程中。

## 问题提出

- 主从架构下，leader 崩溃，数据一致性怎么保证？
- 选举 leader 的时候，整个集群无法处理写请求的，如何快速进行 leader 选举？

## ZAB过程

ZAB协议的核⼼是 **定义了对于那些会改变Zookeeper服务器数据状态的事务请求的处理⽅式**

![](https://img.jacian.com/note/img20201228214732.png)

所有事务必须由一个 **全局唯一的服务器来协调处理** ，这样的服务器被称为Leader服务器，余下的服务器则称为Follower服务器

1. Leader服务器负责将一个客户端事务请求转化为一个事务Proposal（提案），并将该Proposal分发给集群中所有的Follower服务器
2. Leader服务器等待所有Follower服务器的反馈，一旦超过半数的Follower服务器进行了正确的反馈后，Leader就会向所有的Follower服务器发送Commit消息，要求将前一个Proposal进行提交。

## ZAB协议内容简介

ZAB协议包括两种基本的模式： **崩溃恢复** 和 **消息广播**

### 消息广播

当集群中有过半的Follower服务器完成了和Leader服务器的状态同步，那么整个服务框架就可以进入 **消息广播模式** 。

当一台遵守ZAB协议的服务器启动后加入到集群中，如果此时集群中已经存在一个Leader服务器在负责进行消息广播，那么加入的服务器会自觉的进入 **数据恢复模式： 找到Leader 所在的服务器，并与其进⾏数据同步，数据同步完成后参与到消息⼴播流程中。**



ZAB协议的消息广播使用原子广播协议， **类似一个二阶段提交的过程** ，但又有所不同。

1. 二阶段提交中，需要所有参与者反馈ACK后再发送Commit请求。要求所有参与者要么成功，要么失败。这样会产生严重的阻塞问题
2. ZAB协议中，Leader等待半数以上的Follower成功反馈ACK即可，不需要收到全部的Follower反馈ACK。

**消息广播过程：**

1. 客户端发起写请求
2. Leader将客户端请求信息转化为事务Proposal，同时为每个Proposal分配一个事务ID（Zxid）
3. Leader为每个Follower单独分配一个FIFO的队列，将需要广播的Proposal依次放入到队列中
4. Follower接收到Proposal后，首先将其以事务日志的方式写入到本地磁盘中，写入成功后给Leader反馈一个ACK响应
5. Leader接收到半数以上Follower的ACK响应后，即认为消息发送成功，可以发送Commit消息
6. Leader向所有Follower广播Commit消息，同时自身也会完成事务提交。Follower接收到Commit消息后也会完成事务的提交

![](https://img.jacian.com/note/img20201229220334.jpg)

### 崩溃恢复

在整个服务框架启动过程中，如果Leader服务器出现网络中断、崩溃退出或重启等异常情况，ZAB协议就会进入崩溃恢复模式。同时选举出新的Leader服务器。

当选举产生了新的Leader服务器，同时集群中已经有过半的机器与该Leader服务器完成了状态同步（数据同步）之后，ZAB协议会退出恢复模式。  



1. 在ZAB协议中，为了保证程序的正确运⾏，整个恢复过程结束后需要选举出⼀个新的Leader 服务器。
2. Leader选举算法不仅仅需要让Leader⾃身知道已经被选举为Leader，同时还需要让集群中的所有其他机器也能够快速地感知到选举产⽣出来的新Leader服务器。

### ZAB保证数据一致性

ZAB协议规定了 **如果⼀个事务Proposal在⼀台机器上被处理成功，那么应该在所有的机器上都被处理成功，哪怕机器出现故障崩溃。** 针对这些情况ZAB协议需要保证以下条件：

- 已经在Leader服务器上提交的事务最终被所有服务器都提交。

    假设⼀个事务在 Leader 服务器上被提交了，并且已经得到过半 Folower 服务器的Ack反馈，但是在它 将Commit消息发送给所有Follower机器之前，Leader服务器挂了

- 丢弃只在Leader服务器上被提出（未提交）的事务。

    假设初始的 Leader 服务器 Server1 在提出了⼀个事务Proposal3 之后就崩溃退出 了，从⽽导致集群中的其他服务器都没有收到这个事务Proposal3。于是，当 Server1 恢复过来再次加 ⼊到集群中的时候，ZAB 协议需要确保丢弃Proposal3这个事务。

**综上所述，ZAB的选举出来的Leader必须满足以下条件：**

能够确保提交已经被 Leader 提交的事务 Proposal，同时丢弃已经被跳过的事务 Proposal。即：

1. **新选举出来的 Leader 不能包含未提交的 Proposal。** 
2. **新选举的 Leader 节点中含有最大的 zxid** 。

### ZAB如何数据同步

所有正常运行的服务器要么成为Leader，要么成为Follower并和Leader保持同步。

1. 完成Leader选举（新的 Leader 具有最高的zxid）之后，在正式开始⼯作（接收客户端请求）之前，Leader服务器会⾸先确认事务⽇志中的所有Proposal是否都已经被集群中过半的机器提交了，即 **是否完成数据同步** 。

2. Leader服务器需要确保所有的Follower服务器能够接收到每⼀条事务Proposal，并且能够正确地将所有已经提交了的事务Proposal应⽤到内存数据中。等到 Follower服务器将所有其尚未同步的事务 Proposal 都从 Leader 服务器上同步过来并成功应⽤到本地数据库中后，Leader服务器就会将该Follower服务器加⼊到真正的可⽤Follower列表中，并开始之后的其他流程。

## ZAB运行时状态

ZAB协议设计中，每个进程都有可能处于如下三种状态之一：

- LOOKING：Leader选举状态，正在寻找Leader
- FOLLOWING：当前节点是Follower。与Leader服务器保持同步状态
- LEADING：当前节点是Leader，作为主进程领导状态。

### ZAB状态的切换

**启动时的状态转换**

1. 所有进程的初始状态都是LOOKING状态，此时不存在Leader。

2. 接下来，进程会试图选举出来一个新的Leader，Leader切换为LEADING状态，其它进程发现已经选举出新的Leader，那么它就会切换到FOLLOWING状态，并开始与Leader保持同步。

3. 处于FOLLOWING状态的进程称为Follower，LEADING状态的进程称为Leader。
4. 当Leader崩溃或者放弃领导地位时，其余的Follower进程就会切换到LOOKING状态开始新一轮的Leader选举。

**运行过程中的状态转换**

**一个Follower只能和一个Leader保持同步，Leader进程和所有的Follower进程之间通过心跳监测机制来感知彼此的情况。**

1. 若Leader能够在超时时间内正常的收到心跳检测，那么Follower就会一直与该Leader保持连接。
2. 如果在指定时间内Leader无法从过半的Follower进程那里接收到心跳检测，或者TCP连接断开，那么Leader会放弃当前周期的领导，并转换为LOOKING状态；其他的Follower也会选择放弃这个Leader，同时转换为LOOKING状态，之后会进行新一轮的Leader选举

## ZAB的四个阶段

### 选举阶段（Leader Election）

节点在一开始都处于选举阶段，只要有一个节点超过半数阶段的票数，它就可以当选准Leader，**只有到达第三个阶段（同步阶段），这个准Leader才会成为真正的Leader。**

> **这一阶段的目的就是为了选出一个准Leader，然后进入下一阶段。**

### 发现阶段

在这个阶段中，Followers和上一轮选举出的准Leader进行通信，同步Followers最近接受的事务Proposal。这个阶段主要目的是发现当前大多数节点接受的最新提议，并且准Leader生成新的epoch，让Followers接受，更新它们的acceptedEpoch。

一个Follower只会连接一个Leader，如果有一个节点F认为另一个Follower P是Leader，F在尝试连接P时会被拒绝，F被拒绝后，就会进入选举阶段。

![ZAB-发现阶段](https://img.jacian.com/note/img20201230163738.jpg)



### 同步阶段

**同步阶段主要是利用 Leader 前一阶段获得的最新 Proposal 历史，同步集群中所有的副本**。

只有当 quorum（超过半数的节点） 都同步完成，准 Leader 才会成为真正的 Leader。Follower 只会接收 zxid 比自己 lastZxid 大的 Proposal。

![ZAB同步阶段](https://img.jacian.com/note/img20201230165146.jpg)



### 广播阶段

到了这个阶段，Zookeeper 集群才能正式对外提供事务服务，并且 Leader 可以进行消息广播。同时，如果有新的节点加入，还需要对新节点进行同步。
 需要注意的是，Zab 提交事务并不像 2PC 一样需要全部 Follower 都 Ack，只需要得到 quorum（超过半数的节点）的Ack 就可以。

![ZAB广播阶段](https://img.jacian.com/note/img20201230165509.jpg)



## ZAB协议实现

 Java 版本的ZAB协议的实现跟上面的定义略有不同，选举阶段使用的是 **Fast Leader Election**（FLE），它包含了步骤2的发现职责。因为FLE会选举拥有最新提议的历史节点作为 Leader，这样就省去了发现最新提议的步骤。

实际的实现将 **发现和同步阶段合并为 Recovery Phase（恢复阶段）** ，所以，Zab 的实现实际上有三个阶段。

### 快速选举（Fast Leader Election）

前面提到的 FLE 会选举拥有最新Proposal history （lastZxid最大）的节点作为 Leader，这样就省去了发现最新提议的步骤。 **这是基于拥有最新提议的节点也拥有最新的提交记录**

**成为Leader的条件：**

1. 选epoch最大的
2. epoch相等，选zxid最大的
3. epoch和zxid都相等，选server_id最大的（zoo.cfg 中配置的 myid）

节点在选举开始时，都默认投票给自己，当接收其他节点的选票时，会根据上面的 **Leader条件** 判断并且更改自己的选票，然后重新发送选票给其他节点。**当有一个节点的得票超过半数，该节点会设置自己的状态为 Leading ，其他节点会设置自己的状态为 Following**。

![](https://img.jacian.com/note/img20201229225336.png)

### 恢复阶段（Recovery Phase）

这一阶段 Follower 发送他们的 lastZxid 给 Leader，Leader 根据 lastZxid 决定如何同步数据。这里的实现跟前面的 阶段 3 有所不同：Follower 收到 TRUNC 指令会终止 `L.lastCommitedZxid` 之后的 Proposal ，收到 DIFF 指令会接收新的 Proposal。

> history.lastCommittedZxid：最近被提交的提议的 zxid
> history.oldThreshold：被认为已经太旧的已提交提议的 zxid

![](https://img.jacian.com/note/img20201229225342.png)

### 广播阶段（Broadcast Phase）

> 参考 4.1 [ZAB协议内容#消息广播]

## ZAB与Paxos的联系和区别

### 联系

1. 都存在一个类似Leader进程的角色，由其负责协调多个Follower进程的运行
2. Leader进程都会等待超过半数的Follower作出正确的反馈后，才会将一个提议进行提交（**过半原则**）
3. 在ZAB中，每个Proposal中都包含了一个epoch值，用来代表当前Leader周期，在Paxos中同样存在这样的一个表示，名字为 Ballot。

### 区别

1. Paxos算法中，新选举产生的主进程会进行两个阶段的工作；第一阶段称为读阶段：新的主进程和其他进程通信来收集主进程提出的提议，并将它们提交。第二阶段称为写阶段：当前主进程开始提出自己的提议。
2. ZAB协议在Paxos基础上添加了同步阶段，此时，新的Leader会确保存在过半的Follower已经提交了之前Leader周期中的所有事物Proposal。这一同步阶段的引入，能够有效保证，Leader在新的周期中提出事务Proposal之前，所有的进程都已经完成了对之前所有事务Proposal的提交。

总的来说，ZAB协议和Paxos算法的本质区别在于两者的设计目的不一样：ZAB协议主要用于构建一个高可用的分布式数据主备系统，而Paxos算法则用于构建一个分布式的一致性状态机系统。

## 总结

问题解答：

- 主从架构下，leader 崩溃，数据一致性怎么保证？

    leader 崩溃之后，集群会选出新的 leader，然后就会进入恢复阶段，新的 leader 具有所有已经提交的提议，因此它会保证让 followers 同步已提交的提议，丢弃未提交的提议（以 leader 的记录为准），这就保证了整个集群的数据一致性。

- 选举 leader 的时候，整个集群无法处理写请求的，如何快速进行 leader 选举？

    这是通过 Fast Leader Election 实现的，leader 的选举只需要超过半数的节点投票即可，这样不需要等待所有节点的选票，能够尽早选出 leader。
