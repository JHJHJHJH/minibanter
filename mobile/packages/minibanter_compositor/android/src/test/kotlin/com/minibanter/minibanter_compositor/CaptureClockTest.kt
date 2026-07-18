package com.minibanter.minibanter_compositor

import kotlin.test.Test
import kotlin.test.assertEquals

internal class CaptureClockTest {
    @Test
    fun encoderPresentationTimeNs_preserves_the_camera_frame_precision() {
        val clock = CaptureClock()
        clock.startAt(4_000_000_123L)

        assertEquals(0L, clock.encoderPresentationTimeNs(4_000_000_123L))
        assertEquals(1_234_567L, clock.encoderPresentationTimeNs(4_001_234_690L))
    }
}
