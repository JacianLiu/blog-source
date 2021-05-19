---
title: SpringBoot中使用Redis数据库
tags:
  - SpringBoot
categories:
  - SpringBoot
toc: true
category: SpringBoot
date: 2019-02-28 15:00:00
cover: https://img.jacian.com/Fq4RJGhYPPg3JLjFikPDYbHg4yp1
article-thumbnail: 'false'
---

Spring Boot中除了对常用的关系型数据库提供了优秀的自动化支持之外，对于很多NoSQL数据库一样提供了自动化配置的支持，包括：Redis, MongoDB, Elasticsearch, Solr和Cassandra。<!-- more -->

## 使用Redis

Redis是一个开源的使用ANSI C语言编写、支持网络、可基于内存亦可持久化的日志型、Key-Value数据库。

- [Redis官网](http://redis.io/)
- [Redis中文社区](http://www.redis.cn/)

#### 引入依赖

Spring Boot提供的数据访问框架Spring Data Redis基于Jedis。可以通过引入`spring-boot-starter-redis`来配置依赖关系。

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-redis</artifactId>
</dependency>
```

#### 参数配置

按照惯例在`application.properties`中加入Redis服务端的相关配置，具体说明如下：

```
# REDIS (RedisProperties)
# Redis数据库索引（默认为0）
spring.redis.database=0
# Redis服务器地址
spring.redis.host=localhost
# Redis服务器连接端口
spring.redis.port=6379
# Redis服务器连接密码（默认为空）
spring.redis.password=
# 连接池最大连接数（使用负值表示没有限制）
spring.redis.pool.max-active=8
# 连接池最大阻塞等待时间（使用负值表示没有限制）
spring.redis.pool.max-wait=-1
# 连接池中的最大空闲连接
spring.redis.pool.max-idle=8
# 连接池中的最小空闲连接
spring.redis.pool.min-idle=0
# 连接超时时间（毫秒）
spring.redis.timeout=0
```

**其中spring.redis.database的配置通常使用0即可，Redis在配置的时候可以设置数据库数量，默认为16，可以理解为数据库的schema**

#### 测试访问

通过编写测试用例，举例说明如何访问Redis。

```
@RunWith(SpringJUnit4ClassRunner.class)
@SpringApplicationConfiguration(Application.class)
public class ApplicationTests {

	@Autowired
	private StringRedisTemplate stringRedisTemplate;

	@Test
	public void test() throws Exception {

		// 保存字符串
		stringRedisTemplate.opsForValue().set("aaa", "111");
		Assert.assertEquals("111", stringRedisTemplate.opsForValue().get("aaa"));

    }

}
```

通过上面这段极为简单的测试案例演示了如何通过自动配置的`StringRedisTemplate`对象进行Redis的读写操作，该对象从命名中就可注意到支持的是String类型。如果有使用过spring-data-redis的开发者一定熟悉`RedisTemplate<K, V>`接口，`StringRedisTemplate`就相当于`RedisTemplate<String, String>`的实现。

除了String类型，实战中我们还经常会在Redis中存储对象，这时候我们就会想是否可以使用类似`RedisTemplate<String, User>`来初始化并进行操作。但是Spring Boot并不支持直接使用，需要我们自己实现`RedisSerializer<T>`接口来对传入对象进行序列化和反序列化，下面我们通过一个实例来完成对象的读写操作。

- 创建要存储的对象：User

```
public class User implements Serializable {

    private static final long serialVersionUID = -1L;

    private String username;
    private Integer age;

    public User(String username, Integer age) {
        this.username = username;
        this.age = age;
    }

    // 省略getter和setter

}
```

- 实现对象的序列化接口

```
public class RedisObjectSerializer implements RedisSerializer<Object> {

  private Converter<Object, byte[]> serializer = new SerializingConverter();
  private Converter<byte[], Object> deserializer = new DeserializingConverter();

  static final byte[] EMPTY_ARRAY = new byte[0];

  public Object deserialize(byte[] bytes) {
    if (isEmpty(bytes)) {
      return null;
    }

    try {
      return deserializer.convert(bytes);
    } catch (Exception ex) {
      throw new SerializationException("Cannot deserialize", ex);
    }
  }

  public byte[] serialize(Object object) {
    if (object == null) {
      return EMPTY_ARRAY;
    }

    try {
      return serializer.convert(object);
    } catch (Exception ex) {
      return EMPTY_ARRAY;
    }
  }

  private boolean isEmpty(byte[] data) {
    return (data == null || data.length == 0);
  }
}
```

- 配置针对User的RedisTemplate实例

```
@Configuration
public class RedisConfig {

    @Bean
    JedisConnectionFactory jedisConnectionFactory() {
        return new JedisConnectionFactory();
    }

    @Bean
    public RedisTemplate<String, User> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, User> template = new RedisTemplate<String, User>();
        template.setConnectionFactory(jedisConnectionFactory());
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new RedisObjectSerializer());
        return template;
    }


}
```

- 完成了配置工作后，编写测试用例实验效果

```
@RunWith(SpringJUnit4ClassRunner.class)
@SpringApplicationConfiguration(Application.class)
public class ApplicationTests {

	@Autowired
	private RedisTemplate<String, User> redisTemplate;

	@Test
	public void test() throws Exception {

		// 保存对象
		User user = new User("超人", 20);
		redisTemplate.opsForValue().set(user.getUsername(), user);

		user = new User("蝙蝠侠", 30);
		redisTemplate.opsForValue().set(user.getUsername(), user);

		user = new User("蜘蛛侠", 40);
		redisTemplate.opsForValue().set(user.getUsername(), user);

		Assert.assertEquals(20, redisTemplate.opsForValue().get("超人").getAge().longValue());
		Assert.assertEquals(30, redisTemplate.opsForValue().get("蝙蝠侠").getAge().longValue());
		Assert.assertEquals(40, redisTemplate.opsForValue().get("蜘蛛侠").getAge().longValue());

	}

}
```

当然spring-data-redis中提供的数据操作远不止这些，本文仅作为在Spring Boot中使用redis时的配置参考，更多对于redis的操作使用，请参考[Spring-data-redis Reference](http://docs.spring.io/spring-data/redis/docs/1.6.2.RELEASE/reference/html/)。



> 文章转自 ["程序猿DD"](http://blog.didispace.com/) 博客 .