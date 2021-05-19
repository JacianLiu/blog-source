---
title: SpringBoot快速入门
tags:
  - SpringBoot
categories:
  - SpringBoot
toc: true
category: SpringBoot
date: 2019-02-21 15:00:00
thumbnail: https://img.jacian.com/Fq4RJGhYPPg3JLjFikPDYbHg4yp1
article-thumbnail: 'false'
---

## SpringBoot主要优点

- 为所有Spring开发者更快的入门
- 开箱即用，提供各种默认配置来简化项目配置
- 内嵌式容器简化Web项目
- 没有冗余代码生成和XML配置的要求<!-- more -->

## 本文所用工具版本

- Maven3.6.0
- JDK 1.8
- SpringBoot 1.5.19

## 使用Maven构建项目

1. 通过 SPRING INITIALIZR 构建项目

   1. 访问: `https://start.spring.io/` ;

   2. 选择构建工具`Maven Project`、Spring Boot版本`1.5.19`以及一些工程基本信息，可参考下图所示 ;

      ![SPRING INITIALIZR 构建项目](https://img.jacian.com/20190521113131.png)

   3. 点击 Generate Project下载项目压缩包 ;

2. 解压项目包 , 并用IDE 以`Maven`项目导入 , 以 `IDEA` 为例

   1. 菜单中选择`File`–>`New`–>`Project from Existing Sources...`

      ![](https://img.jacian.com/20190521113204.png)

   2. 选择解压后的项目文件夹，点击`OK`

   3. 点击`Import project from external model`并选择`Maven`，点击`Next`到底为止。

      ![](https://img.jacian.com/20190521113237.png)

   4. 若你的环境有多个版本的JDK，注意到选择`Java SDK`的时候请选择`Java 7`以上的版本

      ![](https://img.jacian.com/20190521113254.png)

## 项目结构解析

![](https://img.jacian.com/20190521113313.png)

通过上面步骤完成了基础项目的创建，如上图所示，Spring Boot的基础结构共三个文件（具体路径根据用户生成项目时填写的Group所有差异）：

- `src/main/java`下的程序入口：`Learning1Application`
- `src/main/resources`下的配置文件：`application.properties`
- `src/test/`下的测试入口：`Learning1ApplicationTests`

生成的`Learning1Application`和`Learning1ApplicationTests`类都可以直接运行来启动当前创建的项目，由于目前该项目未配合任何数据访问或Web模块，程序会在加载完Spring之后结束运行。

## 引入Web模块

当前的`pom.xml`内容如下，仅引入了两个模块：

- `spring-boot-starter`：核心模块，包括自动配置支持、日志和YAML
- `spring-boot-starter-test`：测试模块，包括JUnit、Hamcrest、Mockito

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

引入Web模块，需添加`spring-boot-starter-web`模块：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

## 编写HelloWorld服务

- 创建`package`命名为`cn.rickyxd.web`（根据实际情况修改）

- 创建`HelloWorldController`类，内容如下

  ```java
  @RestController
  public class HelloWorldController {
      @RequestMapping("/hello")
      public String hello() {
          return "HelloWorld!";
      }
  }
  ```

- 启动主程序，打开浏览器访问`https://localhost:8080/hello`，可以看到页面输出`Hello World`

![](https://img.jacian.com/20190521113332.png)

## 编写单元测试用例

打开的`src/test/`下的测试入口`Chapter1ApplicationTests`类。下面编写一个简单的单元测试来模拟http请求，具体如下:

```java
@SpringBootTest
// 使用Spring Test组件进行单元测试 , 其中SpringRunner继承SpringJUnit4ClassRunner
@RunWith(SpringRunner.class)
// 测试环境使用，用来表示测试环境使用的ApplicationContext将是WebApplicationContext类型的；value指定web应用的根
@WebAppConfiguration
// 注入 MockMvc 实例
@AutoConfigureMockMvc
public class Learning1ApplicationTests {

    private MockMvc mvc;

    @Before
    public void setUp() throws Exception {
        mvc = MockMvcBuilders.standaloneSetup(new HelloWorldController()).build();
    }

    @Test
    public void contextLoads() throws Exception {
        mvc.perform(MockMvcRequestBuilders.get("/hello").accept(MediaType.APPLICATION_JSON_UTF8))
                .andExpect(status().isOk())
                .andExpect(content().string(equalTo("Hello World!")));
    }
}
```

- 注意引入下面内容，让`status`、`content`、`equalTo`函数可用

```java
import static org.hamcrest.Matchers.equalTo;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
```

> 至此已完成目标，通过Maven构建了一个空白Spring Boot项目，再通过引入web模块实现了一个简单的请求处理。



> 文章转自 ["程序猿DD"](https://blog.didispace.com/) 博客 .