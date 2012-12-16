---
layout: post
title: "嵌入式系统内核驱动模块化转换的简单框架"
date: 2012-12-15 15:57
comments: true
categories: Linux Android
---

<p>
如前篇文章所述，使用模块化方式开发内核驱动可以有效减少编译时间，从而提高开发效率。除此之外，内核模块使用 <code>insmod</code> 载入内核时可以像使用应用程序一样像内核模块中传入特定参数，参数完全由开发者定义。像中断号，GPIO管脚，总线号，设备地址，log等级等等，都可以通过内核参数进行传入。这意味着可以在只编译一次内核驱动模块的情况下，通过传入不同的参数就可以修改驱动程序的属性，大大提高灵活性，对于Debug更加方便。
</p>
<p>
由于在嵌入式系统中，注册设备驱动时也要相应将设备注册到系统中，而设备注册逻辑一般都存放在如 <code>Board_xxxx.c</code> 这类板级驱动文件中。这种安排方式在模块化驱动中显得不是很方便，因为载入模块的系统中需要先注册过设备，这也意味着需要先将相应设备信息添加入板级配置文件后才能使用模块驱动。为此，我想实现一个简单的包装框架，实现以下两个目的：
</p><ol>
<li>修改尽可能少的代码进行驱动模块化
</li>
<li>模块化的驱动可以方便的整合到原系统中，无需做多余的改动
</li>
</ol>


<p>
按照这个想法，我使用ft5x0x的tp驱动完成了驱动模块化转换的简单框架。其中包含两个部分，分别如下：
{% codeblock 模块包装文件 lang:c %}
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/i2c.h>
#include <linux/err.h>
#include <linux/delay.h>
#include <linux/gpio.h>
#include <asm/uaccess.h>

#include <linux/fs.h>
#include <linux/mm.h>

#include "ft5x06_ts.h"

extern int init_wrapper(void);
extern void exit_wrapper(void);

#define module_PRINT_ERR     (1U << 0)
#define module_PRINT_WARNING (1U << 1)
#define module_PRINT_INFO    (1U << 2)
#define module_PRINT_DEBUG   (1U << 3)

#ifndef DEFAULT_DEV_NAME
#define DEFAULT_DEV_NAME "ft5x0x_ts"
#endif
#ifndef DEFAULT_DEV_ADAP
#define DEFAULT_DEV_ADAP 255
#endif
#ifndef DEFAULT_DEV_ADDR
#define DEFAULT_DEV_ADDR 0x38
#endif

