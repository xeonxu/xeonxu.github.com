---
layout: post
title: "使用Make系统自动生成手机驱动光盘"
date: 2013-03-24 21:36
comments: true
categories: Android Linux 开发 Qualcomm
---

<p>
蔽厂为了方便用户在拿到手机后能够顺利安装手机的电脑驱动，将相应的驱动文件打包成一个iso，然后借助Linux Usb Gadget的支持，在手机连接到电脑后会虚拟出一个驱动光盘来。实际效果蛮不错，但是问题在于，将驱动文件打包为iso的过程基本都靠人工手动完成。这于我这样喜爱偷懒的人来说，是极不科学的。于是我考虑将打包iso文件的操作自动化起来，实现步骤考虑是这样的，首先写下制作iso文件的Makefile，然后通过Android的编译系统调用改Makefile，这样在每次编译生成Android系统镜像的时候，就会自动生成相应iso文件了。
</p>
<p>
为了命令行中生成iso文件，首先需要找到相应的命令行程序。这点对于linux系统来说一点不难，现成的mkisofs就可搞定。接下来，需要制定生成相应iso的命令参数。这点也不难，通过查看mkisofs的man帮助即可快速找到所需要的各种参数。最后我决定使用的命令为： <code>mkisofs -input-charset utf-8 -V "Android Driver" -J -r -l -v -o cdrom.iso cdrom_fs/</code> 。这其中，我指定使用utf-8的编码作为输入编码，使用Android Driver作为光盘的卷标，添加joliet格式和rock ridge支持，冗余输出，将 <code>cdrom_fs/</code> 目录下的所有内容生成为cdrom.iso文件。
</p>
<p>
有了基础命令行，就可以写Makefile了。我写好的Makefile如下，其中还添加了光驱icon的支持：
{% codeblock makefile生成iso lang:makefile %}
# Author: Zhiqiang Xu
# Version: 1.1
# Date: 2013.03.22
# makefile to generate cdrom iso file. Only generate iso file without icon in default.

CDROM_FS            ?= ./CDROM_OBJ
TARGET_CDROM        ?= ./cdrom_install.iso
PRODUCT_DRIVERNAME  ?= Phicomm
CDROM_ROOT          ?= ./

ICON_NAME       := "$(PRODUCT_DRIVERNAME).ico"
ICON_PATH       :=
ORIGIN_ICON     := $(CDROM_ROOT)/custom/$(ICON_NAME)
AUTORUN_FILE    := $(CDROM_FS)/autorun.inf

all:$(CDROM_FS)
        mkisofs -input-charset utf-8 -V "$(PRODUCT_DRIVERNAME) Driver" -J -r -l -v -o $(TARGET_CDROM) $(CDROM_FS)

clean:
        @rm -f $(TARGET_CDROM)
        @rm -rf $(CDROM_FS)

cdrom_new:clean
        @mkdir -p $(CDROM_FS)/$(ICON_PATH)

$(AUTORUN_FILE):cdrom_new
        @if [ -e $(ORIGIN_ICON) ]; then \
        cp -f $(ORIGIN_ICON) $(CDROM_FS)/$(ICON_PATH)/; \
        echo "[autorun]\r" > $(AUTORUN_FILE); \
        echo "icon=\"$(ICON_PATH)\\$(ICON_NAME)\"\r" >> $(AUTORUN_FILE); \
        fi

$(CDROM_FS): $(AUTORUN_FILE)
        @cp -rf $(CDROM_ROOT)/driver/* $(CDROM_FS)
{% endcodeblock %}

我在这个makefile中定义了几个默认变量，目的就是为了在没有定义这些变量的时候，能有一个默认值。同时假定用来生成iso的文件都存放在driver目录下，以及需要使用的光盘图标文件都存放在当前目录的custom目录下。如果发现有和 <code>$(PRODUCT_DRIVERNAME)</code> 同名的图标文件，则在光盘根目录中生成相应的autorun.inf文件，以显示相应的光盘图标。写好了makefile，直接执行make就可以生成相应的iso文件。不过我的目的是和Android编译系统联动，所以还需要再做些工作。
</p>
<p>
参考Android中kernel的编译方法，我编写了AndroidCdrom.mk文件，如下：
{% codeblock AndroidCdrom.mk lang:makefile %}
# Author: Zhiqiang Xu
# Version: 1.1
# Date: 2013.03.22
# Android makefile to generate cdrom iso file

# cdrom variant output
# Set Default name to Phicomm
PRODUCT_DRIVERNAME      ?= Phicomm
PHICOMM_TARGET_CDROM    := $(TARGET_OUT)/etc/cdrom_install.iso
PHICOMM_CDROM_ROOT      := device/qcom/msm7627a/cdrom/
PHICOMM_CDROM_FS        := $(TARGET_OUT_INTERMEDIATES)/CDROM_OBJ/

$(PHICOMM_TARGET_CDROM):
        $(MAKE) -C $(abspath $(PHICOMM_CDROM_ROOT)) CDROM_FS=$(abspath $(PHICOMM_CDROM_FS)) TARGET_CDROM=$(abspath $(PHICOMM_TARGET_CDROM)) PRODUCT_DRIVERNAME="$(PRODUCT_DRIVERNAME)"
{% endcodeblock %}
内容相当简单，其实就是将Android编译系统中的一些环境变量和目录信息传递给刚才写的makefile中，传入的路径都转换为绝对路径，防止Android编译路径的变换造成文件生成失败。
</p>
<p>
最后一步，将该AndroidCdrom.mk文件添加到android的编译环境中。同样参照kernel的编译方法，在AndroidBoard.mk文件中添加如下两行：
{% codeblock AndroidBoard.mk lang:makefile %}
# 2013.3.20 zhiqiang.xu Add for generate cdrom iso
include device/qcom/msm7627a/cdrom/AndroidCdrom.mk

droidcore: $(PHICOMM_TARGET_CDROM)
{% endcodeblock %}
这其中的意思是将 <code>$(PHICOMM_TARGET_CDROM)</code> 这个目标依赖到droidcore目标上，而droidcore是生成android核心的标签，于是每次编译android时都会首先编译 <code>$(PHICOMM_TARGET_CDROM)</code> 目标，从而自动生成相应的iso文件。实际测试下来，效果非常好，每次修改了光盘中相应文件后，都不需要再自己手动生成iso文件了，编译Android时从头到尾一气呵成。
</p>
<p>
搞定！
</p>