---
layout: post
title: "使用tmux改进终端体验"
date: 2012-11-04 23:59
comments: true
categories: Linux 开发
---

<p>
之前一直使用GNU Screen作为我的终端管理软件，但是发现它和我使用的Emacs编辑器不兼容，其表现是画面会被无规律的撕裂，经常造成无法正常显示和编辑文件。虽然也尝试过不少配置方法，但是都没有效果。这迫使我去寻找GNU Screen的替代品，直到后来遇到<a href="http://tmux.sourceforge.net">tmux</a> ，才将我从混乱的画面中拯救出来。tmux和Emacs的兼容非常好，没有任何问题，这点让我非常满意。同时，tmux拥有强大的自定义能力，只需简单的配置，就可以使工作环境舒适度显著提高。
</p>
<p>
首先，先简单了解一下tmux。tmux顾名思义，取terminal multiplexer之意，及终端复用器，其源代码基于BSD协议进行开源和分发。使用上来说，tmux和GNU Screen大同小异，都是使用命令引导键来进行操作，不过tmux的默认引导键由Screen的 <code>C-a</code> 变更为了 <code>C-b</code> 。另外，常用命令也和Gnu Screen一样可以通过 <code>引导键 ?</code> 来查看。操作方法的近似，促使我下决心从GNU Screen转换到tmux下。考虑到tmux作为GNU Screen的改进实现，功能要高级许多，仅仅用来替代GNU Screen有点大材小用的感觉。所以为了更好的学习tmux，我从<a href="http://pragprog.com/book/bhtmux/tmux">The Pragmatic Bookshelf</a>购买了名叫 <b>tmux: Productive Mouse-Free Development</b> 的书，并花了3天时间将这本书读完，感到受益匪浅。之后，按照书中的建议配置了工作环境中的tmux，感觉非常好，极大提升了终端工作的效率。下面来看看我的配置：
</p>


{% codeblock .tmux.conf配置 lang:bash %}
# 配置使用和GNU Screen相同的C-a作为命令引导键
set -g prefix C-a
# 设置终端类型为256色
set -g default-terminal "screen-256color"

# 设置状态栏前景及背景色
set -g status-bg colour23
set -g status-fg colour238

# 设置窗口标签的前景及背景色
setw -g window-status-fg colour232
setw -g window-status-bg default
setw -g window-status-attr dim

# 设置当前窗口标签的前景及背景色
setw -g window-status-current-fg colour88
setw -g window-status-current-bg colour130
setw -g window-status-current-attr bright

# 设置窗口分割的边框颜色
set -g pane-border-fg colour189
set -g pane-border-bg black

# 设置当前窗口分割的边框颜色
set -g pane-active-border-fg white
set -g pane-active-border-bg colour208

# 设置提示信息的前景及背景色
set -g message-fg colour232
set -g message-bg colour23
set -g message-attr bright

# 设置状态栏左部宽度
set -g status-left-length 40
# 设置状态栏显示内容和内容颜色。这里配置从左边开始显示，使用绿色显示session名称，黄色显示窗口号，蓝色显示窗口分割号
set -g status-left "#[fg=colour52]#S #[fg=yellow]#I #[fg=cyan]#P"
# 设置状态栏右部宽度
set -g status-right-length 80
# 设置状态栏右边内容，这里设置为时间信息
set -g status-right "#[fg=colour106]#(~/bin/system_info.sh) #[fg=colour208]|%d %b %R"
# 窗口信息居中显示
set -g status-justify centre

# 监视窗口信息，如有内容变动，进行提示
setw -g monitor-activity on
set -g visual-activity on
set -g status-utf8 on

# 窗口号和窗口分割号都以1开始（默认从0开始）
set -g base-index 1
setw -g pane-base-index 1

# 支持鼠标选择窗口，调节窗口大小
setw -g mode-mouse on
set -g mouse-select-pane on
set -g mouse-resize-pane on
set -g mouse-select-window on
set -s escape-time 1

# 设置C-a a为发送C-a键
bind a send-prefix
# 加载tmux配置文件的快捷键
bind r source-file ~/.tmux.conf\; display "Reloaded!"
# 快捷键查看man
bind / command-prompt "split-window 'exec man %%'"
unbind "%"
unbind "\""
# 修改默认的窗口分割快捷键，使用更直观的符号
bind | split-window -h
bind - split-window -v
# 选择窗口功能修改为和Screen一样的C-a "
bind "\"" choose-window

# 选择窗口分割快捷键
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
# 选择窗口快捷键
bind -r C-h select-window -t :-
bind -r C-l select-window -t :+
# 调节窗口大小快捷键
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# 快捷调整窗口分割到全屏
unbind Up
bind Up new-window -d -n tmp \; swap-pane -s tmp.1 \; select-window -t tmp
unbind Down
bind Down last-window \; swap-pane -s tmp.1 \; kill-window -t tmp

