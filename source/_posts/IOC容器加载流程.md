---
title: IOC容器加载流程
tags:
  - Spring
categories:
  - Spring
toc: true
cover: 'https://img.jacian.com/note/img/20200826163449.png'
article-thumbnail: 'false'
date: 2020-12-16 23:32:03
---

Spring容器的`AbstractApplicationContext#refresh()`【容器刷新】源码解析；本文只记录大体步骤， 细节部分自行阅读源码；

`AbstractApplicationContext#refresh()`是IOC容器加载的主要流程，源代码如下

<!--more-->

```Java
@Override
  public void refresh() throws BeansException, IllegalStateException {
    // 对象锁加锁
    synchronized (this.startupShutdownMonitor) {
      /*
        Prepare this context for refreshing.
         刷新前的预处理
         表示在真正做refresh操作之前需要准备做的事情：
          设置Spring容器的启动时间，
          开启活跃状态，撤销关闭状态
          验证环境信息里一些必须存在的属性等
       */
      prepareRefresh();

      /*
        Tell the subclass to refresh the internal bean factory.
         获取BeanFactory；默认实现是DefaultListableBeanFactory
                加载BeanDefition 并注册到 BeanDefitionRegistry
       */
      ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

      /*
        Prepare the bean factory for use in this context.
        BeanFactory的预准备工作（BeanFactory进行一些设置，比如context的类加载器等）
       */
      prepareBeanFactory(beanFactory);

      try {
        /*
          Allows post-processing of the bean factory in context subclasses.
          BeanFactory准备工作完成后进行的后置处理工作
         */
        postProcessBeanFactory(beanFactory);

        /*
          Invoke factory processors registered as beans in the context.
          实例化实现了BeanFactoryPostProcessor接口的Bean，并调用接口方法
         */
        invokeBeanFactoryPostProcessors(beanFactory);

        /*
          Register bean processors that intercept bean creation.
          注册BeanPostProcessor（Bean的后置处理器），在创建bean的前后等执行
         */
        registerBeanPostProcessors(beanFactory);

        /*
          Initialize message source for this context.
          初始化MessageSource组件（做国际化功能；消息绑定，消息解析）；
         */
        initMessageSource();

        /*
          Initialize event multicaster for this context.
          初始化事件派发器
         */
        initApplicationEventMulticaster();

        /*
          Initialize other special beans in specific context subclasses.
          子类重写这个方法，在容器刷新的时候可以自定义逻辑；如创建Tomcat，Jetty等WEB服务器
         */
        onRefresh();

        /*
          Check for listener beans and register them.
          注册应用的监听器。就是注册实现了ApplicationListener接口的监听器bean
         */
        registerListeners();

        /*
          Instantiate all remaining (non-lazy-init) singletons.
          初始化所有剩下的非懒加载的单例bean
          初始化创建非懒加载方式的单例Bean实例（未设置属性）
                    填充属性
                    初始化方法调用（比如调用afterPropertiesSet方法、init-method方法）
                    调用BeanPostProcessor（后置处理器）对实例bean进行后置处理
         */
        finishBeanFactoryInitialization(beanFactory);

        /*
          Last step: publish corresponding event.
          完成context的刷新。主要是调用LifecycleProcessor的onRefresh()方法，并且发布事件（ContextRefreshedEvent）
         */
        finishRefresh();
      }

      catch (BeansException ex) {
        if (logger.isWarnEnabled()) {
          logger.warn("Exception encountered during context initialization - " +
              "cancelling refresh attempt: " + ex);
        }

        // Destroy already created singletons to avoid dangling resources.
        destroyBeans();

        // Reset 'active' flag.
        cancelRefresh(ex);

        // Propagate exception to caller.
        throw ex;
      }

      finally {
        // Reset common introspection caches in Spring's core, since we
        // might not ever need metadata for singleton beans anymore...
        resetCommonCaches();
      }
    }
  }
```

# 逐步剖析

## prepareRefresh();

