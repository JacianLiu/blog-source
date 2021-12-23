---
title: Docker搭建Zookeeper&Kafka集群
tags:
  - Docker
  - Kafka
  - Zookeeper
categories:
  - Docker
toc: true
sidebar: right
cover: 'https://img.jacian.com/FuAw-0Y5N9WOUVU7ks1pVeK5fZtZ'
article-thumbnail: 'false'
date: 2019-08-27 13:29:04
---

**前排提示：最新的`docker-compole.yml`请去github获取，`README`有相应的操作步骤。**
Github地址：https://github.com/JacianLiu/docker-compose
>**最近在学习`Kafka`，准备测试集群状态的时候感觉无论是开三台虚拟机或者在一台虚拟机开辟三个不同的端口号都太麻烦了（嗯。。主要是懒）。**

<!-- more -->

# 环境准备
<div class="note info"><p>一台可以上网且有CentOS7虚拟机的电脑</p></div>
> 为什么使用虚拟机？因为使用的笔记本，所以每次连接网络IP都会改变，还要总是修改配置文件的，过于繁琐，不方便测试。（通过Docker虚拟网络的方式可以避免此问题，当时实验的时候没有了解到）
# Docker 安装
> 如果已经安装Docker请忽略此步骤

1. Docker支持以下的CentOS版本：
2. CentOS 7 (64-bit)：要求系统为64位、系统内核版本为 3.10 以上。
3. CentOS 6.5（64-bit）或更高的版本：要求系统为64位、系统内核版本为 2.6.32-431 或者更高版本。
4. CentOS 仅发行版本中的内核支持 Docker。

## yum安装
Docker 要求 CentOS 系统的内核版本高于 3.10 ，查看上文的前提条件来验证你的CentOS 版本是否支持 Docker 。
```
# 查看内核版本
$ uname -a
```
```
#安装 Docker
$ yum -y install docker
```
```
#启动 Docker 后台服务
$ service docker start
```
```
# 由于本地没有hello-world这个镜像，所以会下载一个hello-world的镜像，并在容器内运行。
$ docker run hello-world
```

## 脚本安装
1. 使用 sudo 或 root 权限登录 Centos。
2. 确保 yum 包更新到最新。
```
$ sudo yum update
```
3. 获取并执行 Docker 安装脚本。
```
$ curl -fsSL https://get.docker.com -o get-docker.sh
# 执行这个脚本会添加 docker.repo 源并安装 Docker。
$ sudo sh get-docker.sh
```

## 启动Docker

```
$ sudo systemctl start docker
```
```
# 验证 docker 是否安装成功并在容器中执行一个测试的镜像。
$ sudo docker run hello-world
$ docker ps
```

## 镜像加速
开始让我配置国内镜像源的时候我是拒绝的，但是使用之后发现那下载速度 `duang~` 的一下就上去了。所以强烈建议大家配置国内镜像源。
打开/创建 ` /etc/docker/daemon.json` 文件，添加以下内容：
```JavaScript
{
  "registry-mirrors": ["http://hub-mirror.c.163.com"]
}
```

# Zookeeper集群搭建
<div class=“note info”><p>Zookeeper镜像：zookeeper:3.4</p></div>
## 镜像准备
```
$ docker pull zookeeper:3.4
```
> 查找镜像可以去 https://hub.docker.com/
docker pull images:TAG // 代表拉取 `TAG` 版本的 `image` 镜像

## 建立独立Zookeeper容器
我们首先用最简单的方式创建一个独立的`Zookeeper`节点，然后我们根据这个例子创建出其他的节点。
```
$ docker run --name zookeeper -p 2181:2181 -d zookeeper:3.4
```
默认的，容器内配置文件在， `/conf/zoo.cfg`，数据和日志目录默认在 `/data` 和 `/datalog`，需要的话可以将上述目录映射到宿主机。
**参数解释**
> 1. --name：指定容器名字
> 2. -p：为容器暴露出来的端口分配端口号
> 3. -d：在后台运行容器并打印容器ID

## 集群搭建
其它节点的`Zookeeper`容器创建方式与创建独立容器类似，需要注意的是，要分别指定节点的`id`和修改文件中多节点的配置，相应的创建命令如下：

