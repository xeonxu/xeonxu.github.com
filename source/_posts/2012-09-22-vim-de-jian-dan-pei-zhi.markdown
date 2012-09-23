---
layout: post
title: "Vim的简单配置"
date: 2012-09-22 21:49
comments: true
categories: Vim Linux 开发
---

<p>
自己平时喜欢使用<a href="http://www.gnu.org/software/emacs/">GNU Emacs</a>，但是单位工作环境的限制，使我不得不在<a href="http://www.gnu.org/software/screen/">GNU Screen</a>下运行GNU Emacs。但是貌似Screen和Emacs有点小的兼容性问题，至少我没能调整到完全正常。使用中，Emacs经常会上移一行从而造成画面错乱，让人用的很不爽。为此，我决定在工作环境中暂时使用别的编辑器来替代Emacs。之后，我尝试过使用<a href="http://www.emacswiki.org/emacs/MicroEmacs">Micro Emacs</a>，包括Linus最喜欢用的<a href="http://git.kernel.org/?p=editors/uemacs/uemacs.git;a=tree">uEmacs PK</a>，可惜这玩意儿和GNU Emacs差异有点大，加之所有MicroEmacs对多字节语系支持地都不是很好，而自己又是个懒人也不是特别Geek，就没继续用下去。于是我重新将目光放到了<a href="http://www.vim.org">VIM</a> 上。
好在工作中对编辑器的要求不是特别高，VIM也不是特别难使，自己又磕磕碰碰地在网上找了些配置添加到自己的Vim上。用起来还不错，可以交叉索引跳转，可以Outline，对我来说，这就够了。
下面简单列举一下Vim的配置方法，算个存档记录。
</p>
<ul>
<li>Cscope安装配置
<ol>
<li>安装Cscope
     去<a href="http://cscope.sourceforge.net">http://cscope.sourceforge.net</a> 下载cscope源码，然后编译安装。
</li>
<li>在个人目录下的 <code>.vimrc</code> 文件中添加如下配置
</li>
</ol>

</li>
</ul>


{% codeblock cscope配置 lang:bash %}
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" cscope setting
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" if has("cscope")
"   set csprg=/usr/local/bin/cscope
"   set csto=1
"   set cst
"   set nocsverb
"   " add any database in current directory
"   if filereadable("cscope.out")
"       cs add cscope.out
"   endif
"   set csverb
" endif
"
" nmap <C-@>s :cs find s <C-R>=expand("<cword>")<CR><CR>
" nmap <C-@>g :cs find g <C-R>=expand("<cword>")<CR><CR>
" nmap <C-@>c :cs find c <C-R>=expand("<cword>")<CR><CR>
" nmap <C-@>t :cs find t <C-R>=expand("<cword>")<CR><CR>
" nmap <C-@>e :cs find e <C-R>=expand("<cword>")<CR><CR>
" nmap <C-@>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
" nmap <C-@>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
" nmap <C-@>d :cs find d <C-R>=expand("<cword>")<CR><CR>
function! LoadCscope()
let db = findfile("cscope.out", ".;")
if (!empty(db))
  let path = strpart(db, 0, match(db, "/cscope.out$"))
  set nocsverb " suppress 'duplicate connection' error
  set csto=0
  set cst
  " add any database in current directory
  if filereadable(db)
     exe "cs add " . db . " " . path
     nmap <C-c>s :cs find s <C-R>=expand("<cword>")<CR><CR>
     nmap <C-c>g :cs find g <C-R>=expand("<cword>")<CR><CR>
     nmap <C-c>c :cs find c <C-R>=expand("<cword>")<CR><CR>
     nmap <C-c>t :cs find t <C-R>=expand("<cword>")<CR><CR>
     nmap <C-c>e :cs find e <C-R>=expand("<cword>")<CR><CR>
     nmap <C-c>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
     nmap <C-c>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
     nmap <C-c>d :cs find d <C-R>=expand("<cword>")<CR><CR>
  " else add database pointed to by environment
  elseif $CSCOPE_DB != ""
     cs add $CSCOPE_DB
  endif
  set csverb
endif
endfunction
au BufEnter /* call LoadCscope()
{% endcodeblock %}
<ol>
<li>使用时先去要查看的代码目录，然后执行cscope -bqR。完成之后，直接 <code>vi filename</code> 。在需要查找的符号上使用 <code>C-c s/g/c/t/e/f/i/d</code> 即可调用相应的功能。原来cscope插件使用 <code>C-@</code> 做命令引导键，我为了和Emacs同步，将其改为了 <code>C-c</code> 。
</li>
<li>添加Outline显示
</li>
</ol>

<p>  Outline显示由Taglist来实现：
</p><ol>
<li>去<a href="http://www.vim.org/scripts/script.php?script_id=273">http://www.vim.org/scripts/script.php?script_id=273</a> 下载Taglist。
</li>
<li>解压后将 <code>taglist.vim</code> 文件放在个人目录下的 <code>.vim/plugin/</code> 目录中。同时，将解压后的 <code>taglist.txt</code> 文件放在个人目录下的 <code>.vim/doc/</code> 目录中。
</li>
<li>最后，添加以下配置到个人目录下的 <code>.vimrc</code> 文件中：
</li>
</ol>


{% codeblock taglist配置 lang:bash %}
" use F8 to toggle taglist
nnoremap <silent> <F8> :TlistToggle<CR>
let Tlist_GainFocus_On_ToggleOpen=1
let Tlist_Close_On_Select=1
{% endcodeblock %}
<p>
  如此便可方便的通过F8按键打开当前文件的Outline，并将光标置于Outline中，选择条目后自动关闭。
</p>
<ul>
<li>设置高亮搜索，自动缩进以及语法高亮
  将以下配置添加到个人目录下的 <code>.vimrc</code> 文件中：
</li>
</ul>


{% codeblock 高亮缩进配置 lang:bash %}
set nu
set hlsearch
syntax enable
set showmatch
set ts=4
set softtabstop=4
set shiftwidth=4
set expandtab
set autoindent
set cindent
{% endcodeblock %}

<p>
OK，如此配置后，查看代码编辑代码舒服多了。
</p>