刷新前的预处理，在这里主要完成对Spring的启动时间进行记录、对系统变量的属性合法性进行校验、初始化容器事件列表

```Java
protected void prepareRefresh() {
    // Switch to active.
    // 启动日期startupDate和活动标志active
    this.startupDate = System.currentTimeMillis();
    this.closed.set(false);
    this.active.set(true);

    if (logger.isDebugEnabled()) {
      if (logger.isTraceEnabled()) {
        logger.trace("Refreshing " + this);
      }
      else {
        logger.debug("Refreshing " + getDisplayName());
      }
    }

    // 初始化属性设置，默认实现为空
    initPropertySources();

    // 属性合法性校验
    getEnvironment().validateRequiredProperties();

    // 事件存储容器
    if (this.earlyApplicationListeners == null) {
      this.earlyApplicationListeners = new LinkedHashSet<>(this.applicationListeners);
    }
    else {
      // 重置事件存储容器
      this.applicationListeners.clear();
      this.applicationListeners.addAll(this.earlyApplicationListeners);
    }

    // 存储容器中早期事件的容器，在多播器可用时进行发布
    this.earlyApplicationEvents = new LinkedHashSet<>();
  }
```

## obtainFreshBeanFactory();

初始化BeanFactory；这一步主要完成了BeanFactory的创建以及获取；

```Java
protected ConfigurableListableBeanFactory obtainFreshBeanFactory() {
  refreshBeanFactory();
  return getBeanFactory();
}

@Override
protected final void refreshBeanFactory() throws BeansException {
  // 判断是否已有bean factory
  if (hasBeanFactory()) {
    // 销毁 beans
    destroyBeans();
    // 关闭 bean factory
    closeBeanFactory();
  }
  try {
    // 实例化 DefaultListableBeanFactory
    DefaultListableBeanFactory beanFactory = createBeanFactory();
    // 设置序列化id
    beanFactory.setSerializationId(getId());
    // 自定义bean工厂的一些属性（是否覆盖、是否允许循环依赖）
    customizeBeanFactory(beanFactory);
    // 解析XML配置文件，加载应用中的BeanDefinitions
    loadBeanDefinitions(beanFactory);
    synchronized (this.beanFactoryMonitor) {
      // 赋值当前bean facotry
      this.beanFactory = beanFactory;
    }
  }
  catch (IOException ex) {
    throw new ApplicationContextException("I/O error parsing bean definition source for " + getDisplayName(), ex);
  }
} 

protected DefaultListableBeanFactory createBeanFactory() {
  return new DefaultListableBeanFactory(getInternalParentBeanFactory());
} 
```

在源码中可以获得以下三个重要信息：

1. 调用`refreshBeanFactory()`方法创建了BeanFactory，它的默认实现是`DefaultListableBeanFactory()`

2. 调用了`loadBeanDefinitions()`方法，完成了配置文件的解析，并封装成了`BeanDefinitions`对象存储到`BeanFactory`中；

3. `getBeanFactory();`获取创建好的`BeanFactory`并返回

## prepareBeanFactory(beanFactory);

BeanFactory的预准备工作，对BeanFactory进行一些默认设置；

