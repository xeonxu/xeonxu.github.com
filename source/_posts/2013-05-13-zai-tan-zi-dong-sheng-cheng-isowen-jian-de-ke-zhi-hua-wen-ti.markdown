---
layout: post
title: "再谈自动生成ISO文件的客制化问题"
date: 2013-05-13 22:37
comments: true
categories: Android Linux Qualcomm 开发
---

<p>
由于最近项目中又有要求说要对手机自带的虚拟驱动光盘的内容做客户定制化，于是基于上篇文章中使用make系统动态构建ISO镜像文件的方法，我又加入了客制化脚本的支持。实现的方法很简单，思路是在make工程下规定一个目录专门做客制化目录，目录下包含以不同项目名称命名的子目录，而相应子目录下便是客户定制的具体内容；同时，每个项目子目录中还包含有一个客制化脚本，用于对光盘文件系统进行重命名或者删减的操作。
</p>
<p>
由于之前已经有了自动生成ISO文件的make系统，基于以上的思路实现下来，加入的代码并不多。首先是改造主makefile：
{% codeblock lang:makefile %}
# Author: Zhiqiang Xu
# Version: 1.2
# Date: 2013.05.09
# Change Log:
# 1.1 Makefile to generate cdrom iso file. Only generate iso file without icon in default.
# 1.2 Add script support to customize cdrom's contents.

CDROM_FS            ?= ./CDROM_OBJ
TARGET_CDROM        ?= ./cdrom_install.iso
PRODUCT_DRIVERNAME  ?= Phicomm
CDROM_ROOT          ?= ./

ICON_NAME       := "$(PRODUCT_DRIVERNAME).ico"
ORIGIN_ICON     := $(CDROM_ROOT)/custom/$(PRODUCT_DRIVERNAME)/$(ICON_NAME)
CUSTOMIZE       := $(CDROM_ROOT)/custom/$(PRODUCT_DRIVERNAME)
CUSTOMIZE_SCRIPT := $(CDROM_FS)/custom.sh
AUTORUN_FILE     := $(CDROM_FS)/autorun.inf

all:$(CDROM_FS)
    mkisofs -input-charset utf-8 -V "$(PRODUCT_DRIVERNAME) Driver" -J -r -l -v -o $(TARGET_CDROM) $(CDROM_FS)

clean:
    @rm -f $(TARGET_CDROM)
    @rm -rf $(CDROM_FS)

cdrom_new:clean
    @mkdir -p $(CDROM_FS)
    @if [ -e $(CUSTOMIZE) ]; then \
    cp -rf $(CUSTOMIZE)/* $(CDROM_FS)/; \
    fi

$(AUTORUN_FILE):cdrom_new
    @if [ -e $(ORIGIN_ICON) ]; then \
    cp -f $(ORIGIN_ICON) $(CDROM_FS)/; \
    echo "[autorun]\r" > $(AUTORUN_FILE); \
    echo "icon=\"\\$(ICON_NAME)\"\r" >> $(AUTORUN_FILE); \
    fi

$(CDROM_FS):$(AUTORUN_FILE)
    @cp -rf $(CDROM_ROOT)/driver/* $(CDROM_FS)
    @if [ -e $(CUSTOMIZE_SCRIPT) ]; then \
        sh $(CUSTOMIZE_SCRIPT) "$(CDROM_FS)"; \
    fi
{% endcodeblock %}
相较之前的版本，我在其中新增了两个变量 <code>CUSTOMIZE</code> 和 <code>CUSTOMIZE_SCRIPT</code> ，这两个变量分别用来指定不同项目所用的客制化目录和客制化脚本。注意， <code>ORIGIN_ICON</code> 变量的内容和原来相比也有变化，路径由原来的 <code>custom</code> 目录变为了相应的项目子目录，这样对于不同的项目来说也容易管理一些。另外，在 <code>cdrom_new</code> tag段，加入了拷贝客制化内容到iso文件系统的语句。对于主makefile最核心的修改实在最后一个tag段，也就是 <code>$(CDROM_FS)</code> 段的最后一句if判断，判断客制化脚本是否存在，如果存在，则以iso文件系统路径为参数执行该脚本。makefile的改动就这么些，接下来看客制化脚本 <code>custom.sh</code> 的内容。
</p>


{% codeblock lang:bash %}
#!/bin/sh
# Author: Zhiqiang Xu
# Version: 1.0
# Script which is used to customize contents of cdrom.

SCRIPT_FILE=$0
CDROM_FS=$1

rm -f $CDROM_FS/PC_Modem_Drivers_Install_Help.pdf
rm -f $CDROM_FS/PHICOMM_USB_Drivers_Install_Help.pdf

#Do not REMOVE!
rm $SCRIPT_FILE
{% endcodeblock %}

<p>
对于一般的项目，默认都是使用 <code>driver/</code> 目录下的内容作为驱动光盘的内容，其中默认包含两份中文pdf说明。但是对于外单项目来讲，肯定不能使用中文说明，那么我们就需要将其从光盘文件系统中删除。以上的脚本就做了这么一件事情，删除了光盘文件系统中的两份pdf文件。脚本最后将脚本自身从光盘文件系统中删除，否则最后生成的iso文件中还包含制作脚本，那将是一件很怪异可笑的事情。从makefile中看，客制化脚本会在生成ISO文件前一步执行，因此，客制化脚本的权限是相当大的，基本上可以实现你想对光盘文件系统执行的一切操作。
</p>
<p>
到此，客制化光盘的需求就完全解决了，前后实现起来也就10分钟时间。最后吐槽一遍，Android的make系统太复杂太慢，如果不是我之前在这个模块中直接使用传统make系统，对应这个简单的需求困怕也要多花费2-3倍的时间。
</p>