---
layout: post
title: "在Android编译时建立符号链接"
date: 2012-10-08 21:48
comments: true
categories: Android 开发 Linux
---

<p>
最近接到一个任务，需要将Busybox环境移植到高通平台的Android项目上。Busybox的目标执行文件有现成编译好的，需要做的工作就是添加一个Android工程，将编译好的二进制文件拷贝到Android的文件系统中，同时还需要生成相应的Busybox命令链接。
</p>
<p>
拷贝文件到指定目录在Android的编译系统中有现成的方法，使用下面这个方法即可：
{% codeblock 拷贝文件到指定目录 lang:makefile %}
LOCAL_PATH := $(call my-dir)

# Add busybox environment zhiqiang.xu 2012.10.8
include $(CLEAR_VARS)
LOCAL_MODULE := busybox_modules
LOCAL_MODULE_STEM := busybox
LOCAL_SRC_FILES := busybox
LOCAL_MODULE_TAGS := eng
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_OUT)/busybox
include $(BUILD_PREBUILT)
{% endcodeblock %}
由于Busybox环境主要用于工程调试，所以模块设置为只在eng编译模式下有效。按照以上这段设置，可以将busybox执行文件拷贝到Android文件系统中的 <code>/system/busybox</code> 目录下。
</p>
<p>
而对于生成链接，之前没有接触过。不过在搜索调查了已有的Android工程文件之后，发现系统中也提供了现成的方法，如下：
{% codeblock recovery使用的软链生成方法 lang:makefile %}
BUSYBOX_LINKS := $(shell cat external/busybox/busybox-minimal.links)
ifndef BOARD_HAS_SMALL_RECOVERY
exclude := tune2fs
ifeq ($(BOARD_HAS_LARGE_FILESYSTEM),true)
exclude += mke2fs
endif
endif
RECOVERY_BUSYBOX_SYMLINKS := $(addprefix $(TARGET_RECOVERY_ROOT_OUT)/sbin/,$(filter-out $(exclude),$(notdir $(BUSYBOX_LINKS))))
$(RECOVERY_BUSYBOX_SYMLINKS): BUSYBOX_BINARY := busybox
$(RECOVERY_BUSYBOX_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
        @echo "Symlink: $@ -> $(BUSYBOX_BINARY)"
        @mkdir -p $(dir $@)
        @rm -rf $@
        $(hide) ln -sf $(BUSYBOX_BINARY) $@

ALL_DEFAULT_INSTALLED_MODULES += $(RECOVERY_BUSYBOX_SYMLINKS)
{% endcodeblock %}
实现方法使用了标准的Makefile目标，在 <code>$(RECOVERY_BUSYBOX_SYMLINKS)</code> 目标下生成相应链接，看起来似乎是只要将Makefile的目标添加到 <code>ALL_DEFAULT_INSTALLED_MODULES</code> 这个变量后，编译的时候就会按照Makefile的标准生成目标。实验后确实可行，不过同时我也发现了一个不足。那就是使用这种方法后，通过mm/mmm命令进行模块编译的时候是没法正确执行的。换言之， <code>ALL_DEFAULT_INSTALLED_MODULES</code> 变量只有在系统完全编译的时候才会被调用。为此，领悟范例的精神后，自己改了一下实现方法，如下：
</p>


{% codeblock 修改后的生成软链的方法 lang:makefile %}
ifneq (,$(filter userdebug eng,$(TARGET_BUILD_VARIANT)))

define _make_link
   $(shell echo "Symlink: $(1) -> $(2)")
   $(shell mkdir -p $(dir $(1)))
   $(shell rm -rf $(1))
   $(shell ln -sf $(2) $(1))
endef

# Add busybox environment zhiqiang.xu 2012.10.8
# Now let's do busybox symlinks
BUSYBOX_LINKS := $(shell cat $(LOCAL_PATH)/busybox.links)
BUSYBOX_SYMLINKS := $(addprefix $(TARGET_OUT)/busybox/,$(notdir $(BUSYBOX_LINKS)))
BUSYBOX_BINARY := /system/busybox/$(LOCAL_SRC_FILES)
$(foreach _item, $(BUSYBOX_SYMLINKS), \
       $(eval $(call _make_link,$(_item),$(BUSYBOX_BINARY))))

_make_link :=
endif
{% endcodeblock %}
<p>
修改后的方法使用了自定义宏，不论是全系统编译还是使用mm/mmm进行模块编译，每次编译的时候宏都会展开执行。同时为了区分编译模式，我又添加了相应的判断宏 <code>ifneq (,$(filter userdebug eng,$(TARGET_BUILD_VARIANT)))</code> 将执行部分包括在里面。实验下来效果良好，可以根据当前设定的编译模式生成或者不生成相应软链。
最后，发现一点，我修改的这个方法由于没有依赖目标，所以每次编译的时候都会执行一遍，编译效率不高，所以这种结构不能用于大负荷的处理工作。好在生成软链不是多重的工作，这么用用也无什么大碍。
</p>