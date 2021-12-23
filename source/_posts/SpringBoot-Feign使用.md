---
title: SpringBoot-Feign使用
tags:
  - SpringBoot
categories:
  - SpringBoot
toc: true
category: SpringBoot
date: 2019-05-24 11:17:20
cover: https://img.jacian.com/Fq4RJGhYPPg3JLjFikPDYbHg4yp1
article-thumbnail: 'false'
---

```
SpringBoot：2.1.5.RELEASE
Feign：2.0.1.RELEASE
feign-okHttp：9.7.0
```



## Feign 简介

Spring Cloud的Feign支持的一个中心概念就是命名客户端.Feign客户端使用@FeignClient注册组合成组件,按需调用远程服务器. 
Spring Cloud使用FeignClientsConfiguration创建一个新的集合作为每个命名客户端的ApplicationContext(应用上下文), 包含feign.Decoder，feign.Encoder和feign.Contract.

你可以使用 Jersey 和 CXF 这些来写一个 Rest 或 SOAP 服务的java客服端。你也可以直接使用 Apache HttpClient 来实现。但是 Feign 的目的是尽量的减少资源和代码来实现和 HTTP API 的连接。通过自定义的编码解码器以及错误处理，你可以编写任何基于文本的 HTTP API。

<!-- more -->

Feign 通过注解注入一个模板化请求进行工作。只需在发送之前关闭它，参数就可以被直接的运用到模板中。然而这也限制了 Feign，只支持文本形式的API，它在响应请求等方面极大的简化了系统。同时，它也是十分容易进行单元测试的。

Spring Cloud应用在启动时，Feign会扫描标有@FeignClient注解的接口，生成代理，并注册到Spring容器中。生成代理时Feign会为每个接口方法创建一个RequetTemplate对象，该对象封装了HTTP请求需要的全部信息，请求参数名、请求方法等信息都是在这个过程中确定的，Feign的模板化就体现在这里。

## Maven依赖

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
</dependency>

<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-openfeign</artifactId>
  <version>2.0.1.RELEASE</version>
</dependency>

```

## Feign客户端接口(调用方)

```java
@FeignClient(name = "testDemo", url = "localhost:8080/student")
public interface TestFeignRepository {
    @GetMapping
    String get1();

    @PostMapping
    String get2();
}
```

## 启动类添加@EnableFeignClients注解

```java
@SpringBootApplication
@EnableFeignClients
public class TestprojectApplication {

    public static void main(String[] args) {
        SpringApplication.run(TestprojectApplication.class, args);
    }

}
```



## @FeignClient注解参数

- name：指定FeignClient的名称，如果项目使用了Ribbon，name属性会作为微服务的名称，用于服务发现
- url: url一般用于调试，可以手动指定@FeignClient调用的地址
- decode404:当发生http 404错误时，如果该字段位true，会调用decoder进行解码，否则抛出FeignException
- configuration: Feign配置类，可以自定义Feign的Encoder、Decoder、LogLevel、Contract
- fallback: 定义容错的处理类，当调用远程接口失败或超时时，会调用对应接口的容错逻辑，fallback指定的类必须实现@FeignClient标记的接口
- fallbackFactory: 工厂类，用于生成fallback类示例，通过这个属性我们可以实现每个接口通用的容错逻辑，减少重复的代码
- path: 定义当前FeignClient的统一前缀

## Feign使用OkHttp3和Hystrix

#### Maven依赖

```xml
<dependency>
  <groupId>io.github.openfeign</groupId>
  <artifactId>feign-okhttp</artifactId>
  <version>9.7.0</version>
</dependency>
<dependency>
  <groupId>io.github.openfeign</groupId>
  <artifactId>feign-hystrix</artifactId>
  <version>9.7.0</version>
</dependency>
```

#### 配置文件：application.yml

```xml
feign:
  httpClient:
    enabled: false
  okhttp:
    enabled: true
  hystrix:
    enabled: true
```

#### 配置类

```java
@Configuration
@ConditionalOnClass(Feign.class)
@AutoConfigureBefore(FeignAutoConfiguration.class)
public class FeignOkHttpConfig {

    @Bean
    public okhttp3.OkHttpClient okHttpClient(){
        return new okhttp3.OkHttpClient.Builder()
                .readTimeout(60, TimeUnit.SECONDS)
                .connectTimeout(60, TimeUnit.SECONDS)
                .writeTimeout(120, TimeUnit.SECONDS)
                .connectionPool(new ConnectionPool())
//                .addInterceptor() // 拦截器
                .build();
    }
}
```