#define pr_module(debug_level_mask, args...)                    \
    do {                                                        \
        if (debug_mask & module_PRINT_##debug_level_mask) {     \
            printk(KERN_##debug_level_mask "[module_driver] "args);    \
        }                                                       \
    } while (0)

static int debug_mask = module_PRINT_ERR | \
    module_PRINT_INFO  | \
    module_PRINT_WARNING  | module_PRINT_DEBUG ;
module_param_named(debug_mask, debug_mask, int, S_IRUGO | S_IWUSR | S_IWGRP);
static u8 local_device_adap = DEFAULT_DEV_ADAP;
module_param_named(adap, local_device_adap, byte, S_IRUGO | S_IWUSR | S_IWGRP);
MODULE_PARM_DESC(adap, "Set the i2c adapter of device.");
static u8 local_device_addr = DEFAULT_DEV_ADDR;
module_param_named(addr, local_device_addr, byte, S_IRUGO | S_IWUSR | S_IWGRP);
MODULE_PARM_DESC(addr, "Set the address of device.");

static struct i2c_client *this_client = NULL;
static struct MODULE_DRIVER_INFO {
    struct i2c_board_info *this_device_info;
    void(*prepare_func)(void);
} module_driver_info = {
    .this_device_info = &ft5x0x_device_info,
    .prepare_func = ft5x06_touchpad_setup
};

static int __init module_driver_init(void)
{
    /* int rc; */
    struct i2c_adapter *i2c_adap;

    pr_module(INFO,"Enter in %s\n", __func__);

    /* Init GPIOs */
    if(module_driver_info.prepare_func)
        (*module_driver_info.prepare_func)();

    /* Add device driver. */
    init_wrapper();
    module_driver_info.this_device_info->addr = local_device_addr;
    /* Add i2c device to platform */
    i2c_adap = i2c_get_adapter(local_device_adap);
    if (NULL == i2c_adap)
    {
        pr_module(ERR, "%s: i2c_get_adapter for %d failed\n", __func__, local_device_adap);
        goto error_adapter;
    }
    this_client = i2c_new_device(i2c_adap, module_driver_info.this_device_info);
    if (NULL == this_client)
    {
        pr_module(ERR, "%s: i2c_new_device for %s failed\n", __func__, module_driver_info.this_device_info->type);
        goto error_device;
    }
    pr_module(INFO, "%s: this_client:%p, addr:%#x\n", __func__, this_client, this_client->addr);
    i2c_put_adapter(i2c_adap);
    return 0;

  error_device:
    i2c_put_adapter(i2c_adap);
  error_adapter:
    exit_wrapper();
    return -1;
}

static void __exit module_driver_exit(void)
{
    pr_module(INFO,"Enter in %s\n", __func__);
    exit_wrapper();
    i2c_unregister_device(this_client);
}

module_init(module_driver_init);
module_exit(module_driver_exit);

MODULE_AUTHOR("zhiqiang.xu<zhiqiang.xu@phicomm.com.cn>");
MODULE_DESCRIPTION("i2c device module driver");
MODULE_LICENSE("GPL v2");
{% endcodeblock %}
以上为部分内容， 其中需要实现板级设备信息 <code>ft5x0x_device_info</code> 和设备初始化函数 <code>ft5x06_touchpad_setup</code> 。其实也就是将板级文件中的相应信息拷贝过来即可。
</p>


{% codeblock 原驱动文件的修改 lang:c %}
#if defined(MODULE)
int init_wrapper(void)
{
    return ft5x0x_ts_init();
}
EXPORT_SYMBOL(init_wrapper);

void exit_wrapper(void)
{
    ft5x0x_ts_exit();
}
EXPORT_SYMBOL(exit_wrapper);
#else
module_init(ft5x0x_ts_init);
module_exit(ft5x0x_ts_exit);

MODULE_AUTHOR("<luowj>");
MODULE_DESCRIPTION("FocalTech ft5x0x TouchScreen driver");
MODULE_LICENSE("GPL");
#endif
{% endcodeblock %}
<p>
由于内核模块中只能存在一对 <code>module_init</code> 和 <code>module_exit</code> ，所以在原驱动文件中使用模块宏 <code>MODULE</code> 将这部分排除，同时使用统一的包装函数名称将驱动初始化函数和退出函数包装起来，并导出符号。
</p>
<p>
最后，参照上篇文章内容编写 <code>Makefile</code> 文件，如下：
{% codeblock lang:makefile %}
# Author: zhiqiang.xu
# EMail : xeonxu@gmail.com
# Date  : 2012-12-11
CROSS_ARCH:=ARCH=arm CROSS_COMPILE="$(ARM_EABI_TOOLCHAIN)/arm-eabi-"
KDIR:=$(ANDROID_PRODUCT_OUT)/obj/KERNEL_OBJ/
PWD:=$(shell pwd)

test_driver-objs := module_driver.o ft5x06_ts.o focaltech_ctl.o  ft5x06_ex_fun.o
obj-m:= test_driver.o
.PHONY: modules package clean
all:package
modules:
    @if [ "$(ANDROID_BUILD_TOP)" = "" ]; then echo "You have to run \". build/envsetup.sh\" to init enviroment first. \nAnd then you have to run
\"choosecombo\" to setup the project."&&exit 1; fi
    @if [ ! -d $(KDIR) ]; then echo "Build kernel first."&&cd $(ANDROID_BUILD_TOP)&&make -j4 bootimage&&cd -; fi
    $(MAKE) $(CROSS_ARCH) -C $(KDIR) M=$(PWD) modules

package:modules
    @mkdir -p ./package
    @cp *.bat ./package
    @cp $(obj-m:.o=.ko) ./package
    @tar --transform='s,package,test_driver,' -jcf test_driver.tar.bz2 ./package/

clean:
    rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions *.order *.symvers package test_driver.tar.bz2
{% endcodeblock %}

修改后的驱动文件使用make即可直接编译出模块驱动，同时该驱动中也包含了设备注册的相关处理，所以相对来说更加独立。完整的驱动文件如下：
<a href="https://docs.google.com/open?id=0B5GJiOxO7LkWVDVQMy0tcDBoejg"> <code>test_driver.tar.bz2</code> </a>
</p>