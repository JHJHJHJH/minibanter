package com.minibanter.minibanter_compositor

import android.media.MediaCodec
import android.media.MediaMuxer

/**
 * Owns the Android-side monotonic capture clock and immutable overlay queue.
 *
 * Camera2/EGL rendering and MediaCodec/MediaMuxer output are deliberately kept
 * in this native session rather than Flutter. Encoding is not enabled until the
 * capture graph is attached; stopRecording therefore reports a native failure
 * instead of fabricating an MP4 path.
 */
internal class AndroidCompositorSession : CompositorHostApi {
    private var config: CompositorConfig? = null
    private var recordingArmed = false
    private var lastCameraTimestampNs: Long? = null
    private val captureClock = CaptureClock()
    private val overlayTimeline = NativeOverlayTimeline()

    // These declarations make the intended native media ownership explicit.
    // They are initialized by the forthcoming Camera2/EGL capture graph.
    @Suppress("unused")
    private var videoEncoder: MediaCodec? = null

    @Suppress("unused")
    private var mediaMuxer: MediaMuxer? = null

    override fun prepare(config: CompositorConfig, callback: (Result<Unit>) -> Unit) {
        if (config.width <= 0 || config.height <= 0 || config.targetFps <= 0) {
            callback(Result.failure(IllegalArgumentException("Invalid compositor configuration.")))
            return
        }
        this.config = config
        recordingArmed = false
        lastCameraTimestampNs = null
        captureClock.reset()
        overlayTimeline.clear()
        callback(Result.success(Unit))
    }

    override fun startRecording(callback: (Result<Long>) -> Unit) {
        if (config == null) {
            callback(Result.failure(IllegalStateException("Prepare the compositor before recording.")))
            return
        }
        recordingArmed = true
        lastCameraTimestampNs = null
        captureClock.reset()
        callback(Result.success(0L))
    }

    override fun currentPresentationUs(callback: (Result<Long>) -> Unit) {
        if (!recordingArmed) {
            callback(Result.failure(IllegalStateException("No native recording is active.")))
            return
        }
        val cameraTimestampNs = lastCameraTimestampNs
        if (cameraTimestampNs == null) {
            callback(Result.failure(IllegalStateException("No camera frame has reached the compositor.")))
            return
        }
        try {
            callback(Result.success(captureClock.presentationUs(cameraTimestampNs)))
        } catch (error: IllegalStateException) {
            callback(Result.failure(error))
        }
    }

    /** Called by Camera2's render path for every camera-frame timestamp. */
    internal fun onCameraFrameTimestamp(sensorTimestampNs: Long) {
        if (!recordingArmed) return
        captureClock.startAt(sensorTimestampNs)
        lastCameraTimestampNs = sensorTimestampNs
    }

    override fun appendCue(cue: CompositorCue, callback: (Result<Unit>) -> Unit) {
        replaceCue(cue, callback)
    }

    override fun replaceCue(cue: CompositorCue, callback: (Result<Unit>) -> Unit) {
        if (!recordingArmed) {
            callback(Result.failure(IllegalStateException("Start recording before adding an overlay.")))
            return
        }
        if (cue.endUs <= cue.startUs) {
            callback(Result.failure(IllegalArgumentException("Overlay cue end must follow start.")))
            return
        }
        try {
            overlayTimeline.replace(cue)
            callback(Result.success(Unit))
        } catch (error: IllegalArgumentException) {
            callback(Result.failure(error))
        }
    }

    override fun stopRecording(callback: (Result<RecordedCompositedVideo>) -> Unit) {
        recordingArmed = false
        lastCameraTimestampNs = null
        captureClock.reset()
        callback(
            Result.failure(
                UnsupportedOperationException(
                    "Camera2/EGL/MediaCodec capture graph is not attached yet; no MP4 was created.",
                ),
            ),
        )
    }

    override fun dispose(callback: (Result<Unit>) -> Unit) {
        recordingArmed = false
        lastCameraTimestampNs = null
        captureClock.reset()
        overlayTimeline.clear()
        videoEncoder?.release()
        videoEncoder = null
        mediaMuxer?.release()
        mediaMuxer = null
        callback(Result.success(Unit))
    }
}
