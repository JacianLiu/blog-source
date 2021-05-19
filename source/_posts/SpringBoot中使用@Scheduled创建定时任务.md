---
title: SpringBoot中使用@Scheduled创建定时任务
tags:
  - SpringBoot
categories:
  - SpringBoot
toc: true
category: SpringBoot
date: 2019-04-02 09:02:00
cover: https://img.jacian.com/Fq4RJGhYPPg3JLjFikPDYbHg4yp1
article-thumbnail: 'false'
---

我们在编写Spring Boot应用中经常会遇到这样的场景，比如：我需要定时地发送一些短信、邮件之类的操作，也可能会定时地检查和监控一些标志、参数等。<!-- more -->

## 创建定时任务

在Spring Boot中编写定时任务是非常简单的事，下面通过实例介绍如何在Spring Boot中创建定时任务，实现每过5秒输出一下当前时间。

- 在Spring Boot的主类中加入`@EnableScheduling`注解，启用定时任务的配置

```
@SpringBootApplication
@EnableScheduling
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

}
```

- 创建定时任务实现类

```
@Component
public class ScheduledTasks {

    private static final SimpleDateFormat dateFormat = new SimpleDateFormat("HH:mm:ss");

    @Scheduled(fixedRate = 5000)
    public void reportCurrentTime() {
        System.out.println("现在时间：" + dateFormat.format(new Date()));
    }

}
```

- 运行程序，控制台中可以看到类似如下输出，定时任务开始正常运作了。

```
2016-05-15 10:40:04.073  INFO 1688 --- [           main] com.didispace.Application                : Started Application in 1.433 seconds (JVM running for 1.967)
现在时间：10:40:09
现在时间：10:40:14
现在时间：10:40:19
现在时间：10:40:24
现在时间：10:40:29522
现在时间：10:40:34
```

关于上述的简单入门示例也可以参见官方的[Scheduling Tasks](http://spring.io/guides/gs/scheduling-tasks/)

## @Scheduled详解

在上面的入门例子中，使用了`@Scheduled(fixedRate = 5000)` 注解来定义每过5秒执行的任务，对于`@Scheduled`的使用可以总结如下几种方式：

- `@Scheduled(fixedRate = 5000)` ：上一次开始执行时间点之后5秒再执行
- `@Scheduled(fixedDelay = 5000)` ：上一次执行完毕时间点之后5秒再执行
- `@Scheduled(initialDelay=1000, fixedRate=5000)` ：第一次延迟1秒后执行，之后按fixedRate的规则每5秒执行一次
- `@Scheduled(cron="*/5 * * * * *")` ：通过cron表达式定义规则

## 代码示例

本文的相关例子可以查看下面仓库中的`chapter4-1-1`目录：

github: https://github.com/WuliGitH/SpringBoot-Learning-1



> 文章转自 ["程序猿DD"](http://blog.didispace.com/) 博客 ,