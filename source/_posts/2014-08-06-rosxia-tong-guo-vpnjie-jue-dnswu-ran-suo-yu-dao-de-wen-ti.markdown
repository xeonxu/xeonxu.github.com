---
layout: post
title: "简单总结ROS下通过VPN解决DNS污染时所遇到的问题"
date: 2014-08-06 22:30
comments: true
published: true
categories: 功夫网 杂谈
---
之前参照[ROS透明经济翻墙][1]在家中搭建了无痛网络，但是期间在解决DNS污染问题上纠缠了一阵，现简单总结一下所遇到的问题。原因有几个方面：

1. 在配置ROS路由器时，本地流量不受标记影响，所以路由器本地是不走vpn的。而电脑DNS之前指定的是ROS自带的DNS，所以虽然在ROS上指定了上级DNS为Google DNS，但由于ROS本地没走vpn，所以域名仍然会被污染。
2. 后来在另外一台路由器上使用了dnsmasq，但是由于沿用了之前配置，所以忘了将114DNS从主查询DNS中删除，更关键在于，污染的域名没有强制使用Google DNS进行解析，所以，虽然添加了Google DNS作为上级查询，但是114DNS的反馈要快好多，所以使用中还是会遇到污染。
3. 接下来，尝试使用了openDNS的非标端口，解决污染有效，但是openDNS不够稳定，所以继续探索。
4. 最后，经过多次尝试后才发现是第一步中所遇到的污染问题是由于ROS本地流量标记的问题。于是还是决定使用dnsmasq来解决，最后在配置文件中将被污染的域名设置为强制走Google DNS，这样在ROS自动路由的情况下，Google DNS走vpn，被污染的域名就可以从Google DNS获得干净的ip地址了。这样就解决了污染问题。不过这个解决方案仍然需要人为维护，至少需要维护dnsmasq配置文件中被污染的域名列表。

最近，看到shadowsocks的作者[@clowwindy][2]又搞出了个[china-DNS][3]的玩意，看上去非常不错，可以很傻瓜免维护的解决DNS，准备有时间再搞一搞。


[1]:http://bbs.router.com.cn/thread-45681-1-1.html
[2]:https://twitter.com/clowwindy
[3]:https://github.com/clowwindy/ChinaDNS-C