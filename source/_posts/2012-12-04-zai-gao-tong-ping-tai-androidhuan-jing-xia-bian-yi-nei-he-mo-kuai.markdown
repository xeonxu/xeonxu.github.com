---
layout: post
title: "在高通平台Android环境下编译内核模块"
date: 2012-12-04 22:14
comments: true
categories: Linux Android 开发
---

<p>
高通Android环境中Linux内核会作为Android的一部分进行编译，直接使用make即可一次性从头编到尾。而有的平台比如Marvell，内核的编译操作相对比较独立，必须使用标准的内核编译命令进行单独编译。一般来说，用高通的这种方式比较傻瓜化，一步到底的感觉；而用Marvell的方式用户干预较多，灵活性也更大。当然这里不是比较他们孰优孰劣，对我来说这两种方式各有千秋。在遇到具体问题时，有时还会觉得独立编译内核的方式比较方便，比如编译内核模块这一点上。
</p>
<p>
编译内核模块之前必须先编译内核，编译内核之前必须先指定内核配置。在独立编译内核情况下，编译一遍内核后，可以直接使用 <code>make module</code> 来编译内核模块，如果修改了相应模块文件，使用相同的命令也能很快的进行增量编译。而在高通环境下，由于内核的编译过程已经被集成到Android的编译中，所以每次编译内核或者内核模块时，都必须通过Android的编译环境进行启用。虽然Android提供诸如 <code>make bootimage</code> 命令，可以只编译bootimage相关内容，但是Android庞大的编译体系在初始化时也会占用很多的时间。前段时间在调试一个独立的内核模块时就一直被这个问题困扰着，每次修改模块代码后都必须通过 <code>make bootimage</code> 来编译。虽然只有一个文件，但是每次编译都花费至少1min30sec，严重影响了开发进度。为此，自己参考内核模块独立编译的Makefile和Android的环境特点写了一个内核模块编译Makefile。
{% codeblock lang:makefile %}
# Author: zhiqiang.xu
# EMail:  xeonxu@gmail.com
CROSS_ARCH:=ARCH=arm CROSS_COMPILE="$(ARM_EABI_TOOLCHAIN)/arm-eabi-"
KDIR:=$(ANDROID_PRODUCT_OUT)/obj/KERNEL_OBJ/
PWD:=$(shell pwd)

obj-m:= my_module.o
.PHONY: modules package clean
all:package
modules:
    @if [ "$(ANDROID_BUILD_TOP)_yes" = "_yes" ]; then echo "You have to run \". build/envsetup.sh\" to init enviroment first. \nAnd then you have to run
\"choosecombo\" to setup the project."&&exit 1; fi
    @if [ ! -d $(KDIR) ]; then echo "Build kernle first."&&cd $(ANDROID_BUILD_TOP)&&make bootimage&&cd -; fi
    $(MAKE) $(CROSS_ARCH) -C $(KDIR) M=$(PWD) modules

package:modules
    @mkdir -p ./package
    @cp $(obj-m:.o=.ko) ./package

clean:
    rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions *.order *.symvers package
{% endcodeblock %}
该Makefile默认会将当前目录下的 <code>my_module.c</code> 文件编译为内核模块。同时，在编译时会强制检查Android的环境是否正确配置，如果没有配置它会进行相应提示后退出编译处理。编译模块时使用的内核配置是编译Android时指定项目所配置的内核配置。如果内核还没有编译，则在编译模块之前会自动编译内核主体。如果一切OK，则每次只会编译修改过的模块文件。编译好后会将模块文件单独拷贝到当前目录下的 <code>package</code> 目录中，方便使用。
</p>
<p>
使用该编译脚本后，模块的编写调试效率高了不少，至少每次编译模块都可以在5sec内搞定了。加上上机实测调试，也能在30sec内完成。生命很可贵，像我一样当个懒人吧。
</p>