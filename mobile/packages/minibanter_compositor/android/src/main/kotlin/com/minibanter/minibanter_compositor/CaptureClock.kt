package com.minibanter.minibanter_compositor

/**
 * Converts Camera2's nanosecond frame timestamps into recording-relative
 * microsecond presentation timestamps. The first frame delivered after the
 * encoder has been armed is the recording origin; wall-clock time is never
 * used for encoded-video PTS.
 */
internal class CaptureClock {
    private var recordingOriginNs: Long? = null

    fun startAt(sensorTimestampNs: Long) {
        require(sensorTimestampNs >= 0) { "Camera frame timestamp must be non-negative." }
        if (recordingOriginNs == null) {
            recordingOriginNs = sensorTimestampNs
        }
    }

    fun presentationUs(sensorTimestampNs: Long): Long {
        return recordingRelativeNs(sensorTimestampNs) / NANOS_PER_MICROSECOND
    }

    /**
     * Returns the recording-relative nanosecond PTS for
     * EGLExt.eglPresentationTimeANDROID. Keep this precision until the EGL
     * boundary; converting through microseconds would quantize encoder frames.
     */
    fun encoderPresentationTimeNs(sensorTimestampNs: Long): Long {
        return recordingRelativeNs(sensorTimestampNs)
    }

    private fun recordingRelativeNs(sensorTimestampNs: Long): Long {
        val recordingOriginNs = checkNotNull(recordingOriginNs) {
            "Capture clock has not received its first camera frame."
        }
        require(sensorTimestampNs >= recordingOriginNs) {
            "Camera frame timestamps must not move backwards."
        }
        return sensorTimestampNs - recordingOriginNs
    }

    fun reset() {
        recordingOriginNs = null
    }

    private companion object {
        const val NANOS_PER_MICROSECOND = 1_000L
    }
}
