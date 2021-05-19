---
title: 基于Netty-SocketIO的主动推送服务
tags:
  - WebSocket
  - SocketIO
categories:
  - WebSocket
toc: true
category: WebSocket
date: 2019-07-13 22:59:00
---

## 背景

前端时间，公司开发了一款主动服务的机器人的程序，讲产生的消息通过服务端主动推送到客户端(H5、IOS、Android)，支持用户的个性化开关设置，用户可自由选择接受的消息类型；同时支持用户主动提问；在此记录下整个部署以及实现的大致思路；

> 同时感谢我的Leader给予的帮助。

<!-- more -->

## 部署

#### Nginx配置

- 为了保持长连接有效，配置HTTP版本1.1；
- 配置`Upgrade`和`Connection`响应头信息；

完整配置如下：

```nginx
location / {
    proxy_pass http://nodes;

    # enable WebSockets
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

#### Socket配置

Socket配置类

```java
public class WebSocketConfig {

    private Logger log = LoggerFactory.getLogger(WebSocketConfig.class);

    @Value("${wss.server.host}")
    private String host;

    @Value("${wss.server.port}")
    private Integer port;

    @Value("${redis.passwd}")
    private String redisPasswd;

    @Value("${redis.address}")
    private String redisAddress;

    @Bean
    public PubSubStore pubSubStore() {
        return socketIOServer().getConfiguration().getStoreFactory().pubSubStore();
    }

    @Bean
    public SocketIOServer socketIOServer() {


        Config redissonConfig = new Config();
      	// 高版本需求 redis:// 前缀
      redissonConfig.useSingleServer().setPassword("xxx").setAddress("redis://xxx:xx").setDatabase();

        RedissonClient redisson = Redisson.create(redissonConfig);
        RedissonStoreFactory redisStoreFactory = new RedissonStoreFactory(redisson);


        Configuration config = new Configuration();
        config.setHostname(host);
        config.setPort(port);
        config.setOrigin(origin);
        config.setHttpCompression(false);
        config.setWebsocketCompression(false);

        config.setStoreFactory(redisStoreFactory);

        // 注意如果开放跨域设置，需要设置为null而不是"*"
        config.setOrigin(null);
        // 协议升级超时时间（毫秒），默认10000。HTTP握手升级为ws协议超时时间
        config.setUpgradeTimeout(10000);
        // Ping消息间隔（毫秒），默认25000。客户端向服务器发送一条心跳消息间隔
        config.setPingInterval(25000);
        // Ping消息超时时间（毫秒），默认60000，这个时间间隔内没有接收到心跳消息就会发送超时事件
        config.setPingTimeout(60000);

        /** 异常监听事件，必须覆写全部方法 */
        config.setExceptionListener(new ExceptionListener(){
            @Override
            public void onConnectException(Exception e, SocketIOClient client) {
                ResponseMessage error = ResponseMessage.error(-1, "连接异常！");
                client.sendEvent("exception", JSON.toJSON(new Response<String>(error, "连接异常！")));
            }
            @Override
            public void onDisconnectException(Exception e, SocketIOClient client) {
                ResponseMessage error = ResponseMessage.error(-1, "断开异常！");
                client.sendEvent("exception",JSON.toJSON(new Response<String>(error, "连接异常！")));
            }
            @Override
            public void onEventException(Exception e, List<Object> data, SocketIOClient client) {
                ResponseMessage error = ResponseMessage.error(-1, "服务器异常！");
                client.sendEvent("exception",JSON.toJSON(new Response<String>(error, "连接异常！")));
            }
            @Override
            public void onPingException(Exception e, SocketIOClient client) {
                ResponseMessage error = ResponseMessage.error(-1, "PING 超时异常！");
                client.sendEvent("exception",JSON.toJSON(new Response<String>(error, "PING 超时异常！")));
            }
            @Override
            public boolean exceptionCaught(ChannelHandlerContext ctx, Throwable e) {
                return false;
            }
        });
      // 类似于过滤器设置，此处不作处理
       config.setAuthorizationListener(data -> {
//            // 可以使用如下代码获取用户密码信息
//            String appId = data.getSingleUrlParam("appId");
//            String source = data.getSingleUrlParam("source");
//            log.info("token {}, client {}", appId, source);
            return true;
        });

        return new SocketIOServer(config);
    }

    @Bean
    public SpringAnnotationScanner springAnnotationScanner(SocketIOServer socketServer) {
        return new SpringAnnotationScanner(socketServer);
    }
}
```

Socket启动类

```java
@Log4j2
@Component
@Order(value=1)
public class ServerRunner implements CommandLineRunner {

    private final SocketIOServer server;


    @Autowired
    public ServerRunner(SocketIOServer server) {
        this.server = server;
    }

    @Override
    public void run(String... args) throws Exception {
        server.start();
        log.info("socket.io启动成功！");
    }
}
```

#### 最终架构

![](https://img.jacian.com/20190606145853.png)



## 实现过程

主动推送服务监听作为KafKa消费者，数据生产者讲加工好的数据推到KafKa中，消费者监听到消息广播给客户端；推送时在数据库查询用户对应的个性化设置，仅推送客户端选择接受的消息；

由于主动推送服务部署了多个节点，而多个节点分配在同一个KafKa消费组中，这样会引起多个节点仅消费到全部消息的一部分的问题；这里使用`Redis`的`发布/订阅`的机制解决了这个问题：当各个节点消费到消息之后，将消息发布之后，其它节点订阅该`Topic`将消息发送给各自节点上连接的客户端，在这里各个节点即是发布者，又是订阅者；

> 从数据的产生，到消费

![](https://img.jacian.com/20190606150018.png)



## 使用Redisson的Topic实现分布式发布/订阅

Redisson为了方便Redis中的`发布/订阅`机制的使用，将其封装成Topic，并提供了代码级别的`发布/订阅`操作，如此一来多个JVM进程连接到Redis（单机/集群）后，便可以实现在一个JVM进程中`发布`的`Topic`，在其他已经`订阅`了该主题的JVM进程中就能及时收到消息。

在Netty-SocketIO整合了`Redisson`之后，内部也使用了`发布/订阅`机制

##### 消息的发布

```java

public void sendMessageToAllClient(String eventType, String message, String desc) {
    Collection<SocketIOClient> clients = server.getBroadcastOperations().getClients();
    for(final SocketIOClient client : clients){
      // Do Somthing
    }

    Packet packet = new Packet(PacketType.MESSAGE);
    packet.setData(new BroadcastMessage(message, eventType, desc));
    publishMessage(packet);
}

private void publishMessage(Packet packet) {
    DispatchMessage dispatchMessage = new DispatchMessage("", packet, "");
    pubSubStore.publish(PubSubType.DISPATCH, dispatchMessage);
    BroadcastMessage broadcastMessage = dispatchMessage.getPacket().getData();

}
```

##### 消息的订阅

```java
@PostConstruct
public void init() {
  pubSubStore.subscribe(PubSubType.DISPATCH, dispatchMessage -> {
      BroadcastMessage messageData = dispatchMessage.getPacket().getData();
    
      Collection<SocketIOClient> clients = server.getBroadcastOperations().getClients();

      for(final SocketIOClient client : clients){
        // DO Somthing
      }, DispatchMessage.class);
}
```