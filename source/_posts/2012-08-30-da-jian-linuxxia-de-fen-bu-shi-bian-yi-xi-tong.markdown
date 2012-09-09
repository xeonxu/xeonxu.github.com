---
layout: post
title: "搭建Linux下的分布式编译系统"
date: 2012-08-30 23:46
comments: true
categories: Linux Android 开发
---


<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1 概述</a></li>
<li><a href="#sec-2">2 分布式编译系统的搭建</a>
<ul>
<li><a href="#sec-2-1">2.1 distcc简介</a></li>
<li><a href="#sec-2-2">2.2 distcc的安装</a></li>
<li><a href="#sec-2-3">2.3 distcc的配置</a>
<ul>
<li><a href="#sec-2-3-1">2.3.1 服务器端配置</a></li>
<li><a href="#sec-2-3-2">2.3.2 客户端配置</a></li>
</ul>
</li>
<li><a href="#sec-2-4">2.4 验证distcc</a></li>
</ul>
</li>
<li><a href="#sec-3">3 使用distcc进行效率对比</a>
<ul>
<li><a href="#sec-3-1">3.1 编译emacs</a></li>
<li><a href="#sec-3-2">3.2 编译Android的Linux内核</a></li>
</ul>
</li>
<li><a href="#sec-4">4 Android代码的分布式编译</a></li>
<li><a href="#sec-5">5 总结</a></li>
</ul>
</div>
</div>

<div id="outline-container-1" class="outline-2">
<h2 id="sec-1">概述</h2>
<div class="outline-text-2" id="text-1">

<p>在公司做手机软件研发已有一年多，前前后后接触过三种手机系统：MStar，MTK和Android。他们有一个共同的特点：代码非常庞大，每种系统都有超过1GB的源代码。如此大量的代码，编译起来是相当缓慢的。实际中，如果使用一台普通四核的机器进行编译的话，将至少需要一个小时才能完成一次完整的编译。长时间的编译等待，对于研发来讲是个极大的浪费。
</p>
<p>
好在事情没有一路悲剧，因为实际中确有一种方法可以提高代码的编译速度，那就是通过分布式编译工具来加速编译工作。何谓分布式编译？简而言之，就是借网络上其他电脑的空闲CPU给自己使用，从而加速编译工作。一般来讲，通过分布式编译工具可以借到的CPU数量是10至20个，这10到20个借来的CPU足以将编译效率提高300%~400%。像MStar系统如果使用分布式编译的话，完整的编译时间将会缩短到15分钟左右！相比单机一个多小时的编译时间来讲，这是非常大的效率提升！
</p>
<p>
Windows下的Incredibuild就是一款成熟的常用分布式编译软件，它提供编译协同处理，可以很好的协同网络上的其他计算机获取和利用他们的空余计算能力进行代码编译。开发MStar和MTK时，就是利用Incredibuild实现的分布编译。遗憾的是Android的系统开发将平台换成了Linux，Linux上有没有办法使用分布式编译呢？答案是肯定的。本文就将探讨如何在Linux上搭建及使用分布式编译系统。
</p>
</div>

</div>

<div id="outline-container-2" class="outline-2">
<h2 id="sec-2">分布式编译系统的搭建</h2>
<div class="outline-text-2" id="text-2">

<p>分布式编译系统，其实分两部分：编译器程序和分布式编译协同程序，像前面说的Windows下的Incredibuild软件其实就是分布式编译协同软件。编译器部分不用担心，Linux下的编译器种类非常丰富，有商业的也有开源的，一般我们使用开源的GCC系列编译器。而分布式协同软件，我们同样选择开源的distcc。
</p>

</div>

<div id="outline-container-2-1" class="outline-3">
<h3 id="sec-2-1">distcc简介</h3>
<div class="outline-text-3" id="text-2-1">

<p>distcc是一款符合GPL协议开源的分布式编译协同软件，它分为两个部分:distcc-client和distcc-server。distcc-client将代码的编译请求发送到distcc-server上，而distcc-server则会对代码按要求进行编译后回传至请求方，从而完成编译代码的动作。client可以和server装在同一台电脑上，也即是说一台电脑可以利用其他电脑进行分布编译，也可以在空闲的时候为其他电脑提供分布编译服务。下面，我们将着重讲解如何安装，配置和使用distcc。
</p>
</div>

</div>

<div id="outline-container-2-2" class="outline-3">
<h3 id="sec-2-2">distcc的安装</h3>
<div class="outline-text-3" id="text-2-2">

