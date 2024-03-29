---
title: 为什么StringBuilder是线程不安全的？StringBuffer是线程安全的？
tags:
  - Java
categories:
  - Java
toc: true
cover: 'https://img.jacian.com/FpO_mt3xbgxjH6NZQF3ml62pqONu'
article-thumbnail: 'false'
date: 2019-09-19 18:11:56
---

面试中经常问到的一个问题：`StringBuilder`和`StringBuffer`的区别是什么？
我们非常自信的说出：`StringBuilder`是线程不安全的，`StirngBuffer`是线程安全的
面试官：`StringBuilder`不安全的点在哪儿？
这时候估计就哑巴了。。。
<!-- more -->
# 分析
`StringBuffer`和`StringBuilder`的实现内部是和`String`内部一样的，都是通过 `char[]`数组的方式；不同的是`String`的`char[]`数组是通过`final`关键字修饰的是不可变的，而`StringBuffer`和`StringBuilder`的`char[]`数组是可变的。

首先我们看下边这个例子：
```java
public class Test {
    public static void main(String[] args) throws InterruptedException {
        StringBuilder stringBuilder = new StringBuilder();
        for (int i = 0; i < 10000; i++){
            new Thread(() -> {
                for (int j = 0; j < 1000; j++){
                    stringBuilder.append("a");
                }
            }).start();
        }

        Thread.sleep(100L);
        System.out.println(stringBuilder.length());
    }
}
```
直觉告诉我们输出结果应该是`10000000`，但是实际运行结果并非我们所想。

![执行结果](https://img.jacian.com/FmucP95hkCgazmSiM1oq9-GoJ5cW)

从上图可以看到输出结果是`9970698`，并非是我们预期的`1000000`（什么情况？剩下的那些都被计算机吃了？），并且还抛出了一个异常`ArrayIndexOutOfBoundsException`（吃了我的东西还给我吐出来个异常）{非必现}

# 为什么输出结果并非预期值？
我们先看一下`StringBuilder`的两个成员变量（这两个成员变量实际上是定义在`AbstractStringBuilder`里面的，`StringBuilder`和`StringBuffer`都继承了`AbstractStringBuilder`）

![AbstractStringBuilder.class](https://img.jacian.com/Fgsq98wpAjFdyi-wYPDUPYZMQmzI)

`StringBuilder`的`append`方法

![StringBuilder.append(String str)](https://img.jacian.com/Fr1X_6JI1fakN8ogHMX-27yZQBJv)

`StringBuilder`的`append`方法调用了父类的`append`方法

![AbstractStringBuilder.append(String str)](https://img.jacian.com/Fowwe-2xu4GpspxBZSJikkON7Jy3)

我们直接看第七行代码，`count += len;` 不是一个原子操作，实际执行流程为
- 首先加载`count`的值到寄存器
- 在寄存器中执行 `+1`操作
- 将结果写入内存

假设我们`count`的值是`10`，`len`的值为`1`，两个线程同时执行到了第七行，拿到的值都是`10`，执行完加法运算后将结果赋值给`count`，所以两个线程最终得到的结果都是`11`，而不是`12`，这就是最终结果小于我们预期结果的原因。
# 为什么会抛出ArrayIndexOutOfBoundsException异常？
我们看回AbstractStringBuilder的追加（）方法源码的第五行，ensureCapacityInternal（）方法是检查StringBuilder的对象的原字符数组的容量能不能盛下新的字符串，如果盛不下就调用expandCapacity（）方法对字符数组进行扩容。
```java
private  void  ensureCapacityInternal（int  minimumCapacity）  {
         //溢出意识代码
    if  （minimumCapacity  -  value .length>  0）
        expandCapacity（minimumCapacity）; 
}
```
扩容的逻辑就是新一个新的字符数组，新的字符数组的容量是原来字符数组的两倍再加2，再通过System.arryCopy（）函数将原数组的内容复制到新数组，最后将指针指向新的字符数组。
```java
void  expandCapacity（int  minimumCapacity）  {
     //计算新的容量
    int  newCapacity =  value .length *  2  +  2 ; 
    //中间省略了一些检查逻辑
     ...
     value  = Arrays.copyOf（ value，newCapacity）; 
}
```
Arrys.copyOf（）方法
```java
public  static  char []  copyOf（char [] original，  int  newLength）  {
     char [] copy =  new  char [newLength]; 
    //拷贝数组
     System.arraycopy（original，  0，copy，  0，
                         Math.min（original.length，newLength））; 
    返回  副本; 
}
```
AbstractStringBuilder的追加（）方法源码的第六行，是将字符串对象里面字符数组里面的内容拷贝到StringBuilder的对象的字符数组里面，代码如下：
```java
str.getChars（0，len，  value，count）;
```
则GetChars（）方法
```java
public  void  getChars（int  srcBegin，  int  srcEnd，  char  dst []，  int  dstBegin）  {
     //中间省略了一些检查
     ...   
    System.arraycopy（ value，srcBegin，dst，dstBegin，srcEnd  -  srcBegin）; 
}
```
拷贝流程见下图
![StringBuilder.append()执行流程](https://img.jacian.com/FpDTeYULGYWcX-tiOBpZXzUZqJku)

假设现在有两个线程同时执行了`StringBuilder`的`append()`方法，两个线程都执行完了第五行的`ensureCapacityInternal()`方法，此刻`count=5`

![StringBuilder.append()执行流程2](https://img.jacian.com/Frtri-MtOAmzqC2hh6OwmO2uv8_t)

这个时候`线程1`的`cpu`时间片用完了，`线程2`继续执行。线程2执行完整个`append()`方法后`count`变成`6`了。

![StringBuilder.append()执行流程3](https://img.jacian.com/FpPE5_29h5bvuoJM0oI569QPGTo_)

`线程1`继续执行第六行的`str.getChars()`方法的时候拿到的`count`值就是`6`了，执行`char[]`数组拷贝的时候就会抛出`ArrayIndexOutOfBoundsException`异常。

至此，`StringBuilder`为什么不安全已经分析完了。如果我们将测试代码的`StringBuilder`对象换成`StringBuffer`对象会输出什么呢？

![StringBuffer输出结果](https://img.jacian.com/Fi-evX7qlA5yXUKX6TWtEqiv7PqI)

结果肯定是会输出 `1000000`，至于`StringBuffer`是通过什么手段实现线程安全的呢？看下源代码就明白了了。。。
![StringBuffer.append()](https://img.jacian.com/FlnMovQ1PXpI825EK9F8XP37VbUc)