```Java
protected void prepareBeanFactory(ConfigurableListableBeanFactory beanFactory) {
  // 上下文以及类加载器设置
  beanFactory.setBeanClassLoader(getClassLoader());
  beanFactory.setBeanExpressionResolver(new StandardBeanExpressionResolver(beanFactory.getBeanClassLoader()));
  beanFactory.addPropertyEditorRegistrar(new ResourceEditorRegistrar(this, getEnvironment()));

  // 配置BeanFactory的上下文回调
  beanFactory.addBeanPostProcessor(new ApplicationContextAwareProcessor(this));
  // 设置忽略的自动装配接口，如：EnvironmentAware、EmbeddedValueResolverAware、ResourceLoaderAware等。
  beanFactory.ignoreDependencyInterface(EnvironmentAware.class);
  beanFactory.ignoreDependencyInterface(EmbeddedValueResolverAware.class);
  beanFactory.ignoreDependencyInterface(ResourceLoaderAware.class);
  beanFactory.ignoreDependencyInterface(ApplicationEventPublisherAware.class);
  beanFactory.ignoreDependencyInterface(MessageSourceAware.class);
  beanFactory.ignoreDependencyInterface(ApplicationContextAware.class);

  // 注册可以解析的自动装配，可以直接在其它组件中自动注入，如：BeanFactory、ResourceLoaderAware、ApplicationEventPublisher、ApplicationContext。
  beanFactory.registerResolvableDependency(BeanFactory.class, beanFactory);
  beanFactory.registerResolvableDependency(ResourceLoader.class, this);
  beanFactory.registerResolvableDependency(ApplicationEventPublisher.class, this);
  beanFactory.registerResolvableDependency(ApplicationContext.class, this);

  // 添加BeanPostProcessor——ApplicationListenerDetector
  beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(this));

  // Detect a LoadTimeWeaver and prepare for weaving, if found.
  if (beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
    beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
    // Set a temporary ClassLoader for type matching.
    beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
  }

  // 添加常用系统组件
  if (!beanFactory.containsLocalBean(ENVIRONMENT_BEAN_NAME)) {
    beanFactory.registerSingleton(ENVIRONMENT_BEAN_NAME, getEnvironment());
  }
  if (!beanFactory.containsLocalBean(SYSTEM_PROPERTIES_BEAN_NAME)) {
    beanFactory.registerSingleton(SYSTEM_PROPERTIES_BEAN_NAME, getEnvironment().getSystemProperties());
  }
  if (!beanFactory.containsLocalBean(SYSTEM_ENVIRONMENT_BEAN_NAME)) {
    beanFactory.registerSingleton(SYSTEM_ENVIRONMENT_BEAN_NAME, getEnvironment().getSystemEnvironment());
  }
}
```

BeanFactory的一些必要配置，不赘述。

## postProcessBeanFactory(beanFactory);

BeanFactory准备工作完成后进行的后置处理工作，Spring预留的切入点，子类通过重写这个方法，在BeanFactory创建并预准备完成后做进一步的操作。

## invokeBeanFactoryPostProcessors(beanFactory);

执行`BeanFactoryPostProcessor`，`BeanFactoryPostProcessor`是`BeanFactory`的后置处理器，执行时机是`BeanFactory`标准初始化之后执行的，涉及接口：`BeanFactoryPostProcessor`、`BeanDefinitionRegistryPostProcessor`等。

```Java
protected void invokeBeanFactoryPostProcessors(ConfigurableListableBeanFactory beanFactory) {
  // 执行后置处理器（内部代码太长，不贴了，自行看），获取到所有的BeanFactoryPostProcessor 
  // 排序后依次执行（排序方式按照：实现PriorityOrdered、实现Ordered接口、未实现优先级接口）
  PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(beanFactory, getBeanFactoryPostProcessors());

  // Detect a LoadTimeWeaver and prepare for weaving, if found in the meantime
  // (e.g. through an @Bean method registered by ConfigurationClassPostProcessor)
  if (beanFactory.getTempClassLoader() == null && beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
    beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
    beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
  }
}



```

这部分主要就是执行容器中`BeanFactoryPostProcessor` 的子类，对其子类注入`BeanFactory`，拆分一下执行流程大概分为以下四步：

1. 获取所有`BeanDefinitionRegistryPostProcessor`

2. 按照优先级进行排序，并按照优先级顺序执行`BeanDefinitionRegistryPostProcessor#postProcessBeanDefinitionRegistry(registry);`，优先级顺序按照：实现`PriorityOrdered`、实现`Ordered`接口、未实现优先级接口

3. 获取所有`BeanFactoryPostProcessor`

4. 按照优先级进行排序，并按照先后顺序执行`BeanFactoryPostProcessor#postProcessBeanFactory(beanFactory);`，优先级顺序按照：实现`PriorityOrdered`、实现`Ordered`接口、未实现优先级接口