# 快捷记录窗口内的内容到文件中
bind P pipe-pane -o "cat >>~/#W.log" \; display "Toggled logging to ~/#W.log"
{% endcodeblock %}
<p>
以上配置只需要复制保存到 <code>~/.tmux.conf</code> 文件中，下次执行tmux时就生效了。
</p>
<p>
当然，tmux的高级不止在于配置功能的强大，它还支持在命令行中对指定session进行设置。利用这个特性，便可以将繁琐的工作环境初始化用脚本完成了。比如我写了如下脚本对我的工作电脑进行初始化：
{% codeblock init_tmux.sh lang:bash %}
#! /bin/bash
export AP_7x27_PROJECT="~/Developer/MSM7x27A-ICS-AP"
export MP_7x27_PROJECT="~/Developer/MSM7x27A-ICS-MP"

export AP_8x25_PROJECT="~/Developer/MSM8x25-ICS-AP"
export MP_8x25_PROJECT="~/Developer/MSM8x25-ICS-MP"

if [ -z "$TMUX" ]; then
    tmux has-session -t development7x27
    if [ $? != 0 ]; then
        # init 7x27 AP
        tmux new-session -s development7x27 -n AP_7x27 -d
        tmux send-keys -t development7x27 "cd $AP_7x27_PROJECT&&. ./build/envsetup.sh&&choosecombo 1 13 1" C-m
        tmux split-window -h -p 40 -t development7x27:1
        tmux send-keys -t development7x27 "cd $AP_7x27_PROJECT&&. ./build/envsetup.sh&&choosecombo 1 13 1" C-m
        tmux split-window -v -t development7x27:1.2
        tmux send-keys -t development7x27 "cd $AP_7x27_PROJECT&&. ./build/envsetup.sh&&choosecombo 1 13 1" C-m

        # init 7x27 MP
        tmux new-window -n MP_7x27 -t development7x27

        tmux send-keys -t development7x27:2 "cd $MP_7x27_PROJECT/modem_proc/build/ms" C-m
        tmux split-window -h -p 40 -t development7x27:2
        tmux send-keys -t development7x27:2 "cd $MP_7x27_PROJECT/modem_proc/build/ms" C-m
        tmux split-window -v -t development7x27:2.2
        tmux send-keys -t development7x27 "cd $MP_7x27_PROJECT/modem_proc/build/ms" C-m

        tmux select-window -t development7x27:1
        tmux select-pane -t development7x27:1 -L
    fi

        tmux send-keys -t development7x27:1.3 "export DISPLAY=$DISPLAY" C-m
        tmux send-keys -t development7x27:2.3 "export DISPLAY=$DISPLAY" C-m

    tmux has-session -t development8x25
    if [ $? != 0 ]; then
        # init 8x25 AP
        tmux new-session -s development8x25 -n AP_8x25 -d
        tmux send-keys -t development8x25 "cd $AP_8x25_PROJECT&&. ./build/envsetup.sh&&choosecombo 1 17 3" C-m
        tmux split-window -h -p 40 -t development8x25:1
        tmux send-keys -t development8x25 "cd $AP_8x25_PROJECT&&. ./build/envsetup.sh&&choosecombo 1 17 3" C-m
        tmux send-keys -t development8x25 'top' C-m
        tmux split-window -v -t development8x25:1.2
        tmux send-keys -t development8x25 "cd $AP_8x25_PROJECT&&. ./build/envsetup.sh&&choosecombo 1 17 3" C-m

        # init 8x25 MP
        tmux new-window -n MP_8x25 -t development8x25

        tmux send-keys -t development8x25:2 "cd $MP_8x25_PROJECT/modem_proc/build/ms" C-m
        tmux split-window -h -p 40 -t development8x25:2
        tmux send-keys -t development8x25:2 "cd $MP_8x25_PROJECT/modem_proc/build/ms" C-m
        tmux split-window -v -t development8x25:2.2
        tmux send-keys -t development8x25 "cd $MP_8x25_PROJECT/modem_proc/build/ms" C-m

        tmux select-window -t development8x25:1
        tmux select-pane -t development8x25:1 -L
    fi

        tmux send-keys -t development8x25:1.3 "export DISPLAY=$DISPLAY" C-m
        tmux send-keys -t development8x25:2.3 "export DISPLAY=$DISPLAY" C-m

    tmux attach -t development7x27
fi
{% endcodeblock %}
脚本主体思想为每次运行时判断相应的tmux session是否存在，如果存在则设置Xwindow的变量后attach；如果不存在相应session，则新建相应session并初始化session中相应窗口和窗口分割，同时在每个窗口分割中运行每次都要运行的环境初始化命令。最后设置Xwindow环境变量后attach。我的脚本中分别初始化了高通7x27 AP和MP的编译环境以及8x25 AP和MP的编译环境。
</p>
<p>
使用时，将以上内容存为文件，并在 <code>~/.bashrc</code> 中调用就可以了。这样，不论是ssh到该主机还是新开一个终端窗口，都会直接进入指定的tmux session中，继续之前的工作。加上Xwindow的设置，tmux中也可以直接运行X程序。工作中，我就是在windows上使用putty+Xming来运行使用X程序的，非常方便高效。简单的配置让工作环境大幅改进，让我觉得之前6刀买到那本书真是超值了。
</p>
<p>
说了这么多好，tmux其实也是有缺点的。最明显的一个缺点就是不支持windows，而GNU Screen却支持是windows的，这不免让人有点遗憾。所以如果有在Windows下使用类似软件的话（真的有需要吗？），只能考虑其它如GNU Screen之类的软件了。
</p>