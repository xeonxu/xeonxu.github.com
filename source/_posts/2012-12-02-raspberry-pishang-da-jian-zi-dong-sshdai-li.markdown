---
layout: post
title: "Raspberry Pi上搭建自动ssh代理"
date: 2012-12-02 00:00
comments: true
categories: RaspberryPi 功夫网
---

<p>
这是一篇 <span style="text-decoration:underline;">功夫网</span> 系列文章，本篇作为该系列文章的第一篇，一直拖了好久才真正开始动笔。这篇文章中，我将要介绍的是如何在Raspberry Pi上搭建基于SSH连接的Socks代理服务器。关于我为什么使用Raspberry Pi，是因为我觉得这玩意小巧，携带方便，而且买了它不用也是闲着。至于为什么搭建Socks服务器，知者自知，不知者我也不想过多解释。总之这是该系列文章第一篇，所以内容上相对来说都是比较简单和基础的，大家往下看就是了。另外需要说明的是，我所使用的Raspberry Pi是B型板，操作系统为Arm版的Slackware系统ArmedSlack。如果使用的是其它发行版，可能需要相应修改以下的命令。
</p>
<p>
本片文章主要实现三个目的：
</p><ol>
<li>实现ssh免密码自动连接远程服务器，并建立Socks代理
</li>
<li>开机时自动通过ssh与远程服务器建立安全通道
</li>
<li>设置守护进程，使得ssh连接异常断开后可以自动进行重新连接
</li>
</ol>


<p>
操作之前，首先使用终端软件通过ssh方式连接到Raspberry Pi上。
</p>
<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1 ssh免密码自动连接远程服务器</a>
<ul>
<li><a href="#sec-1-1">1.1 生成密钥</a></li>
<li><a href="#sec-1-2">1.2 上传密钥</a></li>
<li><a href="#sec-1-3">1.3 建立socks服务</a></li>
</ul>
</li>
<li><a href="#sec-2">2 开机时自动建立连接</a></li>
<li><a href="#sec-3">3 设置守护进程防止断线</a>
<ul>
<li><a href="#sec-3-1">3.1 安装autossh</a></li>
<li><a href="#sec-3-2">3.2 初始化脚本</a></li>
<li><a href="#sec-3-3">3.3 守护进程</a></li>
</ul>
</li>
</ul>
</div>
</div>

<div id="outline-container-1" class="outline-2">
<h2 id="sec-1">ssh免密码自动连接远程服务器</h2>
<div class="outline-text-2" id="text-1">

<p>为了ssh可以在无人干预的情况下自动连接远程服务器，普遍的做法是使用公钥认证方式进行连接。同样，我们也使用公钥认证的方法进行自动连接。为了实现公钥认证连接，首先需要生成密钥对。
</p>
</div>

<div id="outline-container-1-1" class="outline-3">
<h3 id="sec-1-1">生成密钥</h3>
<div class="outline-text-3" id="text-1-1">

<p>生成密钥时可以使用以下 <code>ssh-keygen</code> 命令进行。
{% codeblock lang:bash %}
ssh-keygen -t rsa
{% endcodeblock %}
命令执行中会出现一些提示，大致是一些关于密钥存放路径以及密钥主密码设定之类的。基本上一路回车就可以了，同时注意不要去设置密钥主密码，否则每次访问密钥时都会提示输入，这样就达不到自动认证连接的目的了。由于 <code>ssh-keygen</code> 包含在openssh软件包中，所以如果linux中曾经安装过openssh的话，应该直接就能使用。反之如果提示找不到该命令，可以通过类似下面的命令来安装slackware的n包中的openssh来获取。
{% codeblock lang:bash %}
installpkg /slackware/n/openssh-6.0p1-arm-1.tgz
{% endcodeblock %}
生成好的密钥对默认会保存在 <code>~/.ssh/</code> 目录下，如果生成的时rsa密钥，则密钥文件分别为 <code>id_rsa</code> 和 <code>id_rsa.pub</code> 。其中没有 <code>.pub</code> 扩展名的文件为私钥，另外一个为公钥。现在我们需要将我们刚才生成的公钥文件上传到我们的远程服务器的相应目录中。
</p>
</div>

</div>

<div id="outline-container-1-2" class="outline-3">
<h3 id="sec-1-2">上传密钥</h3>
<div class="outline-text-3" id="text-1-2">

