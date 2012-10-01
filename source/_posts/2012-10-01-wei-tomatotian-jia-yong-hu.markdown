---
layout: post
title: "为Tomato添加用户"
date: 2012-10-01 21:21
comments: true
categories: Linux Tomato RaspberryPi
---

<p>
手上的RT-N16跑Tomato系统已经两年有余了，两年来Tomato系统没有让我失望过，一直提供着稳定高速的网络服务，此外它还提供了内网文件服务，P2P下载以及科学上网代理等重要功能。最近，本人又败了一个小玩意：<a href="http://www.raspberrypi.org">Raspberry Pi</a> ， 税前价格$25，到手¥310。入手后，我在上面安装了ArmedSlack，运行的非常稳定，很不错。于是，本人决定将其打造为一个随身的功能强大的小电脑，包括随插随用的科学上网代理。基本思路是Raspberry Pi启动后通过公钥认证自动连接到家中的RT-N16路由器上，然后通过ssh转发相应端口，即可实现科学上网。不过，这个方法中有一个隐患：因为Tomato默认只提供root/admin账户，权限太大，如果Raspberry Pi使用这个账户进行连接，总是有点不放心。于是，我决定给Tomato系统添加新的用户。
</p>
<p>
Tomato默认并不支持添加账户，即便通过optware安装了adduser后也由于没有passwd命令而失败。不过通过网络搜索，还是让我找到了一个可以添加用户的方法<sup><a class="footref" name="fnr.1" href="#fn.1">1</a></sup>。我用如下的命令在Tomato中建立了一个名为sshuser的用户：
{% codeblock 添加用户 lang:bash %}
UNAM=sshuser
RNAM="For Login Only"
UNUM=200
UGRP=$UNUM
#UGRP=0
echo "$UNAM:x:$UNUM:$UGRP:$RNAM:/tmp:/bin/sh" >> /etc/passwd
echo "$UNAM:x:$UNUM:$UGRP:$RNAM:/home/$UNAM:/bin/sh" >> /etc/passwd.custom
[[ $UGRP -ne 0 ]] && echo "$UNAM:x:$UGRP:" >>/etc/group
[[ $UGRP -ne 0 ]] && echo "$UNAM:x:$UGRP:" >>/etc/group.custom
sed -n -e "s,^root:,$UNAM:,p" < /etc/shadow >> /etc/shadow.custom

chmod 777 /tmp/home
ssh $UNAM@localhost "mkdir /home/$UNAM;touch /home/$UNAM/.profile && echo success"
# press return for the password prompt, you should see the word "success" reported

chmod 755 /tmp/home

nvram setfile2nvram /etc/passwd.custom
nvram setfile2nvram /etc/group.custom
nvram setfile2nvram /etc/shadow.custom
nvram setfile2nvram /home/$UNAM/.profile
nvram commit
{% endcodeblock %}
最后几句包含nvram的语句是将新建的几个 <code>.custom</code> 文件添加到nvram中，这样这些新添加的文件就可以在重启路由器后还能存在。然后，将以下三句添加到路由器设置中-&gt;脚本设置-&gt;初始化中：
{% codeblock 初始化用户 lang:bash %}
sed -i "/^sshuser:/d" /etc/passwd
grep "^sshuser:" < /etc/shadow.custom >> /etc/shadow
grep "^sshuser:" < /etc/passwd.custom >> /etc/passwd
{% endcodeblock %}
如图：
<img src="/./images/blog/./574rHz.png"  alt="./images/blog/./574rHz.png" />
新建的用户使用和root一样的密码，如果需要修改，需要相应修改 <code>/etc/shadow</code> 文件。新建用户登录后的效果入下图：
<img src="/./images/blog/./574dRC.png"  alt="./images/blog/./574dRC.png" />
</p>
<div id="footnotes">
<h2 class="footnotes">Footnotes: </h2>
<div id="text-footnotes">
<p class="footnote"><sup><a class="footnum" name="fn.1" href="#fnr.1">1</a></sup> <a href="http://tomatousb.org/tut:adding-your-own-users">http://tomatousb.org/tut:adding-your-own-users</a>
</p>




</div>
</div>
