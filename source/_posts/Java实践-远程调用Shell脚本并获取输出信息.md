---
title: Java实践-远程调用Shell脚本并获取输出信息
tags:
  - Java
  - Shell
categories:
  - Java
toc: true
cover: 'https://img.jacian.com/FrXPCd0kCZ7Fui-atYsgp_-5EuuT'
article-thumbnail: 'false'
date: 2019-09-09 18:10:42
---

# 1、添加依赖

```xml
<dependency>
    <groupId>ch.ethz.ganymed</groupId>
    <artifactId>ganymed-ssh2</artifactId>
    <version>262</version>
</dependency>
<dependency>
    <groupId>commons-io</groupId>
    <artifactId>commons-io</artifactId>
    <version>2.6</version>
</dependency>
```
<!-- more -->

# 2、Api说明

1. 首先构造一个连接器，传入一个需要登陆的ip地址；

```java
Connection conn = new Connection(ipAddr);
```

2. 模拟登陆目的服务器，传入用户名和密码；

```java
boolean isAuthenticated = conn.authenticateWithPassword(userName, passWord);
```
它会返回一个布尔值，true 代表成功登陆目的服务器，否则登陆失败。

3. 打开一个session，执行你需要的linux 脚本命令；

```java
Session session = conn.openSession();
session.execCommand(“ifconfig”);
```

4. 接收目标服务器上的控制台返回结果，读取br中的内容；

```java
InputStream stdout = new StreamGobbler(session.getStdout());
BufferedReader br = new BufferedReader(new InputStreamReader(stdout));
```

5. 得到脚本运行成功与否的标志 ：0－成功 非0－失败

```java
System.out.println(“ExitCode: ” + session.getExitStatus());
```

6. 关闭session和connection

```java
session.close();
conn.close();
```

> Tips：
> 1. 通过第二部认证成功后当前目录就位于/home/username/目录之下，你可以指定脚本文件所在的绝对路径，或者通过cd导航到脚本文件所在的目录，然后传递执行脚本所需要的参数，完成脚本调用执行。
> 2. 执行脚本以后，可以获取脚本执行的结果文本，需要对这些文本进行正确编码后返回给客户端，避免乱码产生。
> 3. 如果你需要执行多个linux控制台脚本，比如第一个脚本的返回结果是第二个脚本的入参，你必须打开多个Session,也就是多次调用
Session sess = conn.openSession();,使用完毕记得关闭就可以了。

# 3. 实例：工具类

```java
public class SSHTool {

    private Connection conn;
    private String ipAddr;
    private Charset charset = StandardCharsets.UTF_8;
    private String userName;
    private String password;

    public SSHTool(String ipAddr, String userName, String password, Charset charset) {
        this.ipAddr = ipAddr;
        this.userName = userName;
        this.password = password;
        if (charset != null) {
            this.charset = charset;
        }
    }

    /**
     * 登录远程Linux主机
     *
     * @return 是否登录成功
     */
    private boolean login() {
        conn = new Connection(ipAddr);

        try {
            // 连接
            conn.connect();
            // 认证
            return conn.authenticateWithPassword(userName, password);
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }


    /**
     * 执行Shell脚本或命令
     *
     * @param cmds 命令行序列
     * @return 脚本输出结果
     */
    public StringBuilder exec(String cmds) throws IOException {
        InputStream in = null;
        StringBuilder result = new StringBuilder();
        try {
            if (this.login()) {
                // 打开一个会话
                Session session = conn.openSession();
                session.execCommand(cmds);
                in = session.getStdout();
                result = this.processStdout(in, this.charset);
                conn.close();
            }
        } finally {
            if (null != in) {
                in.close();
            }
        }
        return result;
    }

    /**
     * 解析流获取字符串信息
     *
     * @param in      输入流对象
     * @param charset 字符集
     * @return 脚本输出结果
     */
    public StringBuilder processStdout(InputStream in, Charset charset) throws FileNotFoundException {
        byte[] buf = new byte[1024];
        StringBuilder sb = new StringBuilder();
//        OutputStream os = new FileOutputStream("./data.txt");
        try {
            int length;
            while ((length = in.read(buf)) != -1) {
//                os.write(buf, 0, c);
                sb.append(new String(buf, 0, length));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return sb;
    }

    public static void main(String[] args) throws IOException {
        SSHTool tool = new SSHTool("192.168.100.40", "root", "123456", StandardCharsets.UTF_8);
        StringBuilder exec = tool.exec("bash /root/test12345.sh");
        System.out.println(exec);
    }
}

```

# 4、测试脚本
```shell
echo "Hello"
```
**输出结果**
![输出结果](https://img.jacian.com/FkVcWO0iG3G_KEa_1w_LFkxTop4p)