<p>上传密钥可以使用通用的scp命令，也可以使用ssh工具中的 <code>ssh-copy-id</code> 命令。 <code>ssh-copy-id</code> 命令比较简单，指定密钥文件和远程机即可，该命令会自动添加公钥内容到远程机的授权文件中。但要注意该命令不会改变远程机相应文件的属性，所以如果是第一次操作的话，建议使用scp命令比较靠谱。下面我们使用scp命令
{% codeblock lang:bash %}
scp ~/.ssh/id_rsa.pub user@server:/home/user #user和server需要根据实际内容更改，可能需要输入远程机密码
ssh user@server #连接至远程服务器，可能需要输入远程机密码。user和server需要根据实际内容更改
cd
cat id_rsa.pub >> .ssh/authorized_keys #将刚拷贝过来的公钥文件内容添加到.ssh/authorized_keys文件中
chmod 600 .ssh/authorized_keys #必须确保.ssh/authorized_keys文件的属性为600，及他人不可读写，否则公钥认证将会失败
{% endcodeblock %}
OK，大功告成。退出远程机，使用 <code>ssh user@server</code> 命令重新连接远程机，此时会提示加密指纹认证的提示，回答 <code>yes</code> 即可。此后再次连接远程机时就会直接登录进入，而不会出现任何提示了。
</p>
</div>

</div>

<div id="outline-container-1-3" class="outline-3">
<h3 id="sec-1-3">建立socks服务</h3>
<div class="outline-text-3" id="text-1-3">

<p>ssh软件自带功能可以生成socks代理服务器，并通过ssh连接的远程机进行网络访问。使用相当简单，只需要在执行ssh命令连接远程机时使用 <code>-D</code> 参数指定相应端口即可，如
{% codeblock lang:bash %}
ssh -D 9090 user@server
{% endcodeblock %}
以上例子将ssh连接生成端口号为9090的socks代理。该代理可以通过Firefox等浏览器直接使用，每次需要使用socks代理时只需执行以上的命令即可。但是现实情况是，我们希望RaspberryPi在每次开机后即可自动运行ssh连接远程机并建立相应的代理端口。
</p>
</div>
</div>

</div>

<div id="outline-container-2" class="outline-2">
<h2 id="sec-2">开机时自动建立连接</h2>
<div class="outline-text-2" id="text-2">

<p>开机后立即进行ssh连接有很多实现方法，最省事的办法就是修改 <code>rc.local</code> 或者 <code>inittab</code> 文件来实现。方法非常简单，添加相应语句到 <code>rc.local</code> 中即可。以下，我通过新建一个连接脚本，然后在 <code>rc.local</code> 文件中进行调用来实现开机自动连接ssh：
{% codeblock lang:bash %}
mkdir -p ~/bin
echo ssh -D 9090 user@server >> ~/bin/socks_proxy.sh
chmod a+x ~/bin/socks_proxy.sh
echo ~/bin/socks_proxy.sh >> /etc/rc.d/rc.local
{% endcodeblock %}
如果想做的更正式一点，可以参考 <code>/etc/rc.d/</code> 目录下的脚本文件，新建一个rc风格的服务脚本文件，然后修改 <code>rc.M</code> 文件，添加相应的服务启动代码即可。不过接下来马上要做防止断线的处理，需要用到其它工具，所以这一步暂时跳过也没关系。
</p>
</div>

</div>

<div id="outline-container-3" class="outline-2">
<h2 id="sec-3">设置守护进程防止断线</h2>
<div class="outline-text-2" id="text-3">

<p>目前为止我们设置了ssh的免密码登录以及开机自动登录，要求不高的话也差不多可以凑合使用。但是网络这东西有很多不稳定因素，如果碰到ssh服务器出状况或者线路不稳定时，ssh的连接就可能会被中断，这时必须自己手动再连接一次才能继续使用，这显然不是我们希望的。为了防止这类情况的发生，我们需要借助autossh软件来实现断线自动连接。autossh的功能就像它的名称一样直接简单，它可以监测ssh的连接状态，并在有需要的时候自动重新连接ssh。接下来，我来讲解如何安装配置autossh。
</p>
</div>

<div id="outline-container-3-1" class="outline-3">
<h3 id="sec-3-1">安装autossh</h3>
<div class="outline-text-3" id="text-3-1">

