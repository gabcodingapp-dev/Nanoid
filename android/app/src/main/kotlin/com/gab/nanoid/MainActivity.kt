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
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                // Two-part hand-off, which reads far better than fading the
                // whole splash as one flat layer:
                //   1. the mark eases up and scales down slightly, as though it
                //      is settling into the app behind it;
                //   2. the backdrop fades a beat later, so the mark is never
                //      seen dissolving against a half-transparent background.
                //
                // The platform API hands back an android.window.SplashScreenView,
                // which is itself a View (androidx's SplashScreenViewProvider is
                // the one that exposes a .view). Its icon child may be null.
                val standard = PathInterpolator(0.2f, 0f, 0f, 1f)
                val accelerate = PathInterpolator(0.4f, 0f, 1f, 1f)

                val animators = mutableListOf<Animator>()

                splashScreenView.iconView?.let { icon ->
                    animators += ObjectAnimator.ofFloat(
                        icon, View.TRANSLATION_Y, 0f, -icon.height * 0.12f
                    ).apply {
                        duration = ICON_DURATION_MS
                        interpolator = standard
                    }
                    animators += ObjectAnimator.ofFloat(
                        icon, View.SCALE_X, 1f, 0.84f
                    ).apply {
                        duration = ICON_DURATION_MS
                        interpolator = standard
                    }
                    animators += ObjectAnimator.ofFloat(
                        icon, View.SCALE_Y, 1f, 0.84f
                    ).apply {
                        duration = ICON_DURATION_MS
                        interpolator = standard
                    }
                    animators += ObjectAnimator.ofFloat(
                        icon, View.ALPHA, 1f, 0f
                    ).apply {
                        duration = ICON_DURATION_MS - ICON_FADE_LEAD_MS
                        startDelay = ICON_FADE_LEAD_MS
                        interpolator = accelerate
                    }
                }

                animators += ObjectAnimator.ofFloat(
                    splashScreenView, View.ALPHA, 1f, 0f
                ).apply {
                    duration = BACKDROP_DURATION_MS
                    startDelay = BACKDROP_DELAY_MS
                    interpolator = accelerate
                }

                AnimatorSet().apply {
                    playTogether(animators)
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
        const val ICON_DURATION_MS = 340L
        const val ICON_FADE_LEAD_MS = 120L
        const val BACKDROP_DELAY_MS = 140L
        const val BACKDROP_DURATION_MS = 260L
    }
}
