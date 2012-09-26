---
layout: post
title: "调节Android拨号键盘的震动效果"
date: 2012-09-24 21:48
comments: true
categories: Android 开发 Linux
---

<p>
最近在做高通Android项目时遇到一个问题，测试报告说拨号键盘中按键震感偏弱，问题首先提到了我这里。于是，我首先去内核驱动里检查了一下振子的配置，发现给振子的供电已经调到最高值了，看来只能从别的方向下手解决这个问题。震感强烈与否取决于两个因素，一个是驱动电流/驱动电压，而另一个是驱动时长。由于这个项目中给振子的供电是个LDO，只能调节驱动电压，而同时驱动电压已经最大，所以需要想办法加长驱动时间。
</p>
<p>
在和应用一块分析了Android拨号键盘应用的代码后，按键震动的实现在 <code>packages/apps/Contacts/src/com/android/contacts/dialpad/DialpadFragment.java</code> 文件中。该文件中实现了拨号键盘按钮 <code>onClick</code> 事件的监听，其中：
{% codeblock DialpadFragment.java lang:java %}
@Override
public void onClick(View view) {
    switch (view.getId()) {
        case R.id.one: {
            playTone(ToneGenerator.TONE_DTMF_1);
            keyPressed(KeyEvent.KEYCODE_1);
            return;
        }
        case R.id.two: {
            playTone(ToneGenerator.TONE_DTMF_2);
            keyPressed(KeyEvent.KEYCODE_2);
            return;
        }
        case R.id.three: {
            playTone(ToneGenerator.TONE_DTMF_3);
            keyPressed(KeyEvent.KEYCODE_3);
            return;
        }
//以下省略
}
{% endcodeblock %}
可以看到该监听事件中播放了按键音，同时调用了 <code>keyPressed</code> 这个方法。再来看 <code>keyPressed</code> 方法的实现：
{% codeblock DialpadFragment.java lang:c %}
private void keyPressed(int keyCode) {
    mHaptic.vibrate();
    KeyEvent event = new KeyEvent(KeyEvent.ACTION_DOWN, keyCode);
    mDigits.onKeyDown(keyCode, event);

    // If the cursor is at the end of the text we hide it.
    final int length = mDigits.length();
    if (length == mDigits.getSelectionStart() && length == mDigits.getSelectionEnd()) {
        mDigits.setCursorVisible(false);
    }
}
{% endcodeblock %}
注意 <code>mHaptic.vibrate()</code> ，从方法名称上可以看出这个方法和震动相关，所以现在只要搞清楚该方法的具体实现即可。继续往下追，从该类变量的声明 <code>private HapticFeedback mHaptic = new HapticFeedback();</code> 可以看到，这个方法属于一个名叫 <code>HapticFeedback</code> 的类。而 <code>HapticFeedback</code> 类存在于 <code>packages/apps/Phone/src/com/android/phone/HapticFeedback.java</code> 文件中。顺利找到 <code>vibrate()</code> 的定义：
{% codeblock HapticFeedback.java lang:java %}
public void vibrate() {
    if (!mEnabled || !mSettingEnabled) {
        return;
    }
    mVibrator.vibrate(mHapticPattern, NO_REPEAT);
}
{% endcodeblock %}
其中的判断无需关心，通过名称可以看出应该是和震动设定有关。之后调用了另一个类 <code>Vibrator</code> 的 <code>vibrate</code> 方法。该方法接受两个参数，同样通过名称看得出第一个参数有关模式，第二个参数有关是否重复。去 <code>Vibrator</code> 类里看看，该类存在于 <code>frameworks/base/core/java/android/os/Vibrator.java</code> 文件中，找到 <code>vibrate</code> 的实现<sup><a class="footref" name="fnr.1" href="#fn.1">1</a></sup>：
{% codeblock Vibrator.java lang:java %}
/**
 * Vibrate with a given pattern.
 *
 * <p>
 * Pass in an array of ints that are the durations for which to turn on or off
 * the vibrator in milliseconds.  The first value indicates the number of milliseconds
 * to wait before turning the vibrator on.  The next value indicates the number of milliseconds
 * for which to keep the vibrator on before turning it off.  Subsequent values alternate
 * between durations in milliseconds to turn the vibrator off or to turn the vibrator on.
 * </p><p>
 * To cause the pattern to repeat, pass the index into the pattern array at which
 * to start the repeat, or -1 to disable repeating.
 * </p>
 *
 * @param pattern an array of longs of times for which to turn the vibrator on or off.
 * @param repeat the index into pattern at which to repeat, or -1 if
 *        you don't want to repeat.
 */
public void vibrate(long[] pattern, int repeat)
{
    if (mService == null) {
        Log.w(TAG, "Failed to vibrate; no vibrator service.");
        return;
    }
    // catch this here because the server will do nothing.  pattern may
    // not be null, let that be checked, because the server will drop it
    // anyway
    if (repeat < pattern.length) {
        try {
            mService.vibratePattern(pattern, repeat, mToken);
        } catch (RemoteException e) {
            Log.w(TAG, "Failed to vibrate.", e);
        }
    } else {
        throw new ArrayIndexOutOfBoundsException();
    }
}
{% endcodeblock %}
从注释可以了解到该震动模式的意义，第一个值为等待开启震动的时间，第二个为开启震动后持续的时间，之后交替数字为关闭震动的时间以及开启震动的时间。有兴趣可以追到 <code>frameworks/base/services/java/com/android/server/VibratorService.java</code> 看看 <code>vibratePattern</code> 的实现。不过我们已经找到需要的一切了。OK，再次回到 <code>packages/apps/Phone/src/com/android/phone/HapticFeedback.java</code> 文件中查看传入的震动模式设置，很简单搜到以下处理：
{% codeblock HapticFeedback.java lang:java %}
public void init(Context context, boolean enabled) {
     mEnabled = enabled;
     if (enabled) {
         mVibrator = new Vibrator();
         if (!loadHapticSystemPattern(context.getResources())) {
             mHapticPattern = new long[] {0, DURATION, 2 * DURATION, 3 * DURATION};
         }
         mSystemSettings = new Settings.System();
         mContentResolver = context.getContentResolver();
     }
}
{% endcodeblock %}
首先尝试从系统设置里载入震动模式，否则使用默认的 <code>new long[] {0, DURATION, 2 * DURATION, 3 * DURATION};</code> 模式。其中 <code>DURATION</code> 等于10，所以默认的模式为等待0秒，震10毫秒，停20毫秒，之后震动30毫秒。注释掉 <code>if (!loadHapticSystemPattern(context.getResources()))</code> 判断，然后将默认震动模式改为 <code>{0, 6*DURATION, 1 * DURATION, 6 * DURATION};</code> 试试效果。执行：
{% codeblock 编译 lang:bash %}
mmm packages/apps/Contacts/&&mmm packages/apps/Phone/
{% endcodeblock %}
然后将编译好的apk文件推到手机上，震感明显，说明修改正确<sup><a class="footref" name="fnr.2" href="#fn.2">2</a></sup>。现在只需要去xml文件中找到震动模式的设置部分，相应修改就可以了。最后找到 <code>frameworks/base/core/res/res/values/config.xml</code> 文件，其中有一部分为：
{% codeblock 设置 lang:xml %}
<!-- Vibrator pattern for feedback about touching a virtual key -->
<integer-array name="config_virtualKeyVibePattern">
    <item>0</item>
    <item>10</item>
    <item>20</item>
    <item>30</item>
</integer-array>
{% endcodeblock %}
是不是和之前看到的默认震动模式很像呢？最后，根据具体情况调了一个比较适中的值，任务完成。
</p>
<div id="footnotes">
<h2 class="footnotes">Footnotes: </h2>
<div id="text-footnotes">
<p class="footnote"><sup><a class="footnum" name="fn.1" href="#fnr.1">1</a></sup> 还有另外一个 <code>vibrate</code> 的实现，但是该实现只接受一个参数，所以不是我们要找的目标。
</p>


<p class="footnote"><sup><a class="footnum" name="fn.2" href="#fnr.2">2</a></sup> 修改震动设置后，必须同时编译Contact和Phone，并同时更新到手机上才能生效，具体原因不明白，感觉很怪异。
</p>



</div>
</div>
