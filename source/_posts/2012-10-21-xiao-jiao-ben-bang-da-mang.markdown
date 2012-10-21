---
layout: post
title: "小脚本帮大忙"
date: 2012-10-21 23:38
comments: true
categories: Linux Android 开发 杂谈
---

<p>
前两天单位的在做项目中发现一个Bug：手机在启动后触摸屏有一定几率无法使用。这个Bug非常恼人，因为重现几率非常低，而且只会出现在重启过程中。这意味着不论是调查原因还是验证对策，都将是非常耗时且繁琐的。因为对策问题之前，首先需要重现问题，如此才好分析问题的原因。而这个Bug必须要反复重启手机才能重现，人为操作的话太浪费时间效率低下。
好在这个Bug的行为比较稳定，重现后触屏肯定不能使用。通过adb对比调查正常手机和问题手机的设备节点，发现在出问题的手机中，触屏设备没有注册成功。看来是设备注册失败，导致的触屏异常。于是，我们考虑使用脚本对该Bug进行再现分析。思路如下：
</p><ol>
<li>写一个脚本判断触屏驱动的设备节点是否注册成功，如果成功则复位重启；否则保留现场等待分析。
</li>
<li>将该脚本添加到 <code>init.rc</code> 中成为一个服务，在启动时调用。
</li>
<li>脚本运行时将相应的运行信息输出到外部文件中，从而可以计算出再现率。
</li>
</ol>

<p>基于以上想法，写出了以下脚本代码：
{% codeblock check_tp.sh lang:bash %}
#!/system/bin/sh
tp_name="xxxx" # xxxx为注册的tp名称
input_name=`cat /sys/class/input/input0/name`
if [ "x_$tp_name" = "x_$input_name" ]; then
    echo "`date` touch screen is OK." >> /data/check_tp.log
    reboot
else
    echo "`date` touch screen is not OK." >> /data/check_tp.log
fi
{% endcodeblock %}
同时，修改 <code>init.rc</code> 文件，在其中加入：
{% codeblock lang:bash %}
service check_tp /system/bin/sh /system/bin/check_tp.sh
    class main
    oneshot
{% endcodeblock %}
然后重新编译bootimage并刷机。最后使用 <code>adb remount&amp;&amp;adb push check_tp.sh /system/bin/&amp;&amp;adb shell chmod 755 /system/bin/check_tp.sh</code> ，将刚才新写的脚本推送到手机上。重启手机，之后就会看到手机不断的上电然后复位重启。
在运行该脚本不断重启手机8小时之后，手机正常进入了系统。此时操作手机进行验证，发现触屏已经无效。分析 <code>/data/check_tp.log</code> 文件，算出手机共重启了1000多次，从而得出该问题的再现率大概为千分之一。利用该脚本，验证bug方便了好多，大大提高了工作效率。
</p>

<div id="outline-container-1" class="outline-2">
<h2 id="sec-1">后记</h2>
<div class="outline-text-2" id="text-1">

<p>由于以上写的脚本使用到了 <code>if</code> 关键字，而Android系统默认不支持该关键字，必须依赖busybox环境才行。之前我有移植过busybox，但是只在工程模式下生效，所以该脚本在release版本中是不能正常运行的。为了不依赖运行环境，我又将该脚本换了一种写法，改为：
{% codeblock check_tp2.sh lang:bash %}
#!/system/bin/sh
tp_name="xxxx" # xxxx为注册的tp名称
input_name=`cat /sys/class/input/input0/name`
case $input_name in
    $tp_name) echo "`date` touch screen is OK." >> /data/check_tp.log
              reboot
             ;;
    *) echo "`date` touch screen is not OK." >> /data/check_tp.log
            ;;
esac
{% endcodeblock %}
这样，即便是在Android原生环境中，也可以正确无误的运行。这样就能将该脚本发给测试，利用它对release版本进行bug验证了。
</p></div>
</div>
