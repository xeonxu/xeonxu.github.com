---
layout: post
title: "使用ccache优化Android的编译时间"
date: 2013-03-06 23:17
comments: true
categories: Android Qualcomm Linux 开发
---

<p>
最近在Android编译过程中发现，使用ccache也能很好的提升C/C++编译感受，虽然比不上分布式编译所带来的成倍编译速度的体验，但是减少一半编译时间还是绰绰有余的。其实在Android的编译系统中已经自带了对ccache的支持，之前我那篇讲解如何使用distcc编译Android的<a href="http://blog.xeonxu.info/blog/2012/08/30/da-jian-linuxxia-de-fen-bu-shi-bian-yi-xi-tong/#sec-4">文章</a> 中其实就是在ccache的支持基础上进行修改的。但是Android编译系统中的ccache只对Android系统的库文件等进行优化，并不包括Kernel和LK的编译。没搞明白为什么原生的编译系统没有包含这两部分的ccache支持，为此我自己修改了Android编译系统中Kernel和LK的Makefile文件。使用修改后的Makefile文件编译Kernel和LK时，第二次可以节省3-4分钟的时间。看上去时间不长，但是考虑到原来编译Kernel和LK时需要用时8分钟左右，这点提升也是有意义的。
</p>
<p>
修改非常简单，对于Kernel只需要修改
{% codeblock AndroidKernel.mk lang:diff %}
--- a/kernel/AndroidKernel.mk
+++ b/kernel/AndroidKernel.mk
@@ -62,30 +62,30 @@ $(KERNEL_OUT):
        mkdir -p $(KERNEL_OUT)

 $(KERNEL_CONFIG): $(KERNEL_OUT)
-       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- $(KERNEL_DEFCONFIG)
+       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE="ccache arm-eabi-" $(KERNEL_DEFCONFIG)

 $(KERNEL_OUT)/piggy : $(TARGET_PREBUILT_INT_KERNEL)
        $(hide) gunzip -c $(KERNEL_OUT)/arch/arm/boot/compressed/piggy.gzip > $(KERNEL_OUT)/piggy

 $(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
-       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- CONFIG_NO_ERROR_ON_MISMATCH=y
-       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- modules
-       $(MAKE) -C kernel O=../$(KERNEL_OUT) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) ARCH=arm CROSS_COMPILE=arm-eabi- modules_install
+       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE="ccache arm-eabi-" CONFIG_NO_ERROR_ON_MISMATCH=y
+       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE="ccache arm-eabi-" modules
+       $(MAKE) -C kernel O=../$(KERNEL_OUT) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) ARCH=arm CROSS_COMPILE="ccache arm-eabi-" modules_install
        $(mv-modules)
        $(clean-module-folder)
        $(append-dtb)

 $(KERNEL_HEADERS_INSTALL): $(KERNEL_OUT) $(KERNEL_CONFIG)
-       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- headers_install
+       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE="ccache arm-eabi-" headers_install

 kerneltags: $(KERNEL_OUT) $(KERNEL_CONFIG)
-       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- tags
+       $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE="ccache arm-eabi-" tags

 kernelconfig: $(KERNEL_OUT) $(KERNEL_CONFIG)
        env KCONFIG_NOTIMESTAMP=true \
-            $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- menuconfig
+            $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE="ccache arm-eabi-" menuconfig
        env KCONFIG_NOTIMESTAMP=true \
-            $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- savedefconfig
+            $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE="ccache arm-eabi-" savedefconfig
        cp $(KERNEL_OUT)/defconfig kernel/arch/arm/configs/$(KERNEL_DEFCONFIG)

 endif
{% endcodeblock %}

对于LK，修改文件AndroidBoot.mk
{% codeblock AndroidBoot.mk lang:diff %}
--- a/AndroidBoot.mk
+++ b/AndroidBoot.mk
@@ -23,6 +23,10 @@ else
   USER_SYSTEM := USER_SYSTEM=0
 endif

+ifeq ($(USE_CCACHE), 1)
+  CCACHE := CCACHE=$(ANDROID_BUILD_TOP)/prebuilts/misc/linux-x86/ccache/ccache
+endif
+
 # NAND variant output
 TARGET_NAND_BOOTLOADER := $(PRODUCT_OUT)/appsboot.mbn
 NAND_BOOTLOADER_OUT := $(TARGET_OUT_INTERMEDIATES)/NAND_BOOTLOADER_OBJ
@@ -50,11 +54,11 @@ $(EMMC_BOOTLOADER_OUT): emmc_appsbootldr_clean

 # Top level for NAND variant targets
 $(TARGET_NAND_BOOTLOADER): $(NAND_BOOTLOADER_OUT)
-       $(MAKE) -C bootable/bootloader/lk BOOTLOADER_OUT=../../../$(NAND_BOOTLOADER_OUT) $(BOOTLOADER_PLATFORM) $(SIGNED_KERNEL)
+       $(MAKE) -C bootable/bootloader/lk BOOTLOADER_OUT=../../../$(NAND_BOOTLOADER_OUT) $(BOOTLOADER_PLATFORM) $(SIGNED_KERNEL) $(CCACHE)

 # Top level for eMMC variant targets
 $(TARGET_EMMC_BOOTLOADER): $(EMMC_BOOTLOADER_OUT)
-       $(MAKE) -C bootable/bootloader/lk BOOTLOADER_OUT=../../../$(EMMC_BOOTLOADER_OUT) $(BOOTLOADER_PLATFORM) EMMC_BOOT=1 $(SIGNED_KERNEL)
+       $(MAKE) -C bootable/bootloader/lk BOOTLOADER_OUT=../../../$(EMMC_BOOTLOADER_OUT) $(BOOTLOADER_PLATFORM) EMMC_BOOT=1 $(SIGNED_KERNEL) $(CCACHE)

 # Keep build NAND & eMMC as default for targets still using TARGET_BOOTLOADER
 TARGET_BOOTLOADER := $(PRODUCT_OUT)/EMMCBOOT.MBN
@@ -77,4 +81,4 @@ $(NANDWRITE_OUT): nandwrite_clean

 $(TARGET_NANDWRITE): $(NANDWRITE_OUT)
        @echo $(BOOTLOADER_PLATFORM)_nandwrite
-       $(MAKE) -C bootable/bootloader/lk BOOTLOADER_OUT=../../../$(NANDWRITE_OUT) $(BOOTLOADER_PLATFORM)_nandwrite BUILD_NANDWRITE=1
+       $(MAKE) -C bootable/bootloader/lk BOOTLOADER_OUT=../../../$(NANDWRITE_OUT) $(BOOTLOADER_PLATFORM)_nandwrite BUILD_NANDWRITE=1 $(CCACHE)
{% endcodeblock %}

使用时，和Android编译环境默认开启ccache支持一样，只需要在编译环境中定义 <code>USE_CCACHE=1</code> 即可。
</p>