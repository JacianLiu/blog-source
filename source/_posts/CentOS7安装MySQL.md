---
title: CentOS7安装MySQL
tags:
  - Linux
  - MySQL
categories:
  - Linux
toc: true
category: Linux
date: 2019-03-25 09:49:06
cover: https://img.jacian.com/FrXPCd0kCZ7Fui-atYsgp_-5EuuT
article-thumbnail: 'false'
---

## 下载 repo 源

进入 https://repo.mysql.com/  ，里面包含了所有可用的 MySQL 源。选择一个合适的版本，进行下载：

```shell
# wget https://repo.mysql.com/mysql57-community-release-el7.rpm
```

<!-- more -->

>  如果提示`-bash: wget: 未找到命令` 执行以下命令, 安装wget:
>```shell
># yum -y install wget
>```



完成之后，进行安装：

```shell
# rpm -ivh mysql57-community-release-el7.rpm
```



![](https://img.jacian.com/20190521112252.png)

## 安装MySQL

#### 开始安装MySQL

```shell
# yum install mysql -y
# yum install mysql-server -y
# yum install mysql-devel -y
```

`MySQL` 是MySQL客户端

`MySQL-server` 是数据库服务器

`MySQL-devel` 包含了开发用到的库以及头文件

![](https://img.jacian.com/20190521112131.png)

到此为止MySQL就安装完成了。



## 启动/停止 MySQL

#### 启动MySQL

```shell
# systemctl start mysqld.service
```

#### 查看MySQL运行状态

```shell
# systemctl status mysqld.service
```

![](https://img.jacian.com/20190521112526.png)

> 这就说明MySQL成功运行了。

#### 停止MySQL

```shell
# systemctl stop mysqld.service
```

#### 重启MySQL

```shell
# systemctl restart mysqld.service
```

## 登陆MySQL

#### 通过查看日志获取初始密码

```shell
# grep "password" /var/log/mysqld.log
```

![](https://img.jacian.com/20190521112654.png)

#### 输入以下命令并输入初始密码进入数据库

```shell
# mysql -uroot -p
```

![](https://img.jacian.com/20190521112729.png)



> 此时不能做任何事, 要将初始密码修改掉之后才可以进行操作。

## 修改初始密码

#### 修改密码可以使用以下命令

```mysql
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'new password';
```

> 当我们输入的密码过于简单的时候会出现错误, 那是因为MySQL有相应的密码校验, 要求由大小写字母数字特殊符号组成, 否则无法完成修改 ; 如果仅用于自己测试, 想设置一个简单的密码可以参考下列操作 ;

![](https://img.jacian.com/20190521112800.png)

#### 设置简单密码

```mysql
# 修改MySQL参数配置
mysql> set global validate_password_policy=0;
Query OK, 0 rows affected (0.00 sec)

mysql> set global validate_password_mixed_case_count=0;
Query OK, 0 rows affected (0.00 sec)

mysql> set global validate_password_number_count=3;
Query OK, 0 rows affected (0.00 sec)

mysql> set global validate_password_special_char_count=0;
Query OK, 0 rows affected (0.00 sec)

mysql> set global validate_password_length=3;
Query OK, 0 rows affected (0.00 sec)

# 设置简单密码
mysql> SET PASSWORD FOR 'root'@'localhost' = PASSWORD('root');
Query OK, 0 rows affected, 1 warning (0.01 sec)

# 刷新权限
mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)

```

OK，大功告成。

## 设置允许远程访问MySQL

#### 允许任何主机连接

```mysql
mysql> GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;
mysql> flush privileges;
```

#### 允许指定IP连接

```mysql
mysql> GRANT ALL PRIVILEGES ON *.* TO 'jack'@’10.10.50.127’ IDENTIFIED BY '654321' WITH GRANT OPTION;
mysql> flush privileges;
```

> 如果远程连接出现错误请检查是否关闭防火墙。