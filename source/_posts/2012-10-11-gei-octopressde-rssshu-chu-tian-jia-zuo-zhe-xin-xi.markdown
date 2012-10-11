---
layout: post
title: "给Octopress的RSS输出中添加文章作者信息"
date: 2012-10-11 23:30
comments: true
categories: Octopress
---

<p>
Octopress自带的RSS模版中没有包含文章作者信息，而是只包含了网站作者信息。考虑到博客经常只是一个人写作，同时文章作者随RSS显示，更常用一些，所以我对默认的RSS模版做了一点改动，让它支持了文章作者信息的输出。其实改动相当简单，默认情况下就一个 <code>atom.xml</code> 文件，该文件位于 <code>source/</code> 目录下。改动如下：
{% include_code atom.xml输出作者信息 atom_author.diff %}
其实很简单，就是将全局的作者设定移到文章条目的设定中，这样设置的作者信息就成为了文章的属性。
对于曾经给Octopress添加过RSS2.0支持的站点<sup><a class="footref" name="fnr.1" href="#fn.1">1</a></sup>，还需要相应修改一下 <code>source/</code> 目录下 <code>rss.xml</code> 文件：
{% include_code rss.xml输出作者信息 rss_author.diff %}

同样，只需在文章描述段中加入作者信息的属性即可。修改好文件保存之后，再次运行 <code>rake generate</code> 就会发现rss文件已经正确更新了。
</p>
<p>
另外，有人还想在RSS输出的文章中加入相应版权声明，但又不想将版权声明嵌到文章里（比如像我这样）。办法也是有的，其实还是修改RSS模版文件。
首先在 <code>source/_includes/post/</code> 目录中添加一个叫 <code>copyright.html</code> 新文件，内容如下，也可以是自己自定的一些版权内容：
{% include_code 版权声明文件 copyright.diff %}

我的版权声明模版中加入了CC许可，文章原始链接，作者名称以及个人站点信息。然后分别修改 <code>atom.xml</code> 和 <code>rss.xml</code> 文件如下：
{% include_code atom.xml添加版权声明 atom_copyright.diff %}
就添加一句 <code>include post/copyright.html</code> ，不过要注意是在CDATA段中。 <code>rss.xml</code> 一样处理：
{% include_code rss.xml添加版权声明 rss_copyright.diff %}
轻松搞定，效果就是我博客现在的效果。
</p>
<div id="footnotes">
<h2 class="footnotes">Footnotes: </h2>
<div id="text-footnotes">
<p class="footnote"><sup><a class="footnum" name="fn.1" href="#fnr.1">1</a></sup> <a href="http://log4d.com/2012/05/support-rss/">http://log4d.com/2012/05/support-rss/</a>
</p>



</div>
</div>
