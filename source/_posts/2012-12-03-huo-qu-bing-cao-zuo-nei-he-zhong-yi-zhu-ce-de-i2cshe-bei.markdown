---
layout: post
title: "获取并操作内核中已注册的I2C设备"
date: 2012-12-03 00:00
comments: true
categories: Linux Android 开发
---

<p>
之前写过一篇关于如何在Linux内核模块中注册操作I2C设备的<a href="http://blog.xeonxu.info/blog/2012/11/25/zai-linuxnei-he-zhong-yi-mo-kuai-fang-shi-cao-zuo-i2cshe-bei/">文章</a> ，那篇文章最后介绍的方法虽然可行，但是会带来一个问题：如果内核中已经包含有某设备的驱动时，那么在模块中注册该设备的I2C client之前必须先将内核中的驱动进行反注册解挂，然后才能再次注册模块中定义的驱动。这样做带来的问题就是，当你将模块从内核中卸载后，系统将无法再次注册内核中原有的驱动，导致相应设备无法使用。今天补充的方法可以在挂载模块时使用模块内的设备驱动，而在卸载后恢复回系统原来的驱动。
</p>
<p>
内容相当简单，上次我们已经可以通过内核提供的接口函数，找到相应I2C总线相应地址I2C设备的I2C client结构指针。而拥有该指针后，其实就可以做很多事了。比如调用 <code>i2c_master_send</code> 接口向该client指向的设备发送I2C命令。这样，如果需要扩展内核中原有的驱动程序，比如向procfs或sysfs中添加相应的用户空间接口等。一般可以在 <code>module_init</code> 中注册sysfs入口的操作函数，然后在操作函数中通过操作该client指针而实现一定的功能。这种方法可以沿用系统内核中原有的设备驱动，可以单纯添加一些系统驱动中没有的功能。
</p>
<p>
除此之外，还有一种替换内核中现有驱动的方法。通过查阅源代码，可以发现内核中还提供一个 <code>device_reprobe(dev)</code> 的API，该函数接受一个device结构体指针，实现重新匹配设备驱动的操作。同时，I2C client结构体中也有相应的device结构体。我们知道Linux内核匹配I2C设备驱动是通过名称来进行匹配的，所以，我们的方法就是用Hack的方式将系统中获取到的I2C Client结构体的名称改为我们需要的名称。一般修改为我们模块中新建的驱动的名称，这样，当调用 <code>device_reprobe</code> 接口后，系统会将原有驱动remove并重新为相应I2C设备适配一个驱动程序。当然，没有出错的话，它会适配到我们修改的名称指向的驱动。如此，我们便可以在内核模块中编写独立的设备驱动程序了。以下是简单示例框架:
{% codeblock lang:c %}
struct i2c_client *this_client = NULL;

static struct i2c_driver my_driver = {
    .driver = {
        .name = NEW_DRIVER_NAME,
        .owner = THIS_MODULE,
    },
    .probe = my_probe,
    .remove = my_remove,
};

static int __init module_driver_init(void)
{
    struct device *ts_dev = NULL;
    int rc;

    i2c_add_driver(&my_driver);

    ts_dev = bus_find_device_by_name(&i2c_bus_type, NULL, "1-0011");
    if(!ts_dev)
    {
        pr_info("Did not match the device name:1-0011!\n");
        goto device_error_exit;
    }
    this_client  =  container_of(ts_dev, struct i2c_client, dev);

    if(!this_client)
    {
        goto device_error_exit;
    }

    memcpy(this_client->name, NEW_DRIVER_NAME, I2C_NAME_SIZE);
    rc = device_reprobe(ts_dev);
    return 0;

  device_error_exit:
    i2c_del_driver(&my_driver);
    pr_info("ts i2c del driver");
    return -1;
}
{% endcodeblock %}
只需要实现其中的 <code>my_probe</code> , <code>my_remove</code> 等函数即可实现一个完整的驱动。需要注意的是一定要在调用 <code>device_reprobe</code> 接口之前将相应的设备驱动使用 <code>i2c_add_driver</code> 添加到系统中，否则重新适配中会找不到驱动。移除模块时，用同样的方法将I2C client的名称更改为系统中原有驱动的名称，并重新适配驱动，即可实现卸载模块后系统能够使用原有驱动的功能。示例如下：
{% codeblock lang:c %}
static void __exit module_driver_exit(void)
{
    int rc;

    memcpy(this_client->name, ORIGIN_DRIVER_NAME, I2C_NAME_SIZE);

    rc = device_reprobe(&this_client->dev);

    i2c_del_driver(&my_driver);
}
{% endcodeblock %}

最后需要注意，文中方法皆为本人翻查文档自己琢磨搞出来的，所以不排除存在隐患的可能，但在自己测试环境下使用中没有发现任何问题。如果有疑问，也希望各位看官能提出自己的看法。
</p>