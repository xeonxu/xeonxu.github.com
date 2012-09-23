---
layout: post
title: "优化使用Orgmode发布Octopress的方法"
date: 2012-09-05 07:59
comments: true
categories: Org-Mode Octopress Emacs
---

<p>
前几天翻译了一篇来自Tom Alexander的<a href="http://blog.xeonxu.info/blog/2012/09/03/shi-yong-org-modelai-fa-bu-bo-ke/">文章</a> ，文中介绍了如何通过修改Rakefile文件以及添加相应的Emacs设置，来使通过Org-mode发布Octopress博客成为可能。该方法很好用，特别是使用作者自己修改的el脚本可以非常方便的将Org文件输出为octopress的文章。但是，原文作者的方法也有一点缺憾，那就是必须手动移动新建的Org文件到相应的目录下；而且在使用 <code>rake new_post[""]</code> 命令新建文档后必须手动编辑新建的文件，少了那么一点点便捷。为此，我又通过网络查找了一些资料，最后找到了<a href="http://imwuyu.me/blog/configuring-octopress.html/">这里</a> 。 受到这篇文章的启发，我尝试修改了工程中的 <code>Rakefile</code> 文件，最后成功地让一切都自动化起来。具体方法如下：
</p>
<ul>
<li>修改Rakefile中关于org文档目录以及新建post文件的扩展名。同时新增一个编辑器的变量
</li>
</ul>


