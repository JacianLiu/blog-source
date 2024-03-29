---
title: 一文详解Spring循环依赖
tags:
  - Spring
categories:
  - Spring
toc: true
cover: 'https://img.jacian.com/note/img/20200826163449.png'
article-thumbnail: 'false'
date: 2020-12-16 23:45:37
copyright_author: Kevin Lee
copyright_author_href: https://ksisn.com/2020/11/30/2020-11-30一文详解spring循环依赖/
---

## 什么是循环依赖？

大家都知道spring的核心是一个实现了AOP的IOC容器，那么IOC容器对于bean的初始化，会遇到以下情况：当BeanA初始化时，它依赖的对象BeanB也需要执行初始化，如果BeanB里也依赖了BeanA,则又会开始执行BeanA的初始化，那么这样会无限循环，导致初始化异常如下所示。
<!-- more -->

![在这里插入图片描述](https://img-blog.csdnimg.cn/20201206003911766.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2tzaXNu,size_16,color_FFFFFF,t_70#pic_center)

Spring已经很好的解决了这个问题，这个解决方法就是三级缓存。

## 什么是三级缓存？

我们以上图中A、B互相依赖为例，spring为了解决循环依赖问题，做了以下步骤：

- A通过反射创建的“初级bean”a放入到三级缓存中，再执行a的属性填充，这时发现依赖B，开启B的初始化。

- B通过反射生成的“初级bean”b放入到三级缓存中，再执行b的属性填充，这时发现依赖A，开启A的初始化。

- 从三级缓存中找到a，A不再创建新对象，把它移动到二级缓存中，返回a。

- b拿到a的引用，设置到b对应的字段上，属性填充完成，将b从三级缓存暴露到一级缓存中，返回b。

- a拿到b的引用，设置到a对应的字段上，属性填充完成，将a从二级缓存暴露到一级缓存中，返回a，A对应的实例Bean初始化完成。

  **其简易时序图**：

![在这里插入图片描述](https://img.jacian.com/note/img/20201216234410.png)

**逻辑图如下：**

![在这里插入图片描述](https://img.jacian.com/note/img/20201216234418.jpeg)

**咱们再看看三级缓存的存储结构**：

```java
/** Cache of singleton objects: bean name to bean instance. */
	/** 一级缓存，初始化完成的SpringBean均放置其中 */
	private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);

	/** Cache of early singleton objects: bean name to bean instance. */
	/** 二级缓存，反射完成后，还未填充属性的初级对象但是其他对象查询过时从三级中移动到二级 */
	private final Map<String, Object> earlySingletonObjects = new HashMap<>(16);

/** Cache of singleton factories: bean name to ObjectFactory. */
	/** 三级缓存，反射完成后，还未填充属性的初级对象放置其中 */
	private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);
1234567891011
```

为什么三级缓存earlySingletonObjects和二级缓存singletonFactories的初始容量16，而一级缓存容量为256呢？笔者认为因为二级、三级仅仅是在处理依赖时会使用到，这种多重循环依赖的情况在实际项目中应该是少数，所以不用使用太大的空间。而最终spring实例化完成的bean会放置在一级缓存中，所以默认容量会调大一些，毕竟spring有很多自身的bean也是放置在这里面的，比如systemEnvironment、systemProperties、messageSource、applicationEventMulticaster等。

## spring的源码阅读

当单例对象不存在时，会通过org.springframework.beans.factory.support.DefaultSingletonBeanRegistry#getSingleton(java.lang.String, org.springframework.beans.factory.ObjectFactory<?>)方法来获取单例对象。

```java
public Object getSingleton(String beanName, ObjectFactory<?> singletonFactory) {
		/** 省略部分代码 */
		synchronized (this.singletonObjects) {
			Object singletonObject = this.singletonObjects.get(beanName);
			// 在一级缓存singletonObjects中拿到为空 
			if (singletonObject == null) {
				/** 省略状态检查部分代码 */
				
				
				boolean newSingleton = false;
				
				try {
					// 传进来的调用，lamda表达式使用
					singletonObject = singletonFactory.getObject();
					// *********重要*********：singletonFactory.getObject()执行完毕，标记此类已经初始化完成
					// bean初始化完成，标记为新的单例对象
					newSingleton = true;
				}
				catch (IllegalStateException ex) {
					/** 省略部分代码 */
				}
				finally {
					if (recordSuppressedExceptions) {
						this.suppressedExceptions = null;
					}
					afterSingletonCreation(beanName);
				}
				// 如果是新的单例对象，暴露到一级缓存中
				if (newSingleton) {
					addSingleton(beanName, singletonObject);
				}
			}
			return singletonObject;
		}
	}
	
	/**
	 * Add the given singleton object to the singleton cache of this factory.
	 * <p>To be called for eager registration of singletons.
	 * @param beanName the name of the bean
	 * @param singletonObject the singleton object
	 */
	protected void addSingleton(String beanName, Object singletonObject) {
		synchronized (this.singletonObjects) {
			// 加入到一级缓存，从二级和三级缓存中移除;
			this.singletonObjects.put(beanName, singletonObject);
			this.singletonFactories.remove(beanName);
			this.earlySingletonObjects.remove(beanName);
			this.registeredSingletons.add(beanName);
		}
	}
```

上面代码中的singletonFactory.getObject() 无疑是执行创建的关键代码：

org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBean(java.lang.String, org.springframework.beans.factory.support.RootBeanDefinition, java.lang.Object[])方法

```java
/**
	 * Central method of this class: creates a bean instance,
	 * populates the bean instance, applies post-processors, etc.
	 * @see #doCreateBean
	 */
	@Override
	protected Object createBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)
			throws BeanCreationException {

		// 拿到Bd
		RootBeanDefinition mbdToUse = mbd;

		// Make sure bean class is actually resolved at this point, and
		// clone the bean definition in case of a dynamically resolved Class
		// which cannot be stored in the shared merged bean definition.
		// 获得类信息
		Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
		if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
			mbdToUse = new RootBeanDefinition(mbd);
			mbdToUse.setBeanClass(resolvedClass);
		}

		// Prepare method overrides.
		try {
            // 检查该bean是否有重载方法
			mbdToUse.prepareMethodOverrides();
		}
		catch (BeanDefinitionValidationException ex) {
			/** 省略部分代码 */
		}

		try {
			// Give BeanPostProcessors a chance to return a proxy instead of the target bean instance.
			Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
			// 尝试获取代理对象;
			if (bean != null) {
				return bean;
			}
		}
		catch (Throwable ex) {
			/** 省略部分代码 */
		}

		try {
			// 进入，真真正正创建bean
			Object beanInstance = doCreateBean(beanName, mbdToUse, args);
			return beanInstance;
		}
		catch (Throwable ex) {
			/** 省略部分代码 */
		}
	}
```

再来看看doCreateBean方法

```java
/**
	 * Actually create the specified bean. Pre-creation processing has already happened
	 * at this point, e.g. checking {@code postProcessBeforeInstantiation} callbacks.
	 * <p>Differentiates between default bean instantiation, use of a
	 * factory method, and autowiring a constructor.
	 * @param beanName the name of the bean
	 * @param mbd the merged bean definition for the bean
	 * @param args explicit arguments to use for constructor or factory method invocation
	 * @return a new instance of the bean
	 * @throws BeanCreationException if the bean could not be created
	 * @see #instantiateBean
	 * @see #instantiateUsingFactoryMethod
	 * @see #autowireConstructor
	 */
	protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)
			throws BeanCreationException {

		
		BeanWrapper instanceWrapper = null;
		if (mbd.isSingleton()) {
			instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
		}
		if (instanceWrapper == null) {
			// 创建 Bean 实例，仅仅调用构造方法，但是尚未设置属性
			instanceWrapper = createBeanInstance(beanName, mbd, args);
		}
		final Object bean = instanceWrapper.getWrappedInstance();
		Class<?> beanType = instanceWrapper.getWrappedClass();
		if (beanType != NullBean.class) {
			mbd.resolvedTargetType = beanType;
		}

		/** 省略部分代码 */

		// Eagerly cache singletons to be able to resolve circular references
		// even when triggered by lifecycle interfaces like BeanFactoryAware.
		boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
				isSingletonCurrentlyInCreation(beanName));
		if (earlySingletonExposure) {
            // 暴露到三级缓存中
			addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
		}

		// 初始化bean实例
		Object exposedObject = bean;
		try {
			// Bean属性填充
			populateBean(beanName, mbd, instanceWrapper);
			// 调用初始化方法，应用BeanPostProcessor后置处理器
			exposedObject = initializeBean(beanName, exposedObject, mbd);
		}
		catch (Throwable ex) {
			/** 省略部分代码 */
		}

		if (earlySingletonExposure) {
			// 调用一次getSingleton(beanName, false)方法->" + beanName)，只从一级、二级缓存中拿，传入false不需要从三级添加到二级缓存;
            // 核心逻辑是：如果提前暴露到了二级，则返回二级缓存中的对象引用，此时可能获取得到的是原对象的代理对象。因为AOP动态代理时，会将对象提升二级缓存，本文不再详述此问题
			Object earlySingletonReference = getSingleton(beanName, false);
			if (earlySingletonReference != null) {
				if (exposedObject == bean) {
					exposedObject = earlySingletonReference;
				}
				else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
					/** 省略部分代码,检查依赖对象是否均创建完成 */
				}
			}
		}

		// Register bean as disposable.
		try {
            // 初始化完成后一些注册操作
			registerDisposableBeanIfNecessary(beanName, bean, mbd);
		}
		catch (BeanDefinitionValidationException ex) {
			/** 省略部分代码 */
		}

		return exposedObject;
	}
```

从doCreateBean方法可以看出：先调用构造方法，生成初级bean，然后暴露到三级缓存，然后执行属性填充，最表标记bean初始化完成，如果二级缓存有，则替换引用，最后完成注册并返回对象。

那么这个填充属性方法populateBean(String beanName, RootBeanDefinition mbd, @Nullable BeanWrapper bw) 又做了什么呢？

```java
protected void populateBean(String beanName, RootBeanDefinition mbd, @Nullable BeanWrapper bw) {
		/** 省略部分代码 */

		PropertyValues pvs = (mbd.hasPropertyValues() ? mbd.getPropertyValues() : null);

		int resolvedAutowireMode = mbd.getResolvedAutowireMode();
		if (resolvedAutowireMode == AUTOWIRE_BY_NAME || resolvedAutowireMode == AUTOWIRE_BY_TYPE) {
			MutablePropertyValues newPvs = new MutablePropertyValues(pvs);
			// Add property values based on autowire by name if applicable.
			if (resolvedAutowireMode == AUTOWIRE_BY_NAME) {
				autowireByName(beanName, mbd, bw, newPvs);
			}
			// Add property values based on autowire by type if applicable.
			if (resolvedAutowireMode == AUTOWIRE_BY_TYPE) {
				autowireByType(beanName, mbd, bw, newPvs);
			}
			pvs = newPvs;
		}

		boolean hasInstAwareBpps = hasInstantiationAwareBeanPostProcessors();
		boolean needsDepCheck = (mbd.getDependencyCheck() != AbstractBeanDefinition.DEPENDENCY_CHECK_NONE);

		PropertyDescriptor[] filteredPds = null;
		if (hasInstAwareBpps) {
			if (pvs == null) {
				pvs = mbd.getPropertyValues();
			}
			for (BeanPostProcessor bp : getBeanPostProcessors()) {
				if (bp instanceof InstantiationAwareBeanPostProcessor) {
					InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
					PropertyValues pvsToUse = ibp.postProcessProperties(pvs, bw.getWrappedInstance(), beanName);
					if (pvsToUse == null) {
						if (filteredPds == null) {
							filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
						}
						pvsToUse = ibp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
						if (pvsToUse == null) {
							return;
						}
					}
					pvs = pvsToUse;
				}
			}
		}
		if (needsDepCheck) {
			if (filteredPds == null) {
				filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
			}
			checkDependencies(beanName, mbd, filteredPds, pvs);
		}

		if (pvs != null) {
			applyPropertyValues(beanName, mbd, bw, pvs);
		}
	}
```

代码比较多，核心思想就是获取这个bean里的所有依赖bean，然后调用applyPropertyValues方法去创建对应的依赖bean，并设置到对应的属性上。

```java
protected void applyPropertyValues(String beanName, BeanDefinition mbd, BeanWrapper bw, PropertyValues pvs) {
		/** 省略部分代码 */
		BeanDefinitionValueResolver valueResolver = new BeanDefinitionValueResolver(this, beanName, mbd, converter);

		// Create a deep copy, resolving any references for values.
		List<PropertyValue> deepCopy = new ArrayList<>(original.size());
		boolean resolveNecessary = false;
		for (PropertyValue pv : original) {
			if (pv.isConverted()) {
				deepCopy.add(pv);
			}
			else {
                String propertyName = pv.getName();
                Object originalValue = pv.getValue();
                // *** 将依赖的属性目标，转化为初始化完成后的bean
                Object resolvedValue = valueResolver.resolveValueIfNecessary(pv, originalValue);
                Object convertedValue = resolvedValue;
                /** 省略部分代码 */
                pv.setConvertedValue(convertedValue);
                deepCopy.add(pv);
                /** 省略部分代码 */
			}
		}
	/** 省略部分代码 */
	}
```

valueResolver.resolveValueIfNecessary方法经过一些的方法，最终调用beanFactory.getBean，这个方法会回到开始进行新一轮的创建bean

```java
private Object resolveInnerBean(Object argName, String innerBeanName, BeanDefinition innerBd) {
    String[] dependsOn = mbd.getDependsOn();
    if (dependsOn != null) {
        for (String dependsOnBean : dependsOn) {
            this.beanFactory.registerDependentBean(dependsOnBean, actualInnerBeanName);
            // 初始化bean
            this.beanFactory.getBean(dependsOnBean);
        }
    }
}
```

allowEarlyReference传入true，对于新的bean，已经在三级缓存中存在，会将三级缓存转移到二级缓存，并返回bean，不用真正的去创建一个bean。

```java
protected Object getSingleton(String beanName, boolean allowEarlyReference) {
		
		boolean needWarn = true;
		Object singletonObject = this.singletonObjects.get(beanName);
		if (singletonObject == null && isSingletonCurrentlyInCreation(beanName)) {
			synchronized (this.singletonObjects) {
				logger.warn("当前bean已注册，从一级earlySingletonObjects中拿不到->" + beanName + "：" + singletonObject);
				singletonObject = this.earlySingletonObjects.get(beanName);
				if (singletonObject == null && allowEarlyReference) {
					logger.warn("当前bean已注册，从二级缓存earlySingletonObjects中拿不到->" + beanName + "：" + singletonObject);
					ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName);
					if (singletonFactory != null) {
						singletonObject = singletonFactory.getObject();
						this.earlySingletonObjects.put(beanName, singletonObject);
						this.singletonFactories.remove(beanName);
						needWarn = false;
						logger.warn("当前bean已注册，从三级singletonFactories中拿到，并移动到二级缓存earlySingletonObjects->" + beanName + "  ： " + singletonObject);
					}
				}
			}
		}
		if (needWarn) {
			logger.warn("从三级缓存中查询，调用DefaultSingletonBeanRegistry.getSingleton(beanName, allowEarlyReference)->得到" + beanName + ":" + singletonObject + "   ,allowEarlyReference：" + allowEarlyReference);
		}
		return singletonObject;
	}
```

所以第三步的Bean B属性填充方法此时完成，Bean B被加载到一级缓存中。由此回溯，Bean A的属性填充完成，Bean A被加载到一级缓存中。可结合本文最开始给出的时序图进行参考。

## 其他问题

### 为什么要用三级缓存而不是二级?

我们可以从三级缓存的值类型看出，一、二级的值均为Spring Bean对象的引用，三级对象则为ObjectFactory的引用。

```java
/** Cache of singleton objects: bean name to bean instance. */
	/** 一级缓存，初始化完成的SpringBean均放置其中 */
	private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);

	/** Cache of early singleton objects: bean name to bean instance. */
	/** 二级缓存，反射完成后，还未填充属性的初级对象但是其他对象查询过时从三级中移动到二级 */
	private final Map<String, Object> earlySingletonObjects = new HashMap<>(16);

/** Cache of singleton factories: bean name to ObjectFactory. */
	/** 三级缓存，反射完成后，还未填充属性的初级对象放置其中 */
	private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);
```

#### 为什么要有ObjectFactory类型的第三级缓存？

将对象从三级缓存singletonFactories中移动到二级缓存时，会执行ObjectFactory的getBean方法，再调用到getEarlyBeanReference方法，最终遍历该Bean对应的所有SmartInstantiationAwareBeanPostProcessor进行执行；熟悉spring的朋友们肯定知道，SmartInstantiationAwareBeanPostProcessor是Spring Aop动态代理相关属性处理器。执行后获得一个新的bean，该bean是原bean代理对象。

```java
// 新生成一个Factory对象，并设置其getBean方法为getEarlyBeanReference
addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
// 等价于以下代码
/* addSingletonFactory(beanName, new ObjectFactory<Object>() {
				@Override
				public Object getObject() throws BeansException {
					return getEarlyBeanReference(beanName, mbd, bean);
				}
			}); */
123456789
// getEarlyBeanReference方法：将会遍历其所有的SmartInstantiationAwareBeanPostProcessor（智能化属性处理器，然后进行执行）
protected Object getEarlyBeanReference(String beanName, RootBeanDefinition mbd, Object bean) {
		Object exposedObject = bean;
		if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
			for (BeanPostProcessor bp : getBeanPostProcessors()) {
				if (bp instanceof SmartInstantiationAwareBeanPostProcessor) {
					SmartInstantiationAwareBeanPostProcessor ibp = (SmartInstantiationAwareBeanPostProcessor) bp;
					exposedObject = ibp.getEarlyBeanReference(exposedObject, beanName);
				}
			}
		}
		return exposedObject;
	}
```

也就是说，三级缓存 存在的目的就是增强对象，当需要使用spring的aop功能时返回代理对象，如果咱们永远用不到代理对象，三级缓存理论上可以不用。

#### 既然三级缓存为了获取代理对象，只保留一三级缓存、第二级缓存可以不要吗？

理论上可以，只需要两级缓存就可以解决循环依赖的问题，但在处理循环依赖的过程，一级缓存中将可能同时存在完整Spring Bean A 和 半成品Spring Bean B。三级对象getObject之后直接放置到二级，最后再刷到一级，二级到一级这个过程中并无额外的处理。

那么为什么spring要使用三级呢？笔者认为一是为了规范各级缓存职责单一原则，不让一级缓存中出现完整的bean和半成品bean；二是为了避免半成品bean被其他线程获取后进行调用，降低实现的难度。