## registerBeanPostProcessors(beanFactory);

注册`BeanPostProcessor`，`BeanPostProcessor`是Bean的后置处理器，用于拦截Bean 的创建过程，以下为内置的一些`BeanPostProcessor`：

> `BeanPostProcessor
DestructionAwareBeanPostProcessor
InstantiationAwareBeanPostProcessor
SmartInstantiationAwareBeanPostProcessor
MergedBeanDefinitionPostProcessor`

```Java
protected void registerBeanPostProcessors(ConfigurableListableBeanFactory beanFactory) {
  PostProcessorRegistrationDelegate.registerBeanPostProcessors(beanFactory, this);
}


public static void registerBeanPostProcessors(
      ConfigurableListableBeanFactory beanFactory, AbstractApplicationContext applicationContext) {

 // 获取所有类型为 BeanPostProcessor 的BeanName
 String[] postProcessorNames = beanFactory.getBeanNamesForType(BeanPostProcessor.class, true, false);

  // Register BeanPostProcessorChecker that logs an info message when
  // a bean is created during BeanPostProcessor instantiation, i.e. when
  // a bean is not eligible for getting processed by all BeanPostProcessors.
  int beanProcessorTargetCount = beanFactory.getBeanPostProcessorCount() + 1 + postProcessorNames.length;
  beanFactory.addBeanPostProcessor(new BeanPostProcessorChecker(beanFactory, beanProcessorTargetCount));

  // 按照实现PriorityOrdered接口，Ordered接口和未实现优先级接口的顺序排序BeanPostProcessor
  List<BeanPostProcessor> priorityOrderedPostProcessors = new ArrayList<>();
  List<BeanPostProcessor> internalPostProcessors = new ArrayList<>();
  List<String> orderedPostProcessorNames = new ArrayList<>();
  List<String> nonOrderedPostProcessorNames = new ArrayList<>();
  for (String ppName : postProcessorNames) {
    if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
      BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
      priorityOrderedPostProcessors.add(pp);
      if (pp instanceof MergedBeanDefinitionPostProcessor) {
        internalPostProcessors.add(pp);
      }
    }
    else if (beanFactory.isTypeMatch(ppName, Ordered.class)) {
      orderedPostProcessorNames.add(ppName);
    }
    else {
      nonOrderedPostProcessorNames.add(ppName);
    }
  }

  // 首先注册实现PriorityOrdered接口的后置处理器
  sortPostProcessors(priorityOrderedPostProcessors, beanFactory);
  registerBeanPostProcessors(beanFactory, priorityOrderedPostProcessors);

  // 然后注册实现 Ordered 接口的后置处理器
  List<BeanPostProcessor> orderedPostProcessors = new ArrayList<>();
  for (String ppName : orderedPostProcessorNames) {
    BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
    orderedPostProcessors.add(pp);
    if (pp instanceof MergedBeanDefinitionPostProcessor) {
      internalPostProcessors.add(pp);
    }
  }
  sortPostProcessors(orderedPostProcessors, beanFactory);
  registerBeanPostProcessors(beanFactory, orderedPostProcessors);

  // 最后注册没有实现优先级接口的后置处理器
  List<BeanPostProcessor> nonOrderedPostProcessors = new ArrayList<>();
  for (String ppName : nonOrderedPostProcessorNames) {
    BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
    nonOrderedPostProcessors.add(pp);
    if (pp instanceof MergedBeanDefinitionPostProcessor) {
      internalPostProcessors.add(pp);
    }
  }
  registerBeanPostProcessors(beanFactory, nonOrderedPostProcessors);

  // 最后注册 MergedBeanDefinitionPostProcessor
  sortPostProcessors(internalPostProcessors, beanFactory);
  registerBeanPostProcessors(beanFactory, internalPostProcessors);

  // 最后在BeanPostProcessor的链尾再加入ApplicationListenerDetector
  // ApplicationListenerDetector作用功能是用于检测容器中的ApplicationLisenter，将其注册到上下文中
  beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(applicationContext));
} 
```