### 新建docker网络
```
$ docker network create zoo_kafka
$ docker network ls
```

### Zookeeper容器1
```
$ docker run -d \
     --restart=always \
     -v /opt/docker/zookeeper/zoo1/data:/data \
     -v /opt/docker/zookeeper/zoo1/datalog:/datalog \
     -e ZOO_MY_ID=1 \
     -p 2181:2181 \
     -e ZOO_SERVERS="server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888" \
     --name=zoo1 \
     --net=viemall-zookeeper \
     --privileged \
     zookeeper:3.4
```

### Zookeeper容器2
```
$ docker run -d \
     --restart=always \
     -v /opt/docker/zookeeper/zoo2/data:/data \
     -v /opt/docker/zookeeper/zoo2/datalog:/datalog \
     -e ZOO_MY_ID=2 \
     -p 2182:2181 \
     -e ZOO_SERVERS="server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888" \
     --name=zoo2 \
     --net=viemall-zookeeper \
     --privileged \
     zookeeper:3.4
```

### Zookeeper容器3

```
$ docker run -d \
     --restart=always \
     -v /opt/docker/zookeeper/zoo3/data:/data \
     -v /opt/docker/zookeeper/zoo3/datalog:/datalog \
     -e ZOO_MY_ID=3 \
     -p 2183:2181 \
     -e ZOO_SERVERS="server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888" \
     --name=zoo3 \
     --net=viemall-zookeeper \
     --privileged \
     zookeeper:3.4
```

> 这种方式虽然也实现了我们想要的，但是步骤过于繁琐，而且维护起来麻烦（懒癌晚期），所以我们使用 `docker-compose` 的方式来实现。

## docker-compose 搭建zookeeper集群

### 新建docker网络
```
$ docker network create --driver bridge --subnet 172.23.0.0/25 --gateway 172.23.0.1  zoo_kafka
$ docker network ls
```
### 编写 docker-compose.yml 脚本
**使用方式：**
1. 安装 `docker-compose`
```
# 获取脚本
$ curl -L https://github.com/docker/compose/releases/download/1.25.0-rc2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
# 赋予执行权限
$chmod +x /usr/local/bin/docker-compose
```
2. 任意目录下新建 `docker-compose.yml` 文件，复制以下内容
3. 执行命令 `docker-compose up -d `

**命令对照**

|命令|解释|
|----|----|
|docker-compose up|启动所有容器|
|docker-compose up -d|后台启动并运行所有容器|
|docker-compose up --no-recreate -d|不重新创建已经停止的容器|
|docker-compose up -d test2|只启动test2这个容器|
|docker-compose stop|停止容器|
|docker-compose start|启动容器|
|docker-compose down|停止并销毁容器|

`docker-compose.yml`下载地址：https://github.com/JacianLiu/docker-compose/tree/master/zookeeper
**`docker-compose.yml`详情**
```yaml
version: '2'
services:
  zoo1:
    image: zookeeper:3.4 # 镜像名称
    restart: always # 当发生错误时自动重启
    hostname: zoo1
    container_name: zoo1
    privileged: true
    ports: # 端口
      - 2181:2181
    volumes: # 挂载数据卷
      - ./zoo1/data:/data
      - ./zoo1/datalog:/datalog 
    environment:
      TZ: Asia/Shanghai
      ZOO_MY_ID: 1 # 节点ID
      ZOO_PORT: 2181 # zookeeper端口号
      ZOO_SERVERS: server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888 # zookeeper节点列表
    networks:
      default:
        ipv4_address: 172.23.0.11

  zoo2:
    image: zookeeper:3.4
    restart: always
    hostname: zoo2
    container_name: zoo2
    privileged: true
    ports:
      - 2182:2181
    volumes:
      - ./zoo2/data:/data
      - ./zoo2/datalog:/datalog
    environment:
      TZ: Asia/Shanghai
      ZOO_MY_ID: 2
      ZOO_PORT: 2181
      ZOO_SERVERS: server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888
    networks:
      default:
        ipv4_address: 172.23.0.12

  zoo3:
    image: zookeeper:3.4
    restart: always
    hostname: zoo3
    container_name: zoo3
    privileged: true
    ports:
      - 2183:2181
    volumes:
      - ./zoo3/data:/data
      - ./zoo3/datalog:/datalog
    environment:
      TZ: Asia/Shanghai
      ZOO_MY_ID: 3
      ZOO_PORT: 2181
      ZOO_SERVERS: server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888
    networks:
      default:
        ipv4_address: 172.23.0.13

networks:
  default:
    external:
      name: zoo_kafka
```