{% codeblock Rakefile  lang:makefile https://github.com/xeonxu/xeonxu.github.com/commit/d0ebcf9c09d2141fa50e4e0fcba7d18720a5f9ad Source %}
 deploy_dir      = "_deploy"   # deploy directory (for Github pages deployment)
 stash_dir       = "_stash"    # directory to stash posts for speedy generation
 posts_dir       = "_posts"    # directory for blog files
 org_posts_dir   = "org_posts"
 themes_dir      = ".themes"   # directory for blog files
 new_post_ext    = "org"  # default new post file extension when using the new_post task
 new_page_ext    = "markdown"  # default new page file extension when using the new_page task
 server_port     = "4000"      # port for preview server eg. localhost:4000

# open ,使用系统默认编辑器
# open -a Mou，使用Mou打开
# open -a Byword，使用Byword打开
# subl, 使用Sublime Text2打开
editor ="~/bin/em" # Emacs wrapper
{% endcodeblock %}
<p>
我使用我自己编写的emacs wrapper来调用Emacs，为的是让Emacs的启动更快一点（通过server方式）。em的内容如下：
{% codeblock em lang:bash %}
#!/bin/bash
/Applications/Emacs.app/Contents/MacOS/bin/emacsclient -n -a "/Applications/Emacs.app/Contents/MacOS/Emacs" $1 > /dev/null 2>&1 &
{% endcodeblock %}
如果你也想通过emacsclient来加速Emacs的启动速度，你可能需要在你的 <code>.emacs</code> 文件中添加以下语句：
{% codeblock .emacs lang:bash %}
(require 'edit-server)
(edit-server-start)
{% endcodeblock %}
当然，你也可以指定 <code>editor</code> 变量为任何你喜欢的编辑器，不过既然都用Org文件发博客了，有什么理由不用Emacs呢？
</p>
<ul>
<li>添加新建 <code>org_posts_dir</code> 目录及相应org文件的语句
</li>
</ul>

<p>在 <code>task :install, :theme do |t, args|</code> 语句之下，添加新建 <code>org_posts_dir</code> 的语句：
</p>


{% codeblock Rakefile  lang:ruby https://github.com/xeonxu/xeonxu.github.com/commit/d0ebcf9c09d2141fa50e4e0fcba7d18720a5f9ad Source %}
  theme = args.theme || 'classic'
  puts "## Copying "+theme+" theme into ./#{source_dir} and ./sass"
  mkdir_p source_dir
  cp_r "#{themes_dir}/#{theme}/source/.", source_dir
  mkdir_p "sass"
  cp_r "#{themes_dir}/#{theme}/sass/.", "sass"
  mkdir_p "#{source_dir}/#{posts_dir}"
  mkdir_p "#{source_dir}/#{org_posts_dir}"
  mkdir_p public_dir
{% endcodeblock %}

<p>
在 <code>task :new_post, :title do |t, args|</code> 语句之下，添加新建文档目录和新建文章的语句：
{% codeblock Rakefile  lang:ruby https://github.com/xeonxu/xeonxu.github.com/commit/d0ebcf9c09d2141fa50e4e0fcba7d18720a5f9ad Source %}
 task :new_post, :title do |t, args|
   raise "### You haven't set anything up yet. First run `rake install` to set up an Octopress theme." unless File.directory?(source_dir)
   mkdir_p "#{source_dir}/#{posts_dir}"
   mkdir_p "#{source_dir}/#{org_posts_dir}"
   args.with_defaults(:title => 'new-post')
   title = args.title
   filename = "#{source_dir}/#{org_posts_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"
   if File.exist?(filename)
     abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
   end
{% endcodeblock %}

</p><ul>
<li>为了在新建文件之后能够立即编辑，我还在 <code>new_post</code> 命令中加入了相应的编辑语句：
</li>
</ul>


{% codeblock Rakefile  lang:ruby https://github.com/xeonxu/xeonxu.github.com/commit/d0ebcf9c09d2141fa50e4e0fcba7d18720a5f9ad Source %}
desc "Begin a new post in #{source_dir}/#{org_posts_dir}"
task :new_post, :title do |t, args|
  raise "### You haven't set anything up yet. First run `rake install` to set up an Octopress theme." unless File.directory?(source_dir)
  mkdir_p "#{source_dir}/#{posts_dir}"
  mkdir_p "#{source_dir}/#{org_posts_dir}"
  args.with_defaults(:title => 'new-post')
  title = args.title
  filename = "#{source_dir}/#{org_posts_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end
  puts "Creating new post: #{filename}"
  open(filename, 'w') do |post|
    post.puts "#+BEGIN_HTML"
    post.puts "---"
    post.puts "layout: post"
    post.puts "title: \"#{title.gsub(/&/,'&amp;')}\""
    post.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M')}"
    post.puts "comments: true"
    post.puts "categories: "
    post.puts "---"
    post.puts "#+END_HTML"
  end
  if #{editor}
    system "sleep 1; #{editor} #{filename}"
  end
end
{% endcodeblock %}
<p>
在 <code>new_page</code> 中也添加相同的语句，不过注意，最后 <code>editor</code> 那一段中文件名称变量需要使用 <code>#{file}</code> ，如下：
{% codeblock Rakefile lang:ruby %}
  if #{editor}
    system "sleep 1; #{editor} #{file}"
  end
{% endcodeblock %}

</p><ul>
<li>最后，为了预览更加方便，在 <code>preview</code> 命令最后添加下面的语句：
</li>
</ul>


{% codeblock Rakefile  lang:ruby https://github.com/xeonxu/xeonxu.github.com/commit/d0ebcf9c09d2141fa50e4e0fcba7d18720a5f9ad Source %}
   system "sleep 2; open http://localhost:#{server_port}/"
   [jekyllPid, compassPid, rackupPid].each { |pid| Process.wait(pid) }
{% endcodeblock %}

<p>
好了，现在我们只需要在控制台上执行 <code>rake new_post["something"]</code> 就会自动在我们设定的 <code>org_posts_dir</code> 目录下新建一份org文档，并且使用我们指定的编辑器打开它。然后随便编辑一点什么，保存并执行 <code>C-c C-e F</code> 或者直接调用Tom Alexander文章中所说的 <code>M-x save-then-publish</code> 命令。最后再在控制台上执行 <code>rake generate&amp;&amp;rake preview</code> 。 Booooom，自动弹出的浏览器上是不是显示出了你刚才编写的文章？非常方便吧？赶快试试！
</p>