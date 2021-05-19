---
title: 基于Hexo&GitHub从零搭建个人博客
tags:
  - hexo
  - 博客
categories:
  - hexo
toc: true
category: hexo
date: 2019-08-19 15:57:27
---

<div class="note info no-icon"><p>现在越来越多的人喜欢利用Github搭建静态网站，原因不外乎简单省钱。本人也利用hexo+github搭建了本博客，用于分享一些心得。在此过程中，折腾博客的各种配置以及功能占具了我一部分时间，在此详细记录下我是如何利用hexo+github搭建静态博客以及一些配置相关问题，以免过后遗忘，且当备份之用。
</p></div>

<!-- more -->

### 准备工作

- 下载&安装node.js，默认会安装npm：https://nodejs.org/zh-cn/
- 下载&安装git：https://git-scm.com/downloads
- 下载安装hexo。方法：打开cmd 运行`npm install -g hexo`

### 本地搭建hexo静态博客

- 新建一个文件夹，如`blog`
- 进入该文件夹内，右击运行git，输入：`hexo init`（生成hexo模板）
- 生成完模板，运行`npm install`（目前貌似不用运行这一步）
- 最后运行：`hexo s` （运行程序，访问本地localhost:4000可以看到博客已经搭建成功）

![](https://img.jacian.com/1566207418011.png)

### 目录介绍

```
├── _config.yml						// 博客配置文件
├── public								// 静态文件存放目录
│   ├── 2019
│   ├── archives
│   ├── css
│   ├── images
│   ├── index.html
│   ├── js
│   └── lib
├── source								
│   └── _posts						// 博文存放路径
└── themes								// 主题路径
    ├── landscape
    └── next
```



### 将博客与Github关联

- 在Github上创建名字为`XXX.github.io`的项目，`XXX`为自己的GitHub用户名。
- 打开本地的MyBlog文件夹项目内的`_config.yml`配置文件，将其中的type设置为git

```yaml
deploy:
  type: git
  repository: https://github.com/XXX/XXX.github.io.git
  branch: master
```

- 运行：`npm install hexo-deployer-git –save`
- 运行：`hexo g`（本地生成静态文件）
- 运行：`hexo d`（将本地静态文件推送至Github）

> 此时打开 https://XXX.github.io ，即可看到效果

<div class="note warning"><p>这里注意把文中的 XXX 修改为自己的github用户名</p></div>
### 更新文章

- 在`blog`目录下执行：`hexo new “我的第一篇文章”`，会在source->_posts文件夹内生成一个.md文件。
- 编辑该文件（遵循Markdown规则）
- 修改起始字段
  - title 文章的标题
  - date 创建日期 （文件的创建日期 ）
  - updated 修改日期 （ 文件的修改日期）
  - comments 是否开启评论 true
  - tags 标签
  - categories 分类
  - permalink url中的名字（文件名）
- 编写正文内容（MakeDown）
- `hexo clean` 删除本地静态文件（public目录）
- `hexo g` 生成本地静态文件（public目录）
- `hexo deploy` 将本地静态文件推送至github（hexo d）

### 修改主题

> 至此，我们的博客就已经搭建完了，发现两个问题，一是丑，二是使用GitHub默认域名不舒服。所以我们要修改一个好看的主题（默认的主题经过一番DIY也能达到不错的效果，这里就不多做演示）和使用自己的域名（可选），非必须，看个人喜好。

目前安装的主题：[Next](https://github.com/theme-next/hexo-theme-next)

更多主题：[主题](https://github.com/hexojs/hexo/wiki/Themes)

主题配置文档：[Next主题配置](https://theme-next.iissnan.com/theme-settings.html)

#### 1、在博客的根目录下，也就是上文提到的blog文件夹中，执行clone主题

```
$ git clone https://github.com/theme-next/hexo-theme-next themes/next
```

#### 2、修改hexo配置文件

使用文本编辑器打开`blog`目录下的`_config.yml`文件，将 `themes` 对应的值进行修改，如下：

```
theme: next
```

#### 3、重新生成静态文件

```
$ hexo clean

$ hexo g

$ hexo s
```

浏览器打开 http://localhost:4000 即可看到效果。确认没问题执行 `hexo d` 命令更新到GitHub，稍等片刻重新打开  https://XXX.github.io 便可看到效果；

![](https://img.jacian.com/1566208941026.png)





### 绑定域名

- 域名提供商设置

  添加一条CNAME记录：

  CNAME —> XXX.github.io

- 博客添加CNAME文件

  配置完域名解析后，进入博客目录，在`source`目录下新建`CNAME`文件，写入域名，如：jacian.com

- 运行：`hexo g`

- 运行：`hexo d`

*重新发布完，稍等片刻打开自己的域名即可看到效果。至此你的个人博客就已经搭建完毕了；当然，你还可以做一些DIY的设置，在这篇文章中就不一一列举了，可以参考文档或者其他大神的博客去进行一些自定义的设置。*