<p>distcc的项目主页为：<a href="http://code.google.com/p/distcc/">http://code.google.com/p/distcc/</a>， 主页上提供源代码以及安装包的下载。安装包默认提供deb和rpm软件包，分别用来适应Debian系和RedHat系的Linux系统，可以直接安装。如果比较追新和在意个性化定制，也可以下载最新的源代码进行编译后使用。本文采用编译源代码的方法进行安装。
从官网下载最新的 <code>3.1</code> 版的distcc软件包，名称为： <code>distcc-3.1.tar.bz2</code> 。
</p>
<p>
假如软件包下载后存放在 <code>~/Downloads</code> 目录下，使用命令：
</p>


{% codeblock lang:sh %}
mkdir -p ~/temp && tar jxvf ~/Downloads/distcc-3.1.tar.bz2 -C ~/temp
{% endcodeblock %}

<p>
将其解压至个人目录中的临时目录： <code>~/temp</code> 下。然后执行：
</p>


{% codeblock lang:sh %}
cd ~/temp
./configure
make
sudo make install
{% endcodeblock %}

<p>
安装时需要输入自己的密码，如果顺利的话，就会看到distcc安装完成了。不过目前这种状态还不能使用，需要对distcc进行配置。
</p>
</div>

</div>

<div id="outline-container-2-3" class="outline-3">
<h3 id="sec-2-3">distcc的配置</h3>
<div class="outline-text-3" id="text-2-3">

<p>配置分为两部分，客户端和服务端的配置，主要的配置文件存放在 <code>/etc/distcc</code> 目录下。
</p>

</div>

<div id="outline-container-2-3-1" class="outline-4">
<h4 id="sec-2-3-1">服务器端配置</h4>
<div class="outline-text-4" id="text-2-3-1">

<p>假设当前电脑所在网络IP地址为： <code>172.16.149.22</code> ，需要 <code>172.16</code> 网段的电脑都能够访问这台分布编译服务器，那么做如下配置：
</p>
<p>
修改 <code>/etc/distcc/client.allow</code> ，在最后一行添加
</p>



<pre class="example">#允许172.16网段的所有电脑连接本服务器
172.16.0.0/16
</pre>


<p>
修改 <code>/etc/distcc/commands.allow.sh</code> ，在 <code>allowed_compilers</code> 段里加入需要访问到的编译器程序。注意这里编译器程序可以使用通配符，但是路径需要使用绝对路径，否则会拒绝访问相应的编译器。此例中配置允许访问存放在 <code>/usr/local/</code> 目录下gcc的 <code>arm-eabi-4.4.3</code> 交叉编译器，实际配置中需要根据需要做修改。
</p>


