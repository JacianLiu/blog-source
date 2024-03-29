---
title: SpringBoot构建RESTful API与单元测试
tags:
  - SpringBoot
categories:
  - SpringBoot
toc: true
category: SpringBoot
date: 2019-02-23 15:00:00
cover: https://img.jacian.com/Fq4RJGhYPPg3JLjFikPDYbHg4yp1
article-thumbnail: 'false'
---

- `@Controller`：修饰class，用来创建处理http请求的对象
- `@RestController`：Spring4之后加入的注解，原来在`@Controller`中返回json需要`@ResponseBody`来配合，如果直接用`@RestController`替代`@Controller`就不需要再配置`@ResponseBody`，默认返回json格式。
- `@RequestMapping`：配置url映射<!-- more -->

下面我们尝试使用Spring MVC来实现一组对User对象操作的RESTful API，配合注释详细说明在Spring MVC中如何映射HTTP请求、如何传参、如何编写单元测试。

**RESTful API具体设计如下：**

![](https://img.jacian.com/20190521113032.png)

User实体定义：

```java
public class User { 

    private Long id;
    private String name;
    private Integer age;

    // 省略setter和getter

}
```

实现对User对象的操作接口

```java
@RestController
// 配置使以下映射都在 /users 下
@RequestMapping("/users")
public class UserController {

    /**
     * 创建线程安全的Map
     */
    private static Map<Long, User> users = Collections.synchronizedMap(new HashMap<Long, User>());

    /**
     * 处理 "/users/" 的GET请求,用来获取用户列表
     * 还可以通过 @RequestParam 从页面中传递参数进行查询条件或者分页信息的传递
     * @return 用户列表
     */
    @GetMapping("/")
    public List<User> getUserList() {
        return new ArrayList<User>(users.values());
    }

    /**
     * 处理 "/users/" 的 POST 请求 , 用来创建 User
     *  还可以通过@RequestParam从页面中传递参数
     * @param user 用户信息
     * @return 创建 user 的成功与否
     */
    @PostMapping("/")
    public String postUser(@RequestBody User user) {
        users.put(user.getId(), user);
        return "success";
    }

    /**
     * 处理"/users/{id}"的GET请求，用来获取url中id值的User信息
     *  url中的id可通过@PathVariable绑定到函数的参数中
     * @param id 用户ID
     * @return 用户信息
     */
    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) {
        // 处理"/users/{id}"的GET请求，用来获取url中id值的User信息
        // url中的id可通过@PathVariable绑定到函数的参数中
        return users.get(id);
    }

    /**
     * 处理"/users/{id}"的PUT请求，用来更新User信息
     * @param id 用户ID
     * @param user 更新后的用户信息
     * @return 是否更新成功
     */
    @PutMapping("/{id}")
    public String putUser(@PathVariable Long id, @ModelAttribute User user) {
        User u = users.get(id);
        u.setName(user.getName());
        u.setAge(user.getAge());
        users.put(id, u);
        return "success";
    }

    /**
     * 处理"/users/{id}"的DELETE请求，用来删除User
     * @param id 用户ID
     * @return 是否删除成功
     */
    @DeleteMapping("/{id}")
    public String deleteUser(@PathVariable Long id) {
        users.remove(id);
        return "success";
    }
}
```

下面针对该Controller编写测试用例验证正确性，具体如下。当然也可以通过浏览器插件等进行请求提交验证。

```java
@RunWith(SpringJUnit4ClassRunner.class)
@SpringApplicationConfiguration(classes = MockServletContext.class)
@WebAppConfiguration
public class ApplicationTests {

	private MockMvc mvc;

	@Before
	public void setUp() throws Exception {
		mvc = MockMvcBuilders.standaloneSetup(new UserController()).build();
	}

	@Test
	public void testUserController() throws Exception {
        // 测试UserController
		RequestBuilder request = null;

		// 1、get查一下user列表，应该为空
		request = get("/users/");
		mvc.perform(request)
				.andExpect(status().isOk())
				.andExpect(content().string(equalTo("[]")));

		// 2、post提交一个user
		request = post("/users/")
				.param("id", "1")
				.param("name", "测试大师")
				.param("age", "20");
		mvc.perform(request)
		        .andExpect(content().string(equalTo("success")));

		// 3、get获取user列表，应该有刚才插入的数据
		request = get("/users/");
		mvc.perform(request)
				.andExpect(status().isOk())
				.andExpect(content().string(equalTo("[{\"id\":1,\"name\":\"测试大师\",\"age\":20}]")));

		// 4、put修改id为1的user
		request = put("/users/1")
				.param("name", "测试终极大师")
				.param("age", "30");
		mvc.perform(request)
				.andExpect(content().string(equalTo("success")));

		// 5、get一个id为1的user
		request = get("/users/1");
		mvc.perform(request)
				.andExpect(content().string(equalTo("{\"id\":1,\"name\":\"测试终极大师\",\"age\":30}")));

		// 6、del删除id为1的user
		request = delete("/users/1");
		mvc.perform(request)
				.andExpect(content().string(equalTo("success")));

		// 7、get查一下user列表，应该为空
		request = get("/users/");
		mvc.perform(request)
				.andExpect(status().isOk())
				.andExpect(content().string(equalTo("[]")));

	}

}
```

至此，我们通过引入web模块（没有做其他的任何配置），就可以轻松利用Spring MVC的功能，以非常简洁的代码完成了对User对象的RESTful API的创建以及单元测试的编写。其中同时介绍了Spring MVC中最为常用的几个核心注解：`@Controller`,`@RestController`,`RequestMapping`以及一些参数绑定的注解：`@PathVariable`,`@ModelAttribute`,`@RequestParam`等。

> 文章转自 ["程序猿DD"](https://blog.didispace.com/) 博客 .