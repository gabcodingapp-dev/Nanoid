package com.gab.nanoid

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.animation.PathInterpolator
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity

/**
 * Nanoid entry point.
 *
 * Extends [AudioServiceActivity] (rather than FlutterActivity) because
 * audio_service requires its activity to host the Flutter engine. Previously
 * the manifest pointed straight at AudioServiceActivity and this class was
 * never instantiated, so anything here was dead code.
 */
class MainActivity : AudioServiceActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Aligns the Flutter view vertically with the window.
        WindowCompat.setDecorFitsSystemWindows(window, false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Hand the splash off with a short fade + gentle scale instead of a
            // hard cut. Deliberately brief so it never reads as an intro
            // animation: it plays over Flutter's already-rendered first frame,
            // so it costs nothing at startup.
            // The platform API hands back an android.window.SplashScreenView,
            // which is itself a View (unlike androidx's SplashScreenViewProvider,
            // which exposes a .view). Animate it directly.
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                val fade = ObjectAnimator.ofFloat(splashScreenView, View.ALPHA, 1f, 0f)
                val scaleX = ObjectAnimator.ofFloat(splashScreenView, View.SCALE_X, 1f, 1.06f)
                val scaleY = ObjectAnimator.ofFloat(splashScreenView, View.SCALE_Y, 1f, 1.06f)

                AnimatorSet().apply {
                    playTogether(fade, scaleX, scaleY)
                    duration = SPLASH_EXIT_DURATION_MS
                    interpolator = PathInterpolator(0.4f, 0f, 0.2f, 1f)
                    addListener(object : AnimatorListenerAdapter() {
                        override fun onAnimationEnd(animation: Animator) {
                            splashScreenView.remove()
                        }
                    })
                    start()
                }
            }
        }

        super.onCreate(savedInstanceState)
    }

    private companion object {
        const val SPLASH_EXIT_DURATION_MS = 320L
    }
}
