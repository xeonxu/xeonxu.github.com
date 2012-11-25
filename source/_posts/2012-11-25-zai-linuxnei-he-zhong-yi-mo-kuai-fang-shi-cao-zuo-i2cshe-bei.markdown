---
layout: post
title: "在Linux内核模块中操作I2C设备"
date: 2012-11-25 00:02
comments: true
categories: Linux Android 开发
---

<p>
近期公司项目较为空闲，抽空做了一些学习性质的研发内容，其中涉及到在Linux内核模块中使用I2C对外部器件进行控制的操作。虽然在Linux中操作使用I2C设备并不复杂，但本人接触Linux内核驱动开发时间并不算长，此次学习中也算较为系统的了解了Linux中对I2C设备的操控方式，谨在此做下记录。
</p>
<p>
通过Linux内核文档中关于操作I2C设备的文章后不难看出Linux中注册使用I2C设备一般通过四种方法<sup><a class="footref" name="fnr.1" href="#fn.1">1</a></sup>：
</p><ol>
<li>通过总线号声明设备
</li>
<li>立即探测设备
</li>
<li>通过Probe探测相应设备
</li>
<li>在用户空间立即探测
</li>
</ol>


<p>
简单来说，第一种方式一般应用在嵌入式设备中。因为对于嵌入式设备来说，外围器件基本都是固定的，只需提供有限几款器件的支持即可。使用这种方式的时候，需要在板级配置文件中定义并设置 <code>i2c_board_info</code> 这个结构体的内容。其中需要配置设备名称和设备地址，此外设备中断和私有数据结构也可以选择设置。然后使用 <code>i2c_register_board_info</code> 这个接口对设置的设备进行注册使用。需要注意的是这种方法注册的设备是在注册I2C总线驱动时进行驱动适配的。
</p>
<p>
第二种方法可以通过给定的I2C适配器以及相应的I2C板级结构体，自行通过 <code>i2c_new_device</code> 接口进行添加注册所需的设备。这种方法灵活性要较第一种方法大，可以很方便的在模块中使用。
</p>
<p>
第三种方法是 <code>2.6</code> 内核之前的做法，使用 <code>detect</code> 方法去探测总线上的设备驱动。因为探测机制的原因，会导致一些副作用的发生，所以不建议使用，除非真的没有别的办法。
</p>
<p>
第四种方法是在Linux的控制台上，在用户空间通过sysfs，使用 <code>/sys/bus/i2c/devices/i2c-3/new_device</code> 节点进行设备的添加注册。
</p>
<p>
从上面可以看出，如果需要在Linux内核中以模块的方式对I2C设备进行驱动控制的话，第二种方法是比较推荐的。通过测试，在module的init中使用
{% codeblock lang:c %}
struct i2c_adapter *i2c_adap;
struct i2c_client *i2c_client;
i2c_adap = i2c_get_adapter(1);
i2c_client = i2c_new_device(i2c_adap, &i2c_device);
i2c_put_adapter(i2c_adap);
{% endcodeblock %}
即可成功注册I2C设备。其中:
{% codeblock lang:c %}
static struct i2c_board_info ft5306_i2c_device = {
    I2C_BOARD_INFO("test_i2c", 0x11),
};
{% endcodeblock %}

以上，对于如何在模块中注册使用I2C设备简单做了描述。那么如何在另外的模块中对已经注册的I2C设备进行反注册呢？由于内核中操作I2C设备都是通过 <code>i2c_client</code> 结构进行，所以问题可以抽象为如何在内核中获取指定设备的 <code>i2c_client</code> 结构指针。通过查阅内核API，也找到了一个方法可以达到这样的目的，如下：
{% codeblock lang:c %}
struct i2c_client *i2c_client;
struct device *i2c_dev;

i2c_dev = bus_find_device_by_name(&i2c_bus_type, NULL, "1-0011");
if(i2c_dev)
    i2c_client  =  container_of(i2c_dev, struct i2c_client, dev);
if(i2c_client)
    i2c_unregister_device(i2c_client);
{% endcodeblock %}
该反注册例子的内容就是对前面注册的 <code>0x11</code> 地址的设备进行反注册。注意 <code>bus_find_device_by_name</code> 函数中第三项参数，该参数是需要查找的设备在总线上注册的名称。"1"代表着1号适配器，"0011"是16位的I2C地址。如此便可方便的在内核模块中对I2C设备进行挂载和解挂了。
</p>
<div id="footnotes">
<h2 class="footnotes">Footnotes: </h2>
<div id="text-footnotes">
<p class="footnote"><sup><a class="footnum" name="fn.1" href="#fnr.1">1</a></sup> 参考Linux内核目录下的Documentation/i2c/instantiating-devices
</p>



</div>
</div>
