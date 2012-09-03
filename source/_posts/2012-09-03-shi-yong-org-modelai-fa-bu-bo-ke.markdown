---
layout: post
title: "使用Org-Mode来发布博客"
date: 2012-09-03 20:58
comments: true
categories: Octopress Org-Mode Emacs 翻译
---

<p>
原文地址： <a href="http://blog.paphus.com/blog/2012/08/01/introducing-octopress-blogging-for-org-mode/">http://blog.paphus.com/blog/2012/08/01/introducing-octopress-blogging-for-org-mode/</a>
</p>
<p>
在之前的一篇<a href="http://blog.paphus.com/blog/2012/07/21/octopress-and-org-mode/"> 文章 </a>中曾介绍过一种从 <a href="http://www.gnu.org/software/emacs/">Emacs</a> 的 <a href="http://orgmode.org/">Org-Mode</a> 中导出文章到Octopress的方法，但这种方法使用简单的HTML导出，会失去语法高亮的特性。为此我将方法重新进行了设计，并且得到了一种更好的方法来取代之前不靠谱的方法。
</p>
<p>
首先，你需要根据  <a href="http://octopress.org/">Octopress</a> 的官方说明进行设置。我在Clone好Octopress的代码库后，进入克隆产生的目录并执行以下命令：
{% codeblock lang:sh %}
  #!/bin/sh
  #
  curl -L https://get.rvm.io | bash -s stable --ruby
  source ~/.rvm/scripts/rvm
  rvm install 1.9.2
  rvm rubygems latest
  gem install bundler
  bundle install
  rake install
{% endcodeblock %}

像之前介绍的那样，我们需要在 <code>.emacs</code> 中新增一个叫 <code>save-then-publish</code> 的命令。
{% codeblock Save Then Publish  lang:scheme http://doc.norang.ca/org-mode.html source %}
  (defun save-then-publish ()
    (interactive)
    (save-buffer)
    (org-save-all-org-buffers)
    (org-publish-current-project))
{% endcodeblock %}

接下来，我们需要设置Org-mode的工程。以我的配置举例来说，我将Octopress的文章放置在 <code>~/git/blog/</code> 目录下。如果你需要将你的文章放在其它什么地方，记得修改下面配置中相应的路径。
{% codeblock Publish Projects  lang:scheme http://jaderholm.com/blog/blogging-with-org-mode-and-octopress source %}
  (setq org-publish-project-alist
        '(("blog-org" .  (:base-directory "~/git/blog/source/org_posts/"
                                          :base-extension "org"
                                          :publishing-directory "~/git/blog/source/_posts/"
                                          :sub-superscript ""
                                          :recursive t
                                          :publishing-function org-publish-org-to-octopress
                                          :headline-levels 4
                                          :html-extension "markdown"
                                          :octopress-extension "markdown"
                                          :body-only t))
          ("blog-extra" . (:base-directory "~/git/blog/source/org_posts/"
                                           :publishing-directory "~/git/blog/source/"
                                           :base-extension "css\\|pdf\\|png\\|jpg\\|gif\\|svg"
                                           :publishing-function org-publish-attachment
                                           :recursive t
                                           :author nil
                                           ))
          ("blog" . (:components ("blog-org" "blog-extra")))
          ))
{% endcodeblock %}

