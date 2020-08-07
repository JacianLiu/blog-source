---
title: Joda Time使用小结
tags:
  - Joda
  - DateTime
categories:
  - Spring
toc: true
category: Spring
date: 2019-06-13 17:39:06
---

## 一、Joda Time基础操作

<!-- more -->

### 1、 构造指定时间

```java
// 明确给出年月日时分秒,同时还可以指定毫秒
DateTime dateTime = new DateTime(2017,9,14,20,30,0);  

// 使用时间戳构造
Datetime dateTime = new DateTime(1505371053358L);

// 使用字符串构造，使用字符串构造需要自己定义pattern
String date = "2017-09-14 20:30:00";
DateTimeFormatter dateTimeFormatter = DateTimeFormat.forPattern("yyyy-MM-dd HH:mm:ss");
DateTime dateTime = dateTimeFormatter.parseDateTime(date);

// 指定时区构造时间
DateTime dateTime = new DateTime(DateTimeZone.forTimeZone(TimeZone.getTimeZone("Asia/Shanghai")));
```

> 注意：”Asia/Shanghai”是国际时区Id，该ID可以通过JDK代码获取，代码如下：

```java
String[] zones = TimeZone.getAvailableIDs();
for (String zone : zones) {
    System.out.println(zone);
}
```



### 2、获取当前时间的时间戳

```java
// JDK
long currentTimeOfMills = System.currentTimeMillis();
// Joda Time
long currentTimeOfMills = DateTime.now().getMillis();
```



### 3、获得当前时间的时区

```java
DateTimeZone zone = DateTime.now().getZone();
```


### 4、 获取指定时区的当前时间

```java
DateTimeZone gmt = DateTimeZone.forID("GMT");
DateTime dateTime = DateTime.now().toDateTime(gmt);
```



## 二、Joda Time 对年月日的一些简单操作。

### 1、 获取月初第一天和月末最后一天

```java
DateTime dateTime = new DateTime();
// 月初第一天
DateTime theFirstDateOfMonth = dateTime.dayOfMonth().withMinimumValue();
//  当前月最后一天
DataTime theEndDataOfMonth = dateTime.dayOfMonth().withMaximumValue();

// 这一天是几号
int day = dateTime.getDayOfMonth();
// 这一天是哪月
int month = dateTime.getMothOfYear();
// 这一天是哪年
int year = dateTime.getYear();
// 判断本月是不是9月
if(dateTime.getDayOfMonth() == DateTimeConstants.SEPTEMBER){
//TODO
}

// 获取相对于当前时间的月份，比如获取上个月的时间或者下个月的是时间，方法minusMoths接受一个int的参数，如果这个参数等于0，代表本月，大于0代表已经过去的时间，小于0代表还没有到来的时间
 LocalDate lastDayOfMonth = new LocalDate().minusMonths(1).dayOfMonth().withMaximumValue();
```


### 2、关于星期的操作

```java
DateTime dateTime = new DateTime();
// 今天是星期几
int week = dateTime.getDayOfWeek();
// 判断今天是不是星期三
if(dateTime.getDayOfWeek() == DateTimeConstants.WEDNESDAY){
	// TODO
}
```

> 注意：DateTimeConstants中包含了许多你需要的常量，而不用你自己去定义，比如星期、月份、上午还是下午都有哦

### 3、计算时间差 
**注意开始时间与结束时间参数位置，如果开始时间小于结束时间，得到的天数是正数，否则就是负数哦！**

```java
DateTime currentDateTime = new DateTime();
DateTime targetDateTime = new DateTime(2017,10,1,0,0,0);

// 相差多少年
int years = Years.yearsBetween(currentDateTime,targetDateTime).getYears();
// 相差多少月
int months = Months.monthsBetween(currentDateTime,targetDateTime).getMonths();
// 距离国庆放假还有多少天，嘎嘎！
int days = Days.daysBetween(currentDateTime,targetDateTime).getDays();
// 相差多少小时
int hours = Hours.hoursBetween(currentDateTime,targetDateTime).getHours();
// 相差多少分钟
int minutes = Minutes.minutesBetween(currentDateTime,targetDateTime).getMinutes();
// 相差多少秒
int seconds = Seconds.secondsBetween(currentDateTime,targetDateTime).getSeconds();
// 相差多少周
int weeks = Weeks.weeksBetween(currentDateTime,targetDateTime).getWeeks();
```



### 4、获取零点相关的时间

