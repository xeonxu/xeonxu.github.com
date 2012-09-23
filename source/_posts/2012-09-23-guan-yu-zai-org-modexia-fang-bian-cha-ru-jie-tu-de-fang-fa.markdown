---
layout: post
title: "关于在Org-Mode下方便插入截图的方法"
date: 2012-09-23 23:58
comments: true
categories: Emacs Org-Mode Octopress
---

<p>
本来使用 <code>Org-Mode</code> 来写博客就很舒服了， 插入图片也很容易，使用
</p>


<pre class="example">[[图片地址]]
</pre>

<p>
的方法就可以。但是对于编写需要插入截图的文档来说，就得先截图，然后保存图片到相应位置，之后才能使用上面的方法来插入图片。
</p>
<p>
有幸，前面搜索资料时发现了一篇文章<sup><a class="footref" name="fnr.1" href="#fn.1">1</a></sup>，其中介绍了一种更加自动化的方式在 <code>Org-Mode</code> 中插入截图。试用后觉得非常方便，不过我又做了一些改动，以适应Mac OSX。同时为使用Octopress，重新设置了图片目录，如下：
{% codeblock my-screenshot lang:scheme %}
(defun my-screenshot ()
  "Take a screenshot into a unique-named file in the current buffer file
directory and insert a link to this file."
  (interactive)
  (setq filename
        (concat (make-temp-name "./") ".png"))
  (setq fullfilename
                 (concat (file-name-directory (buffer-file-name)) "images/blog/" filename))
  (if (file-accessible-directory-p (concat (file-name-directory
                                            (buffer-file-name)) "images/blog/"))
      nil
    (make-directory "images/blog/" t))
  (call-process-shell-command "screencapture" nil nil nil nil "-i" (concat
                                                            "\"" fullfilename "\"" ))
  (insert (concat "[[./images/blog/" filename "]]"))
  (org-display-inline-images)
)
{% endcodeblock %}

另外，还需要给 <code>org-octopress.el</code> 打个补丁，否则发布文档中图片的索引会有问题，造成某些页面下无法显示：
{% codeblock org-octopress.el补丁 lang:diff %}
diff --git a/org-octopress.el b/org-octopress.el
index 7f87742..36eed86 100644
--- a/org-octopress.el
+++ b/org-octopress.el
@@ -961,7 +961,7 @@ OPT-PLIST is the export options list."
          (if (string-match "^file:" desc)
              (setq desc (substring desc (match-end 0)))))
        (setq desc (org-add-props
-                      (concat "<img src=\"" desc "\" alt=\""
+                      (concat "<img src=\"/" desc "\" alt=\"/"
                               (file-name-nondirectory desc) "\"/>")
                       '(org-protected t))))
       (cond
@@ -1960,7 +1960,7 @@ PUB-DIR is set, use this as the publishing directory."
   "Create image tag with source and attributes."
   (save-match-data
     (if (string-match "^ltxpng/" src)
-       (format "<img src=\"%s\" alt=\"%s\"/>"
+       (format "<img src=\"/%s\" alt=\"/%s\"/>"
                 src (org-find-text-property-in-string 'org-latex-src src))
       (let* ((caption (org-find-text-property-in-string 'org-caption src))
             (attr (org-find-text-property-in-string 'org-attributes src))
@@ -1972,7 +1972,7 @@ PUB-DIR is set, use this as the publishing directory."
 <p>"
                    (if org-par-open "</p>\n" "")
                    (if label (format "id=\"%s\" " (org-solidify-link-text label)) "")))
-       (format "<img src=\"%s\"%s />"
+       (format "<img src=\"/%s\"%s />"
                src
                (if (string-match "\\<alt=" (or attr ""))
                    (concat " " attr )
{% endcodeblock %}

修改完成以后，就可以在编写Org文档的时候执行 <code>M-x my-screenshot</code> 进行抓屏了，抓好的图片存放在当前目录的 <code>./image/blog/</code> 下，命名使用随机命名方式。最后，这个脚本还会开启Emacs <code>Org-Mode</code> 的内嵌图片显示，达到图文并茂的效果。如果不需要该功能，可以使用快捷键 <code>C-c C-x C-v</code> 来关闭。
</p>
<p>
截个之前<a href="#fig-Vim">配置好的Vim</a>，看看效果吧!
</p>

<div id="fig-Vim" class="figure">
<p><img src="/./images/blog/./90530rcx.png"  alt="./images/blog/./90530rcx.png" /></p>
<p>Vim with taglist</p>
</div>

<div id="footnotes">
<h2 class="footnotes">Footnotes: </h2>
<div id="text-footnotes">
<p class="footnote"><sup><a class="footnum" name="fn.1" href="#fnr.1">1</a></sup> <a href="http://dreamrunner.org/wiki/public_html/Emacs/org-mode.html">http://dreamrunner.org/wiki/public_html/Emacs/org-mode.html</a>
</p>
</div>
</div>
