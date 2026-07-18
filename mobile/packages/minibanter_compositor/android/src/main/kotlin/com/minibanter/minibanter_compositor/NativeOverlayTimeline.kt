package com.minibanter.minibanter_compositor

/**
 * Immutable-cue timeline consumed by the Android render thread at a camera
 * presentation timestamp. A replacement atomically supersedes the cue with
 * the same id; individual cues are never mutated while they may be rendered.
 */
internal class NativeOverlayTimeline {
    private val cuesById = linkedMapOf<String, CompositorCue>()

    fun replace(cue: CompositorCue) {
        require(cue.startUs >= 0) { "Overlay cue start must be non-negative." }
        require(cue.endUs > cue.startUs) { "Overlay cue end must follow start." }
        cuesById[cue.id] = cue
    }

    fun activeAt(presentationUs: Long): List<CompositorCue> {
        require(presentationUs >= 0) { "Presentation timestamp must be non-negative." }
        return cuesById.values
            .asSequence()
            .filter { it.startUs <= presentationUs && presentationUs < it.endUs }
            .sortedWith(compareBy<CompositorCue> { it.zIndex }.thenBy { it.id })
            .toList()
    }

    fun clear() {
        cuesById.clear()
    }
}