上边代码比较长，其实做的事并没有这么复杂，主要就是对容器中后置处理器的排序，然后遍历注册的过程：

1. 获取所有`BeanPostProcessor`，不同接口类型的`BeanPostProcessor`，执行时机不同；【后置处理器都可以通过`PriorityOrdered`、`Ordered`指定优先级】

2. 按照优先级进行排序，并按照先后顺序注册（`beanFactory#addBeanPostProcessor(postProcessor);`），优先级顺序：实现`PriorityOrdered`、实现`Ordered`接口、未实现优先级接口

3. 最后注册`MergedBeanDefinitionPostProcessor`类型的后置处理器

4. 最终注册负责扫描发现监听器子类的处理器`ApplicationListenerDetector`，在Bean创建完成后，检查是不是`ApplicationListener`类型，如果是就注册到容器中

## initMessageSource();

初始化`MessageSource`组件（国际化、消息绑定、消息解析）

```Java
protected void initMessageSource() {
  ConfigurableListableBeanFactory beanFactory = getBeanFactory();
  // MESSAGE_SOURCE_BEAN_NAME = "messageSource"，尝试在BeanFactory中获取ID为messageSource
  // 并且类型为MessageSource的Bean，如果有直接赋值
  if (beanFactory.containsLocalBean(MESSAGE_SOURCE_BEAN_NAME)) {
    this.messageSource = beanFactory.getBean(MESSAGE_SOURCE_BEAN_NAME, MessageSource.class);
    // Make MessageSource aware of parent MessageSource.
    if (this.parent != null && this.messageSource instanceof HierarchicalMessageSource) {
      HierarchicalMessageSource hms = (HierarchicalMessageSource) this.messageSource;
      if (hms.getParentMessageSource() == null) {
        // Only set parent context as parent MessageSource if no parent MessageSource
        // registered already.
        hms.setParentMessageSource(getInternalParentMessageSource());
      }
    }
    if (logger.isTraceEnabled()) {
      logger.trace("Using MessageSource [" + this.messageSource + "]");
    }
  }
  
  // 如果没有就直接赋值类型为DelegatingMessageSource的实例
  else {
    // Use empty MessageSource to be able to accept getMessage calls.
    DelegatingMessageSource dms = new DelegatingMessageSource();
    dms.setParentMessageSource(getInternalParentMessageSource());
    this.messageSource = dms;
    beanFactory.registerSingleton(MESSAGE_SOURCE_BEAN_NAME, this.messageSource);
    if (logger.isTraceEnabled()) {
      logger.trace("No '" + MESSAGE_SOURCE_BEAN_NAME + "' bean, using [" + this.messageSource + "]");
    }
  }
}
```

在这一步可以看出，如果我们需要使用国际化组件，只需要把`MessageSource`注册到容器中，获取国际化配置文件时，可以注入`MessageSource`组件进行使用：

1. 尝试在BeanFactory中获取id为`messageSource`且类型为`MessageSource`的组件

2. 如果有就拿过来直接赋值；如果没有就自己创建一个`DelegatingMessageSource`；

## initApplicationEventMulticaster();

初始化事件派发器

```Java
protected void initApplicationEventMulticaster() {
  ConfigurableListableBeanFactory beanFactory = getBeanFactory();
  // APPLICATION_EVENT_MULTICASTER_BEAN_NAME = "applicationEventMulticaster"
  // 尝试在容器中获取ID为applicationEventMulticaster并且类型为ApplicationEventMulticaster的Bean
  // 如果有直接赋值
  if (beanFactory.containsLocalBean(APPLICATION_EVENT_MULTICASTER_BEAN_NAME)) {
    this.applicationEventMulticaster =
        beanFactory.getBean(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, ApplicationEventMulticaster.class);
    if (logger.isTraceEnabled()) {
      logger.trace("Using ApplicationEventMulticaster [" + this.applicationEventMulticaster + "]");
    }
  }
  // 如果没有，那么构建一个SimpleApplicationEventMulticaster实例注册到容器中
  else {
    this.applicationEventMulticaster = new SimpleApplicationEventMulticaster(beanFactory);
    beanFactory.registerSingleton(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, this.applicationEventMulticaster);
    if (logger.isTraceEnabled()) {
      logger.trace("No '" + APPLICATION_EVENT_MULTICASTER_BEAN_NAME + "' bean, using " +
          "[" + this.applicationEventMulticaster.getClass().getSimpleName() + "]");
    }
  }
}
```