{% codeblock commands.allow.sh lang:sh %}
allowed_compilers="
  /usr/bin/cc
  /usr/bin/c++
  /usr/bin/c89
  /usr/bin/c99
  /usr/bin/gcc
  /usr/bin/g++
  /usr/bin/*gcc-*
  /usr/bin/*g++-*
  /usr/local/arm-eabi-4.4.3/bin/*gcc*
  /usr/local/arm-eabi-4.4.3/bin/*g++*
  /usr/local/arm-eabi-4.4.3/bin/*ld*
  /usr/local/arm-eabi-4.4.3/bin/*ar*
  /usr/local/arm-eabi-4.4.3/bin/*as*
"
{% endcodeblock %}

<p>
将 <code>/usr/local/arm-eabi-4.4.3/bin/</code> 加入到访问路径中，修改 <code>~/.bash_profile</code> 文件，添加以下内容：
</p>


{% codeblock lang:sh %}
export PATH=/usr/local/arm-eabi-4.4.3/bin/:$PATH
{% endcodeblock %}

<p>
修改 <code>/etc/init.d/distcc</code> ,在
</p>


{% codeblock lang:sh %}
EXEC="/usr/bin/distccd"
{% endcodeblock %}

<p>
下面添加一行
</p>


{% codeblock lang:sh %}
export PATH=/usr/local/arm-eabi-4.4.0/bin/:$PATH
{% endcodeblock %}

<p>
上述文件都改好保存后，退出到命令行界面，重启distcc服务程序：
{% codeblock lang:sh %}
sudo /etc/init.d/distcc restart
{% endcodeblock %}
好了，这样一台服务器就算配置完成了。将网络上可以提供编译服务的电脑，全部参照如此配置进行设置。这样就拥有一群可以提供分布编译服务的计算机群了。
</p>
</div>

</div>

<div id="outline-container-2-3-2" class="outline-4">
<h4 id="sec-2-3-2">客户端配置</h4>
<div class="outline-text-4" id="text-2-3-2">

<p>相对于服务器端的配置来说，客户端的配置非常简单。只需要修改 <code>/etc/distcc/hosts</code> 文件即可。
修改 <code>/etc/distcc/hosts</code> ，加入配置好的服务器IP即可，一行一个IP地址，如：
</p>


<pre class="example">172.16.149.45
172.16.149.14
172.16.149.60
172.16.149.20
#本机也加入分布编译服务器群组
localhost
</pre>


<p>
然后定义 <code>CROSS_COMPILE</code> 环境变量，以之前配置的 <code>arm-eabi-gcc</code> 交叉编译器为例，如下定义：
{% codeblock lang:sh %}
export CROSS_COMPILE="distcc arm-eabi-"
{% endcodeblock %}
至此，distcc的配置全部完成，可以使用了。
</p>
</div>
</div>

</div>

<div id="outline-container-2-4" class="outline-3">
<h3 id="sec-2-4">验证distcc</h3>
<div class="outline-text-3" id="text-2-4">

<p>在客户端电脑上进入开源代码目录中执行，上执行
{% codeblock lang:sh %}
make clean;make -j4 CC="distcc gcc"
{% endcodeblock %}
然后在同一台客户机的另一终端上执行：
{% codeblock lang:sh %}
watch distccmon-text
{% endcodeblock %}
如果看到类似如下信息，则表明distcc安装配置正常。
</p>


<pre class="example">Every 2.0s: distccmon-text                            Mon Oct 24 15:29:40 2011

  8836  Compile     state.c                                  172.16.149.45[0]
  8808  Connect     climasq.c                                172.16.149.14[2]
  8807  Connect     backoff.c                                172.16.149.60[3]
  8839  Preprocess  strip.c                                  172.16.149.60[0]
</pre>

<p>
如果显示Block之类的信息，请检查对方服务器上的 <code>client.allow</code> 是否正确，同时需要确保服务器上的3632端口没有被防火墙拦住。
</p>
</div>
</div>

</div>

<div id="outline-container-3" class="outline-2">
<h2 id="sec-3">使用distcc进行效率对比</h2>
<div class="outline-text-2" id="text-3">

<p>本例中使用3台单核2.6G的电脑群组做编译实验，分别对单机编译和分布编译时间进行比较。对比中会分别编译emacs23代码和交叉编译Android的linux内核代码。
</p>

</div>

<div id="outline-container-3-1" class="outline-3">
<h3 id="sec-3-1">编译emacs</h3>
<div class="outline-text-3" id="text-3-1">

<p>下载并解压emacs23代码，目录为： <code>~/Downloads/emacs-23.3/</code>
</p>
<p>
首先非分布式编译，使用8个线程。执行
{% codeblock lang:sh %}
cd ~/Downloads/emacs-23.3
./configure
make clean
time make -j8
{% endcodeblock %}
编译完成后结果为：
</p>


<pre class="example">real    3m14.220s
user    2m24.740s
sys     0m48.610s
</pre>

<p>
然后使用分布式编译，同样使用8个线程。执行
{% codeblock lang:sh %}
cd ~/Downloads/emacs-23.3
./configure
make clean
time make -j8 CC="distcc gcc"
{% endcodeblock %}
编译完成后结果为：
</p>


<pre class="example">real    2m24.330s
user    1m38.630s
sys     0m37.600s
</pre>

<p>
可以看到编译时间减少了50秒，cpu的占用也明显减小了不少。
</p>
</div>

</div>

<div id="outline-container-3-2" class="outline-3">
<h3 id="sec-3-2">编译Android的Linux内核</h3>
<div class="outline-text-3" id="text-3-2">

<p>假设Android的Linux内核存目录为： <code>~/Downloads/Android2.3_kernel_v1.01</code>
</p>
<p>
同样首先非分布式编译，使用8个线程。由于之前设置过 <code>CROSS_COMPILE</code> 变量，现在单机编译需要重新设置该变量。
{% codeblock lang:sh %}
export CROSS_COMPILE="arm-eabi-"
cd ~/Downloads/Android2.3_kernel_v1.01
make clean
time make -j8
{% endcodeblock %}
编译完成后结果为：
</p>


<pre class="example">real    6m32.640s
user    4m22.040s
sys     2m9.160s
</pre>

<p>
然后分布式编译，使用8个线程。执行
{% codeblock lang:sh %}
export CROSS_COMPILE="distcc arm-eabi-"
cd ~/Downloads/Android2.3_kernel_v1.01
make clean
time make -j8
{% endcodeblock %}
编译完成后结果为：
</p>


<pre class="example">real    3m42.140s
user    2m10.630s
sys     1m20.240s
</pre>

<p>
可以看到编译时间减少了2分50秒，接近一半的水平了，分布编译的性能提升非常明显。
</p>
<p>
从以上两个实验可以看出，对于使用纯C程序编写的软件项目，如：Linux内核，distcc提供的分布编译效率非常显著。而对于混合有其他程序语言的项目，如Emacs<sup><a class="footref" name="fnr.1" href="#fn.1">1</a></sup>，效率提升就不是那么显著了。
</p>
</div>
</div>

</div>

<div id="outline-container-4" class="outline-2">
<h2 id="sec-4">Android代码的分布式编译</h2>
<div class="outline-text-2" id="text-4">

<p>Android的代码比较特殊，一部分是C程序，而另一部分为JAVA程序。所以分布编译的时候只能对C程序部分生效。同时，Android代码包包含完整的交叉编译工具链，编译时会使用自己代码包中的工具链进行编译，所以我们之前设置的 <code>CROSS_COMPILE</code> 环境变量会失效。好在解决办法也不是没有，做如下修改即可：
</p>
<p>
修改Android代码目录中的 <code>build/core/combo/select.mk</code> 文件
{% codeblock build/core/combo/select.mk lang:makefile %}
# (...省略...)
# Now include the combo for this specific target.
include $(BUILD_COMBOS)/$(combo_target)$(combo_os_arch).mk

#使用distcc修改 BEGIN
ifneq ($(USE_DISTCC),)
  distcc := distcc
  ifneq ($(distcc),$(firstword $($(combo_target)CC)))
    ifeq ($(dir $($(combo_target)CC)),./)
      $(combo_target)CC := $(distcc) $($(combo_target)CC)
    else
      $(combo_target)CC := $(distcc) $(abspath $($(combo_target)CC))
    endif
  endif
  ifneq ($(distcc),$(firstword $($(combo_target)CXX)))
    ifeq ($(dir $($(combo_target)CXX)),./)
      $(combo_target)CXX := $(distcc) $($(combo_target)CXX)
    else
      $(combo_target)CXX := $(distcc) $(abspath $($(combo_target)CXX))
    endif
  endif
  distcc =
endif
#使用distcc修改 END

ifneq ($(USE_CCACHE),)
  CCACHE_HOST_TAG := $(HOST_PREBUILT_TAG)
  # If we are cross-compiling Windows binaries on Linux
# (...省略...)
{% endcodeblock %}

之后，执行
{% codeblock lang:sh %}
. ./build/envsetup.sh

export USE_CCACHE=1
export USE_DISTCC=1

make -j16
{% endcodeblock %}

我这里使用6台XEON四核单机组成的集群做出来的结果是：
</p><table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">
<caption>Android编译结果比较</caption>
<colgroup><col class="left" /><col class="left" /><col class="left" />
</colgroup>
<thead>
<tr><th scope="col" class="left">不开启分布编译</th><th scope="col" class="left">开启分布编译第一次</th><th scope="col" class="left">开启分布编译第二次</th></tr>
</thead>
<tbody>
<tr><td class="left">real    37m49.735s</td><td class="left">real    34m1.854s</td><td class="left">real    31m7.957s</td></tr>
<tr><td class="left">user    107m13.238s</td><td class="left">user    55m57.950s</td><td class="left">user    52m28.229s</td></tr>
<tr><td class="left">sys     9m55.805s</td><td class="left">sys     26m40.228s</td><td class="left">sys     21m22.468s</td></tr>
</tbody>
</table>

可以看出有一定的效率提升，但是非常有限，只有区区8分钟不到的提升。我将其原因归结于以下几个原因：
<ol>
<li>磁盘瓶颈。编译过程中需要读写大量中间文件，磁盘的读写速度限制了编译程序的处理能力；
</li>
<li>编译JAVA时不能分布式。如前面所述，Android代码中有一部分时JAVA代码。而JAVA代码在编译的时候是不能应用到distcc的分布式能力的，所以这方面也拖了编译速度的后腿。
</li>
<li>没有根据服务器的CPU处理能力进行任务分发优化。distcc默认是没有任务分发优化的，需要配合使用dmucs程序才能实现。据说配合了dmucs后，性能还能提升30%~50%。不过如何配置使用dmucs就不是本文的主题了，也希望通过我这抛出的“砖”能引出配置dmucs的“玉”来。
</li>
</ol>


</div>

</div>

<div id="outline-container-5" class="outline-2">
<h2 id="sec-5">总结</h2>
<div class="outline-text-2" id="text-5">

<p>总体来讲，使用distcc这个工具可以大幅提高编译代码的效率。但这个工具只能针对C++、ObjC、C等C系列语言生效；而对于像Android这种有一半代码是JAVA的系统来说，联编优势就不那么显著了。尽管如此，distcc带来的200%的编译效率提升，还是值得使用的。
</p>
<div id="footnotes">
<h2 class="footnotes">Footnotes: </h2>
<div id="text-footnotes">
<p class="footnote"><sup><a class="footnum" name="fn.1" href="#fnr.1">1</a></sup> Emacs源码中包含不少的elisp程序，这些elisp程序也在make编译阶段进行编译，从而成为elc文件。
</p>



</div>
</div>

</div>
</div>