```java
DateTime currentDateTime = new DateTime();
// 今天的零点
DateTime dateTime = currentDateTime.withMillisOfDay(0)；
// 昨天的零点
DateTime dateTime = currentDateTime.withMillisOfDay(0).plusDays(-1);
// 明天的零点
DateTime dateTime = currentDateTime.withMillisOfDay(0).plusDays(1);
// 这一年最后一天0点
new DateTime().dayOfYear().withMaximumValue().withMillisOfDay(0)
// 这一年第一天0点
new DateTime().dayOfYear().withMinimumValue().withMillisOfDay(0)
// 这个月最后一天0点
new DateTime().dayOfMonth().withMaximumValue().withMillisOfDay(0)
// 这个月月初0点
new DateTime().dayOfMonth().withMinimumValue().withMillisOfDay(0)
```



> 注意：要获取多少天后或者多少天前的零点，只需在plusDays()方法中填写相应参数即可

## 三、准确使用Joda Time的时间处理类
### 1、格式化就这么简单

```java
// 格式化时间
DateTime currentDateTime = new DateTime();
currentDateTime.toString("yyyy-MM-dd HH:mm:ss");

// 指定时区格式化
String format = "yyyy-MM-dd HH:mm:ss";
DateTime dateTime = new DateTime();
dateTime.toString(format, Locale.US);

// 格式化时分秒（单位毫秒并且最大可格式23:59:59，超出将报错）
int millis = 120000;
LocalTime localTime = new LocalTime().withMillisOfDay(millis);
localTime.toString("HH:mm:ss");
```



### 2、 如果业务只需要日期，请使用LocalDate,因为LocalDate仅仅关心日期，更专业，也减少了不必要的资源消耗；如果业务只关心时间，那么使用LocalTime。例如：

```java
LocalDate localDate = new LocalDate();
LocalTime localTime = new LocalTime();
System.out.println(localDate);
// 2017-09-14
System.out.println(localTime);
//10:54:14.506
```



### 3、 如果业务需要日期时间都要使用，那么可以使用LocalDateTime, DateTime这两个类，它们都是线程安全的同时都是不可变的，使用起来不用担心出问题。 
LocalDateTime是与时区无关的。 
DateTime是与时区相关的一个国际标准时间。 
使用的时候根据自己的需要选择，详细的解释看官方文档吧！

### 4、再次提醒要使用DateTimeConstants类定义好的常量，避免重复造轮子。下面给出DateTimeConstants类的常量（也不多），不在解释，望名知义。

```java
// 月份
public static final int JANUARY = 1;
public static final int FEBRUARY = 2;
public static final int MARCH = 3;
public static final int APRIL = 4;
public static final int MAY = 5;
public static final int JUNE = 6;
public static final int JULY = 7;
public static final int AUGUST = 8;
public static final int SEPTEMBER = 9;
public static final int OCTOBER = 10;
public static final int NOVEMBER = 11;
public static final int DECEMBER = 12;
// 星期
public static final int MONDAY = 1;
public static final int TUESDAY = 2;
public static final int WEDNESDAY = 3;
public static final int THURSDAY = 4;
public static final int FRIDAY = 5;
public static final int SATURDAY = 6;
public static final int SUNDAY = 7;
// 上午&下午
public static final int AM = 0;
public static final int PM = 1;
// 公元前...年(基督之前...年)
public static final int BC = 0;
// 公元前
public static final int BCE = 0;
// 公元...年(原义为主的纪年)
public static final int AD = 1;
// 基督纪元,公元
public static final int CE = 1;
// 1秒对应毫秒数
public static final int MILLIS_PER_SECOND = 1000;
// 1分钟对应秒数
public static final int SECONDS_PER_MINUTE = 60;
// 1分钟对应毫秒数
public static final int MILLIS_PER_MINUTE = 60000;
// 1小时对应分钟数
public static final int MINUTES_PER_HOUR = 60;
// 1小时对应的秒数
public static final int SECONDS_PER_HOUR = 3600;
// 1小时对应的毫秒数
public static final int MILLIS_PER_HOUR = 3600000;
// 1天对应的小时
public static final int HOURS_PER_DAY = 24;
// 1天对应的分钟数
public static final int MINUTES_PER_DAY = 1440;
// 1天对应的秒数
public static final int SECONDS_PER_DAY = 86400;
// 1天对应的毫秒数
public static final int MILLIS_PER_DAY = 86400000;
// 1周对应的天数
public static final int DAYS_PER_WEEK = 7;
// 1周对应的小时
public static final int HOURS_PER_WEEK = 168;
// 1周对应的分钟
public static final int MINUTES_PER_WEEK = 10080;
// 1周对应的秒数
public static final int SECONDS_PER_WEEK = 604800;
// 1周对应的毫秒数
public static final int MILLIS_PER_WEEK = 604800000;
```