这一步和国际化组件的初始化流程类型，可以我们自身指定它的实现，如果不指定也没关系，因为Spring会有自身默认的实现

1. 尝试在BeanFactory中获取id为`applicationEventMulticaster`且类型为`ApplicationEventMulticaster`的组件；如果有则直接赋值到`applicationEventMulticaster`

2. 如果未找到`applicationEventMulticaster`组件，则会自动创建一个`SimpleApplicationEventMulticaster`的事件派发器，并将其添加到添加到容器中

## onRefresh();

容器初始化期间执行的操作，子类重写这个方法，在容器刷新的时候可以自定义逻辑；如创建Tomcat，Jetty等WEB服务器

## registerListeners();

将所有事件监听器注册到容器中，也就是注册实现了`ApplicationListener`的Bean

```Java
protected void registerListeners() {
  // 获取预先存放的事件监听器
  for (ApplicationListener<?> listener : getApplicationListeners()) {
    getApplicationEventMulticaster().addApplicationListener(listener);
  }

  // 获取容器中所有类型为ApplicationListener 的Bean，注册到容器中
  String[] listenerBeanNames = getBeanNamesForType(ApplicationListener.class, true, false);
  for (String listenerBeanName : listenerBeanNames) {
    getApplicationEventMulticaster().addApplicationListenerBean(listenerBeanName);
  }

  // 派发之前产生的事件
  Set<ApplicationEvent> earlyEventsToProcess = this.earlyApplicationEvents;
  this.earlyApplicationEvents = null;
  if (earlyEventsToProcess != null) {
    for (ApplicationEvent earlyEvent : earlyEventsToProcess) {
      getApplicationEventMulticaster().multicastEvent(earlyEvent);
    }
  }
}
```

总结下来其实也就是以下三个步骤：

1. 拿到容器中所有`ApplicationListener`

2. 将每个事件监听器添加到事件派发器中

3. 派发之前产生的事件

## finishBeanFactoryInitialization(beanFactory);

初始化所有剩下的单实例Bean，其中调用的`beanFactory.preInstantiateSingletons();`方法用于实现初始化其余单实例Bean的逻辑

1. 获取容器中所有的Bean，依次进行初始化和创建对象`RootBeanDefinition`

2. 依次获取Bean的定义信息

3. 判断Bean：不是抽象的 && 是单实例的 && 不是懒加载的

1. 判断是否是FactoryBean：是否是实现了FactoryBean接口。如果是则调用`getObject();`获取对象；

2. 如果不是FactoryBean，利用`getBean(beanName);`创建对象

1. 先获取缓存中保存的单实例Bean，如果能获取到说明之前已经创建过（所有创建的Bean都会被缓存起来）`Map singletonObjects = new ConcurrentHashMap(256);`

2. 如果缓存中获取不到Bean，开始创建Bean流程

3. 标记当前Bean已经被创建【`markBeanAsCreated(beanName);`】

4. 获取Bean定义信息【`final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);`】

5. 【获取当前Bean依赖的其它Bean（`String[] dependsOn = mbd.getDependsOn();`）。如果有，按照`getBean()`方式，把依赖的Bean先创建出来】

6. 启动单实例Bean创建流程（`createBean(beanName, mbd, args);`）

1. `resolveBeforeInstantiation(beanName, mbdToUse);`让`BeanPostProcessor`先拦截返回代理对象；如果是`InstantiationAwareBeanPostProcessor`类型，则执行`postProcessBeforeInstantiation`方法，如果有返回值，再触发`postProcessAfterInitialization`方法

