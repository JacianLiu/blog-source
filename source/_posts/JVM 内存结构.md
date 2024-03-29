---
title: JVM内存结构
tags:
  - JVM
  - Java
categories:
  - JVM
toc: true
category: JVM
date: 2023-03-23 18:22:43
---
![](https://img.jacian.com/note/img/202303231818253.jpeg)
<a name="sUt6q"></a>

# 类加载子系统

- 类加载器子系统负责从文件系统或网络中加载class文件，class文件有特定的文件头标识
- ClassLoader 只负责class文件的加载，至于是否可以运行是由**Execution Engine（执行引擎）**决定
- 加载的类信息存放在方法区中，除了类信息外，方法区中还会存放运行时常量池信息，可能还包括字符串字面量和数字常量（这部分常量信息是class文件中常量池部分的内存映射）

![](https://img.jacian.com/note/img/202303231818214.jpeg)
> 类的加载过程

<a name="jAFeB"></a>

## 加载（Loading）
Java虚拟机对class文件的加载采用的是按需加载的模式，也就是说当需要用到该类时才会把class文件加载到内存中生成Class对象；而且加载某个class文件时，Java虚拟机采用的是[**双亲委派**](#fI1fZ)的模式（既把请求交由父类加载，是一种任务委派的模式。）

1. 通过类的权限定名获取定义此类的二进制字节流
2. 将这个字节流存储所代表的静态结构转化为方法区的运行时数据结构
3. 在内存中生成一个`java.lang.Class`对象，作为方法区这个类各种数据的访问入口
4. 如果一个类使用同一个ClassLoader并且类的完整路径一样，那么JVM判定为是同一个Class对象

严格上来讲，类加载器分为两类：引导类加载器和自定义类加载器（扩展类加载器和应用类加载器属于自定义类加载器）；直接或间接集成抽象类ClassLoader的都属于自定义类加载器
> 可以通过方法`ClassLoader#getClassLoader`获取类的加载器

<a name="n5avz"></a>
### 启动类加载器

- 使用C/C++编写，嵌套在JVM内部；并非继承自`java.lang.ClassLoader`
- 主要用来加载Java核心类库（jre/lib/rt.jar、resources.jar或sun.boot.class.path路径下的内容），用于提供JVM自身需要的类
- 用于加载扩展类加载器和应用类加载器，并指定为它们两个的父类
- 启动类加载器只负责加载包名为`java`、`javax`、`sun`等开头的类
<a name="GYycy"></a>
### 扩展类加载器

- 使用Java编写，`sun.misc.Launcher.ExtClassLoader`
- 派生于`java.lang.ClassLoader`，父类加载器为启动类加载器
- 从JDK安装目录的`jre/lib/ext`子目录（扩展目录）下加载类库，也会加载系统属性`java.ext.dirs`指定扩展类加载器需要加载的类库；如果jar包放在扩展目录下，也会自动由扩展类加载器加载
<a name="nXCRl"></a>
### 应用类加载器

- 使用Java编写，`sun.misc.Launcher.AppClassLoader`
- 派生于`java.lang.ClassLoader`，父类加载器为扩展类加载器
- 负责加载`classpath`或系统属性`java.class.path`指定加载的路径
- 该类加载器是程序中默认的类加载器，一般来说，Java应用的类都是由应用类加载器负责加载
<a name="ncJuz"></a>
### 用户自定义类加载器
<a name="KNfuU"></a>
#### 自定义类加载器的使用场景

- **隔离加载类：**避免使用同一库不同版本带来的冲突；通过自定义来加载器实现类的隔离，以便在同一个程序中使用同一个库的不同版本
- 修改类加载方式
- **扩展加载类：**加载非标准的资源文件，如从网络中、数据库中加载类。
- **防止源码泄露：**对字节码文件进行加密，通过自定义的类加载器对字节码文件解密
<a name="OZJ7i"></a>
#### 用户如何实现自定义的类加载器？

- 继承抽象类 `java.lang.ClassLoader`
- 1.2之前必须要重写`loadClass()`方法；1.2之后不建议用户重写`loadClass()`方法，而是建议把自定义类的加载逻辑放在`findClass()`方法中
- 如果没有特殊复杂需求，可以直接继承`URLClassLoader`，避免自己重写`findClass()`方法
<a name="fI1fZ"></a>
### 双亲委派机制
双亲委派机制是指在类加载过程中，如果一个类加载器收到了类加载的请求，会将这个类加载的请求委托给它的父类加载器，如果父类加载器无法完成请求，会再次委托给它的父类加载器，依次向上委托直到找到顶层的启动类加载器，如果启动类加载器也无法完成类加载请求，则会返回给下一级类加载器，由下一级类加载器尝试进行类加载。

- 双亲委派机制可以避免类的重复加载
- 保护程序安全，避免核心API被篡改（沙箱安全机制）
<a name="oBnFd"></a>
### 类的主动使用和被动使用

- 主动使用：会执行初始化阶段
   - 创建类的实例
   - 反射（如：Class.forName()）
   - 初始化一个类的子类
   - Java虚拟机启动时被标记为启动类的类（main方法所在类）
   - 动态语言的支持（动态代理）java.lang.invoke.MethodHandle
- 被动使用（除主动使用外都称为被动使用）：不会执行初始化阶段
   - 访问某个类或接口的静态变量或者对该类静态变量的赋值
   - 调用类的静态方法
   <a name="di5Uz"></a>
## 链接（Linking）
<a name="msbuo"></a>
### 验证（Verification）

- 确保Class文件字节流中包含的信息符合当前虚拟机的要求，**保证被加载类的安全性和准确性，保证虚拟机自身安全**（字节码文件的二进制以 CAFEBABE 开头）
- 包括四种验证：**文件格式验证、元数据验证、字节码验证、符号引用验证**
<a name="GG7tc"></a>
### 准备（Preparation）

- 为类变量（静态变量）分配内存并设置该变量的初始化值，即零值
- 被final修饰的static，被称为**常量**，在编译的时候就会分配，准备阶段会显式的初始化
- 这里不会为实例变量分配和初始化，类变量分配在方法区中，而实例变量会跟着对象一起分配
<a name="LUKti"></a>
### 解析（Resolution）

- 将常量池内的**符号引用（一组符号，描述所引用的目标）**转换为**直接引用**（直接指向目标的指针）的过程
- 解析动作主要针对类或接口、字段、类方法、接口方法、方法类型等。
<a name="LFWmV"></a>
## 初始化（Initialization）

- 执行类构造器方法`<clinit>()`的过程，此方法不需要定义，是javac编译器自动收集类变量的赋值动作和静态代码块自动生成的（如果没有相关动作则不会生成`<clinit>()`方法）；构造器方法的执行顺序按照源文件中出现的顺序执行
- `<clinit>()`方法不同于类的构造器，类的构造器是虚拟机视角的 `<init>()`方法
- 若该类有父类，JVM虚拟机会保证优先加载父类`<clinit>()`，虚拟机必须保证一个类的`<clinit>()`方法在多线程下被同步加锁
<a name="u3muZ"></a>
# 运行时数据区
每个Java应用程序仅有一个`Runtime`实例（运行时环境）<br />![](https://img.jacian.com/note/img/202303231818822.jpeg)
<a name="n7sz6"></a>

## 程序计数器（PC 寄存器）
PC寄存器用来存储指向下一条指令的地址，也就是即将要执行的下一行指令的代码。由执行引擎读取下一条指令。是一块很小的内存空间，几乎可以忽略不计，生命周期与线程保持一致。<br />它是程序控制流的指示器，分支、循环、跳转、异常处理、线程恢复等基础功能都依赖计数器完成。

<a name="LRZGw"></a>
## 虚拟机栈
栈是运行时单位，堆是存储的单位，栈解决的是程序运行问题，程序如何运行或者说如何处理数据；堆管理数据的存储，数据存在哪儿怎么存；<br />一个栈帧对应一个方法，每个线程创建时都会创建一个虚拟机栈，是线程私有的，生命周期与线程一直；其内部保存的一个个的栈帧，一个栈帧对应的是一个Java方法的调用；栈的执行速度仅次于程序计数器；方法的执行伴随着入栈操作，方法的结束伴随着出栈操作；对应栈来说不存在垃圾回收问题；<br />栈的大小可以是动态的，也可以是固定大小；如果是固定大小的，超出设置的大小时会抛出StackowerFlowError，如果是动态大小，有可能会内存不够用抛出OutOfMemoryError；

虚拟机栈主管Java方法的调用，保存方法的局部变量（基本数据类型或对应引用）、操作数栈（）、动态链接和方法返回地址。<br /> 
<a name="ssR6J"></a>
### 局部变量表（Local Variable Table）
局部变量表是一块变量值存储空间，存放方法入参和方法中定义的局部变量。包括**8种基本数据类型、对象引用（reference类型）和returnAddress类型（指向一条字节码指令的地址）**；**其中64位长度的类型的数据（long和double）会占用2个变量槽（Slot），其余数据类型只占用1个；byte、short、char和boolean存储前会被转换为int类型，0表示false，非0表示true。**

![image.png](https://img.jacian.com/note/img/202303231819104.png)<br />如上图所示，右侧对应的是局部变量表存储的内容，各列<br />**起始PC：**作用域起始字节码行号<br />**长度：**局部变量有效的作用范围<br />**序号：**Slot序号，可以看到变量v（long类型)和变量w之间间隔2个<br />**名字：**变量名<br />**描述符：**对应局部变量类型

静态方法、静态代码块中不能使用this关键字，因为static的方法在类初始化时加载，非static方法在实例初始化时加载；static的局部变量表中没有this的变量，非static的方法有this的变量；
<a name="hzaT1"></a>
### 操作数栈
操作数栈在方法执行过程中，根据字节码指令，往栈中写入数据（入栈）或提取数据（出栈），操作数栈的深度在编译时期即可确定；主要用于存储计算过程的中间结果，同时作为计算过程中变量临时的存储空间
<a name="aNxmi"></a>
### 动态链接
动态链接作用是将符号引用转换为直接引用（被调用的方法在编译期无法被确定下来）。图中的 #7和#13都是符号引用；图二表示的是符号对应的真实引用地址。 <br />![图1](https://img.jacian.com/note/img/202303231819848.png)

<a name="nkMOL"></a>
 ![图2](https://img.jacian.com/note/img/202303231819491.png)
<a name="wvP1q"></a>

### 静态链接
当一个字节码文件被装载进JVM内部时，如果被调用的目标方法在编译期可知且运行期保持不变时。这种情况下将调用方法的符号引用转换为直接引用的过程称之为静态链接。
<a name="mcVqE"></a>
### 方法返回地址
存储的是该方法的PC寄存器的值（也就是方法返回后执行的指令地址），正常退出时，在方法退出后都会返回该方法被调用的位置；异常退出时，返回地址是通过异常表来确定的，栈帧中一般不会存储这部分信息。 <br />返回指令包括：ireturn（byte、short、int、char、boolean）、lreturn、freturn、dreturn、aretuen
<a name="pyl3m"></a>
## 本地方法栈
与虚拟机栈类似，主要用于管理本地方法的调用。Hotspot虚拟机没有本地方法栈，使用虚拟机栈实现。
<a name="YSRdj"></a>
## 堆

<a name="nzwSd"></a>
## 方法区
> JDK1.8之前的实现是**永久代**；JDK1.8及之后版本的实现是**元空间**



<a name="GdjO2"></a>
# 执行引擎



