package com.minibanter.minibanter_compositor

import kotlin.test.Test
import kotlin.test.assertEquals

internal class NativeOverlayTimelineTest {
    @Test
    fun activeCuesAt_returnsOnlyActiveCues_inStableZOrder() {
        val timeline = NativeOverlayTimeline()
        val lower = cue(id = "lower", startUs = 100, endUs = 300, zIndex = 1)
        val upper = cue(id = "upper", startUs = 100, endUs = 300, zIndex = 2)
        val expired = cue(id = "expired", startUs = 0, endUs = 100, zIndex = 0)

        timeline.replace(expired)
        timeline.replace(upper)
        timeline.replace(lower)

        assertEquals(listOf(lower, upper), timeline.activeAt(100))
        assertEquals(emptyList(), timeline.activeAt(300))
    }

    @Test
    fun replace_replaces_the_prior_cue_with_the_same_id() {
        val timeline = NativeOverlayTimeline()
        val original = cue(id = "caption", startUs = 100, endUs = 300, zIndex = 1)
        val replacement = cue(id = "caption", startUs = 400, endUs = 600, zIndex = 1)

        timeline.replace(original)
        timeline.replace(replacement)

        assertEquals(emptyList(), timeline.activeAt(100))
        assertEquals(listOf(replacement), timeline.activeAt(400))
    }

    @Test
    fun activeCuesAt_orders_equal_layers_by_id_independent_of_arrival_order() {
        val timeline = NativeOverlayTimeline()
        val zulu = cue(id = "zulu", startUs = 100, endUs = 300, zIndex = 1)
        val alpha = cue(id = "alpha", startUs = 100, endUs = 300, zIndex = 1)

        timeline.replace(zulu)
        timeline.replace(alpha)

        assertEquals(listOf(alpha, zulu), timeline.activeAt(100))
    }

    @Test
    fun clear_removes_queued_cues() {
        val timeline = NativeOverlayTimeline()
        timeline.replace(cue(id = "caption", startUs = 0, endUs = 100, zIndex = 1))

        timeline.clear()

        assertEquals(emptyList(), timeline.activeAt(0))
    }

    private fun cue(id: String, startUs: Long, endUs: Long, zIndex: Long) = CompositorCue(
        id = id,
        kind = "caption",
        text = "A fictional subtitle.",
        startUs = startUs,
        endUs = endUs,
        x = 0.5,
        y = 0.83,
        scale = 1.0,
        rotationDegrees = 0.0,
        zIndex = zIndex,
        styleTemplate = "lower_third_v1",
    )
}