2. 如果前边的`InstantiationAwareBeanPostProcessor`没有返回代理对象，则执行3，如果返回了代理对象则直接返回Bean

3. 执行`Object beanInstance = doCreateBean(beanName, mbdToUse, args);`创建Bean

1. 【创建Bean实例】`createBeanInstance(beanName, mbd, args);`，利用工厂方法或对象构造器创建Bean实例

2. `applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);`，调用`MergedBeanDefinitionPostProcessor#postProcessMergedBeanDefinition`方法

3. 【Bean属性赋值】`populateBean(beanName, mbd, instanceWrapper);`

1. 执行`InstantiationAwareBeanPostProcessor`后置处理器的`postProcessAfterInstantiation`方法

2. 执行`InstantiationAwareBeanPostProcessor`后置处理器的`postProcessPropertyValues`方法

3. `applyPropertyValues(beanName, mbd, bw, pvs);`应用Bean的属性值，为属性利用getset方法等进行赋值

1. 【Bean初始化】`initializeBean(beanName, exposedObject, mbd);`

1. 【执行Aware】`invokeAwareMethods(beanName, bean);`执行xxxAwaer接口方法；如：`BeanNameAware`、`BeanClassLoaderAware`、`BeanFactoryAware`

2. 【执行后置处理器初始化之前的方法】`applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);` ，执行`BeanPostProcessor#postProcessBeforeInitialization`方法

3. 【执行Bean初始化方法】`invokeInitMethods(beanName, wrappedBean, mbd);`

1. 判断是不是实现了`InitializingBean`接口，如果是执行该接口规定的初始化方法

2. 判断是不是自定义了初始化方法

1. 【执行初后置处理器初始化之后方法】`applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);`，执行`BeanPostProcessor#postProcessAfterInitialization`方法

1. 【注册Bean销毁方法】`registerDisposableBeanIfNecessary(beanName, bean, mbd);`

2. 将创建的Bean存入缓存：`singletonObjects`，IOC就是Map，很多的Map保存了单实例Bean、环境信息等。。。

1. 所有Bean都利用`getBean()`创建完成之后，检查所有的Bean是否实现了`SmartInitializingSingleton`接口，如果是就执行`afterSingletonsInstantiated`方法

## finishRefresh();

完成BeanFactory的初始化创建工作，IOC容器创建完成

```Java
protected void finishRefresh() {
  // 清空上下文资源缓存
  clearResourceCaches();

  // 初始化生命周期相关后置处理
  initLifecycleProcessor();

  // 拿到声明周期处理器，回调容器刷新完成方法
  getLifecycleProcessor().onRefresh();

  // 发布容器刷新完成事件
  publishEvent(new ContextRefreshedEvent(this));

  LiveBeansView.registerApplicationContext(this);
}
```

这一步主要就是完成一些收尾工作：

1. 初始化生命周期相关后置处理器；我们可以写一个`LifecycleProcessor`的实现类，可以在`BeanFactory`刷新完成和关闭的时候进行一次自定义操作。

2. 拿到生命周期处理器（`LifecycleProcessor`），回调容器刷新完成方法

3. 发布容器刷新完成事件

# 总结

1. Spring容器启动时，会保存所有注册进来的Bean定义信息；xml、注解方式

2. Spring容器会在合适的时机创建这些注册好的Bean，使用这个Bean的时候，利用`getBean()`创建Bean，创建完成以后保存在容器中；方法`finishBeanFactoryInitialization(beanFactory);`统一创建剩下的单实例Bean；

3. 后置处理器：每一个Bean注册完成后，都会使用各种后置处理器进行处理，来增强Bean的功能；`AutowireAnnotationBeanPostProcessor`【处理自动注入】、`AnnotationAwareAspectJProxyCreator`【AOP功能】、`AsyncAnnotationBeanPostProcessor`【异步处理接口】

4. 事件驱动模型：`ApplicationListener`【事件监听】、ApplicationEventMulticaster【事件派发】