现在，我们开始修改代码目录中的 <code>Rakefile</code> 文件。打开它找到 <b>Misc Configs</b> 设置部分，参照下面例子分别修改 <code>new_post_ext</code> 和 <code>new_page_ext</code> 的内容并添加 <code>org_posts_dir</code> 项:
{% codeblock Rakefile  lang:text https://gist.github.com/1244494 source %}
  ## -- Misc Configs -- ##

  public_dir      = "public"    # compiled site directory
  source_dir      = "source"    # source file directory
  blog_index_dir  = 'source'    # directory for your blog's index page (if you put your index in source/blog/index.html, set this to 'source/blog')
  deploy_dir      = "_deploy"   # deploy directory (for Github pages deployment)
  stash_dir       = "_stash"    # directory to stash posts for speedy generation
  posts_dir       = "_posts"    # directory for blog files
  org_posts_dir   = "org_posts"
  themes_dir      = ".themes"   # directory for blog files
  new_post_ext    = "org"  # default new post file extension when using the new_post task
  new_page_ext    = "org"  # default new page file extension when using the new_page task
  server_port     = "4000"      # port for preview server eg. localhost:4000
{% endcodeblock %}

接着修改 <code>Rakefile</code> ，找到下面代码所示的部分并添加 <code>BEGIN_HTML</code> 和 <code>END_HTML</code> 。这样，我们新建文章的时候就能自动生成相应的HTML标签了。
{% codeblock Rakefile  lang:text https://gist.github.com/1244494 source %}
      post.puts "#+BEGIN_HTML"
      post.puts "---"
      post.puts "layout: post"
      post.puts "title: \"#{title.gsub(/&/,'&amp;')}\""
      post.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M')}"
      post.puts "comments: true"
      post.puts "categories: "
      post.puts "---"
      post.puts "#+END_HTML"
{% endcodeblock %}

现在，我们可以使用我修改后的HTML导出插件来生成新的文章了。我修改后的导出插件放置在github上，地址在 <a href="https://github.com/craftkiller/orgmode-octopress">https://github.com/craftkiller/orgmode-octopress</a> 。你也可以直接通过 <a href="https://raw.github.com/craftkiller/orgmode-octopress/master/org-octopress.el">org-octopress.el</a> 来下载。将下载的文件存放在你emacs的load-path中，并通过 <code>(require 'org-octopress)</code> 命令来加载。因为我的git代码都存放在 ＝~/git/＝ 目录下，所以我的Emacs配置是这样的：
{% codeblock .emacs lang:scheme %}
  (add-to-list 'load-path "~/git/orgmode-octopress")
  (require 'org-octopress)
{% endcodeblock %}

终于可以写作了！但是写作之前，你必须像下面示例那样先新增一个org文件并将它移动到org_posts目录下：
{% codeblock lang:sh %}
  cd blog
  rake "new_post[title]"
  mv source/_posts/2012-08-01-title.org source/org_posts/
  # I keep my posts in GIT so then I add it to the repo
  git add source/org_posts/2012-08-01-title.org
{% endcodeblock %}

写完文章后，在Emacs中执行 <code>M-x save-then-publish</code> ，然后你可以到shell中执行 <code>rake gen_deploy</code>. 这样，你的文章就成功的发布到网上了。
</p>
<p>
我这次改进主要新增了代码模块的语法高亮特性，不过目前它只能支持小写的 <code>begin_src</code> <code>end_src</code> 代码块。 另外，它也支持 <code>:title</code> <code>:url</code> 和 <code>:urltext</code> 选项。如果你想了解他们的用法，可以看看这篇博文的源代码:<a href="http://blog.paphus.com/org\_posts/2012-08-01-introducing-octopress-blogging-for-org-mode.org">http://blog.paphus.com/org_posts/2012-08-01-introducing-octopress-blogging-for-org-mode.org</a> 。如果有谁希望帮助改进这个HTML导出插件的话，欢迎在github加入。
</p>
<p>
最后，你也许需要修改你的 <code>.htaccess</code> 文件来重定向图像请求。我重定向了所有SVG文件的请求到根目录上，这样静态链接就不会在访问图像的时候报错了。你需要将 <code>.htaccess</code> 文件放置在 <code>source</code> 目录下。
{% codeblock .htaccess lang:text %}
  Options +FollowSymlinks
  RewriteEngine on
  RewriteBase /
  RewriteRule /([^/]+)\.(svg)$ /$1.$2 [R,L]
{% endcodeblock %}
</p>