<p>由于slackware官方没有提供autossh的安装包，所以需要自己从源码编译。首先从autossh<a href="http://www.harding.motd.ca/autossh/">官网</a> 下载最新的源代码包 <code>autossh-1.4c.tgz</code> ，然后执行以下命令进行编译安装：
{% codeblock lang:bash %}
gunzip -c autossh-1.4c.tgz | tar xvf -
cd autossh-1.4c
./configure --prefix=/usr --sysconfdir=/etc
make
sudo make install
{% endcodeblock %}
整个过程没有什么难度，标准的从源代码安装软件的方法，除了RPi的编译速度有点慢以外。为了方便，我这里也用slackbuild编译了一份适用于RPi使用的二进制软件包： <a href="./downloads/autossh-1.4c-arm-1_SBo.tgz">autossh-1.4c-arm.tgz</a> ,只需要执行 <code>sudo installpkg autossh-1.4c-arm-1_SBo.tgz</code> 即可。
</p></div>

</div>

<div id="outline-container-3-2" class="outline-3">
<h3 id="sec-3-2">初始化脚本</h3>
<div class="outline-text-3" id="text-3-2">

<p>autossh安装好后不需要特别的设置，只需要使用它改写之前的ssh连接脚本即可。修改 <code>~/bin/socks_proxy.sh</code> 如下：
{% codeblock lang:bash %}
#!/bin/bash
#
# autossh:  Connect remote with ssh automatically.
#
# processname: autossh
# pidfile: /var/run/autossh.pid
#                       --Zhiqiang Xu <xeonxu@gmail.com>


export AUTOSSH_PIDFILE="/var/run/autossh.pid"
PIDFILE=$AUTOSSH_PIDFILE
SSH_SERVER=user@server

if [ -e $AUTOSSH_PIDFILE ]; then
        exit 0
elif [ -x /usr/bin/autossh -a -x /usr/bin/ssh ]; then
        echo "Starting autossh..."
        autossh -M 40000 $SSH_SERVER -f -q -C -g -N -D 9090
fi
{% endcodeblock %}
如果之前还没有修改过 <code>/etc/rc.d/rc.local</code> 文件，记得在该文件最后加上一句 <code>~/bin/socks_proxy.sh</code> 。如此便可在每次开机后自动使用autossh来进行ssh连接，同时再也不用担心该ssh会发生断线问题了。
</p>
</div>

</div>

<div id="outline-container-3-3" class="outline-3">
<h3 id="sec-3-3">守护进程</h3>
<div class="outline-text-3" id="text-3-3">

<p>说实在，通过之前的那些操作基本可以保证我们拥有一个可以自动监护连接，并能稳定提供socks代理的功能了。以下操作可以不必进行，不过如果你纠结于更稳定的保全的连接，可以继续看下去。这一步操作主要是将autossh加入守护进程，从而防止autossh的异常退出（还记得autossh是干什么的来着？如果autossh异常退出会发生什么事？Yes, 这就是我们要防止的）。
</p>
<p>
将autossh脚本以守护进程方式运行的方法很多，最简单的就是修改 <code>inittab</code> 文件。如果之前修改过 <code>/etc/rc.local</code> 文件，记得将其中关于运行autossh的语句删掉或者注释掉，否则和守护进程的设置会重复。
打开 <code>inittab</code> 文件，参考其它项目的写法添加一行就搞定，如下：
{% codeblock lang:bash %}
AUTOSSH:12345:respawn:sh /home/user/bin/socks_proxy.sh
{% endcodeblock %}
另外，使用守护进程方式运行autossh时要注意一点，运行的脚本必须不是daemon方式的。所以还需要将前面的连接语句：
{% codeblock lang:bash %}
autossh -M 40000 $SSH_SERVER -f -q -C -g -N -D 9090
{% endcodeblock %}
修改为：
{% codeblock lang:bash %}
autossh -M 40000 $SSH_SERVER -q -C -g -N -D 9090
{% endcodeblock %}
也即是去掉其中的 <code>-f</code> 选项，否则，init会不断尝试重新运行autossh命令，导致服务不稳定。
</p>
<p>
守护进程还可以通过第三方工具来配置，比如daemontools，monit等等之类，功能相对来说更强大一点，但是所提供的基本功能都是一样的，所以这里也就不再详细介绍了，有兴趣的自己看文档编译配置一份就能用。
</p>
<p>
这个就是我配了壳后的Raspberry Pi， 运行起来还是很稳定的:
</p>

<div class="figure">
<p><img src="/./images/blog/RPi_shell.jpg"  alt="./images/blog/RPi_shell.jpg" /></p>
<p>配了壳的RPi</p>
</div>
</div>
</div>
</div>