## 验证
从图中我们可以看出，有一个`Leader`，两个`Flower`，至此我们的`Zookeeper`集群就已经搭建好了
![Zookeeper](https://img.jacian.com/1566900790498.png)

# Kafka集群搭建
有了上面的基础，再去搞`Kafka`集群还是问题吗？其实就是几个变量值不同而已。

有了上边的例子，就不费劲去搞单节点的`Kafka`了，直接使用`docker-compose`的方式，部署三个节点，其实方式大同小异，上边也说到，其实就是一些属性不同而已；这时候我们就不需要再去新建 Docker 网络了，直接使用前边搭建 `Zookeeper` 集群时创建的网络即可！

## 环境准备
> Kafka镜像：wurstmeister/kafka
> Kafka-Manager镜像：sheepkiller/kafka-manager

```
# 不指定版本默认拉取最新版本的镜像
docker pull wurstmeister/kafka
docker pull sheepkiller/kafka-manager
```

## 编写 docker-compose.yml 脚本
**使用方式：**
1. 安装 `docker-compose`
```
# 获取脚本
$ curl -L https://github.com/docker/compose/releases/download/1.25.0-rc2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
# 赋予执行权限
$chmod +x /usr/local/bin/docker-compose
```
2. 任意目录下新建 `docker-compose.yml` 文件，复制以下内容
3. 执行命令 `docker-compose up -d `

**命令对照**
|命令|解释|
|-|-|
|docker-compose up|启动所有容器|
|docker-compose up -d|后台启动并运行所有容器|
|docker-compose up --no-recreate -d|不重新创建已经停止的容器|
|docker-compose up -d test2|只启动test2这个容器|
|docker-compose stop|停止容器|
|docker-compose start|启动容器|
|docker-compose down|停止并销毁容器|


`docker-compose.yml`下载地址：https://github.com/JacianLiu/docker-compose/tree/master/zookeeper
**`docker-compose.yml`详细内容**
```yaml
version: '2'

services:
  broker1:
    image: wurstmeister/kafka
    restart: always
    hostname: broker1
    container_name: broker1
    privileged: true
    ports:
      - "9091:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_LISTENERS: PLAINTEXT://broker1:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker1:9092
      KAFKA_ADVERTISED_HOST_NAME: broker1
      KAFKA_ADVERTISED_PORT: 9092
      KAFKA_ZOOKEEPER_CONNECT: zoo1:2181/kafka1,zoo2:2181/kafka1,zoo3:2181/kafka1
      JMX_PORT: 9988
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./broker1:/kafka/kafka\-logs\-broker1
    external_links:
    - zoo1
    - zoo2
    - zoo3
    networks:
      default:
        ipv4_address: 172.23.0.14

  broker2:
    image: wurstmeister/kafka
    restart: always
    hostname: broker2
    container_name: broker2
    privileged: true
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_LISTENERS: PLAINTEXT://broker2:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker2:9092
      KAFKA_ADVERTISED_HOST_NAME: broker2
      KAFKA_ADVERTISED_PORT: 9092
      KAFKA_ZOOKEEPER_CONNECT: zoo1:2181/kafka1,zoo2:2181/kafka1,zoo3:2181/kafka1
      JMX_PORT: 9988
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./broker2:/kafka/kafka\-logs\-broker2
    external_links:  # 连接本compose文件以外的container
    - zoo1
    - zoo2
    - zoo3
    networks:
      default:
        ipv4_address: 172.23.0.15

  broker3:
    image: wurstmeister/kafka
    restart: always
    hostname: broker3
    container_name: broker3
    privileged: true
    ports:
      - "9093:9092"
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_LISTENERS: PLAINTEXT://broker3:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker3:9092
      KAFKA_ADVERTISED_HOST_NAME: broker3
      KAFKA_ADVERTISED_PORT: 9092
      KAFKA_ZOOKEEPER_CONNECT: zoo1:2181/kafka1,zoo2:2181/kafka1,zoo3:2181/kafka1
      JMX_PORT: 9988
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./broker3:/kafka/kafka\-logs\-broker3
    external_links:  # 连接本compose文件以外的container
    - zoo1
    - zoo2
    - zoo3
    networks:
      default:
        ipv4_address: 172.23.0.16

  kafka-manager:
    image: sheepkiller/kafka-manager:latest
    restart: always
    container_name: kafka-manager
    hostname: kafka-manager
    ports:
      - "9000:9000"
    links:            # 连接本compose文件创建的container
      - broker1
      - broker2
      - broker3
    external_links:   # 连接本compose文件以外的container
      - zoo1
      - zoo2
      - zoo3
    environment:
      ZK_HOSTS: zoo1:2181/kafka1,zoo2:2181/kafka1,zoo3:2181/kafka1
      KAFKA_BROKERS: broker1:9092,broker2:9092,broker3:9092
      APPLICATION_SECRET: letmein
      KM_ARGS: -Djava.net.preferIPv4Stack=true
    networks:
      default:
        ipv4_address: 172.23.0.10

networks:
  default:
    external:   # 使用已创建的网络
      name: zoo_kafka
```
## 验证
我们打开`kafka-manager`的管理页面，访问路径是，宿主机ip:9000；
![Kafka-Manager](https://img.jacian.com/1566902368519.png)
如果所示，填写上`Zookeeper`集群的地址，划到最下边点击`save`
点击刚刚添加的集群，可以看到，集群中有三个节点
![Kafka-Cluster](https://img.jacian.com/1566902527518.png)


# 搭建过程中遇到的问题
1. 挂载数据卷无限重启，查看`log`提示：chown: changing ownership of ‘/var/lib/mysql/....‘: Permission denied
解决方式：
	- 在docker run中加入 --privileged=true  给容器加上特定权限
	- 临时关闭selinux： setenforce 0
	- 添加selinux规则，改变要挂载的目录的安全性文本
2. kafka-manager报jmx相关错误，
解决方法：
	- 在每一个kafka节点加上环境变量  JMX_PORT=端口
	- 加上之后发现连不上，又是网络连接的问题，于是又把每个jmx端口暴露出来，然后fire-wall放行， 解决问题。
	- `KAFKA_ADVERTISED_HOST_NAME`这个最好设置宿主机的ip,宿主机以外的代码或者工具来连接，后面的端口也需要设置暴露的端口。 

```java
[error] k.m.j.KafkaJMX$ - Failed to connect to service:jmx:rmi:///jndi/rmi://9.11.8.48:-1/jmxrmi java.lang.IllegalArgumentException: requirement failed: No jmx port but jmx polling enabled!
```

3. 在容器中查看`topic`时报以下错误（不仅仅是topic的命令，好像所有的都会出错）
```
$ bin/kafka-topics.sh --list --zookeeper zoo1:2181/kafka1,zoo2:2181/kafka1,zoo3:2181/kafka1
# 以下是错误
Error: Exception thrown by the agent : java.rmi.server.ExportException: Port already in use: 7203; nested exception is:
        java.net.BindException: Address already in use
```
解决方法：
	在命令前加上`unset JMX_PORT;`指令，上边的命令改造为：
```
$ unset JMX_PORT;bin/kafka-topics.sh --list --zookeeper zoo1:2181/kafka1,zoo2:2181/kafka1,zoo3:2181/kafka1
```

# 附：Docker常用指令
```
# 查看所有镜像
docker images
# 查看所有运行中的容器
docker ps
# 查看所有容器
docker ps -a
# 获取所有容器ip
$ docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
# 查看容器内部日志
$ docker logs -f <容器ID>
# 进入容器内部
$ docker exec -it <容器ID> /bin/basj
# 创建容器 -d代表后台启动
docker run --name <容器名称> -e <参数> -v <挂载数据卷> <容器ID>
# 重启容器
docker restart <容器ID>
# 关闭容器
docker stop <容器id>
# 运行容器
docker start <容器id>
```