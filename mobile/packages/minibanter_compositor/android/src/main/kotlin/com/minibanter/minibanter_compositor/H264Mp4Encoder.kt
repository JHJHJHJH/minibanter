package com.minibanter.minibanter_compositor

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.view.Surface
import java.io.File

/**
 * H.264 encoder owned by the native compositor. EGL renders each already-
 * composited frame into [inputSurface]; this class drains encoder output into
 * an MP4 without decoding or server-side re-rendering.
 */
internal class H264Mp4Encoder(
    private val outputFile: File,
    width: Int,
    height: Int,
    fps: Int,
) {
    private val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
    private val muxer = MediaMuxer(outputFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    private val bufferInfo = MediaCodec.BufferInfo()
    private var videoTrackIndex = -1
    private var muxerStarted = false
    private var ended = false
    var durationUs: Long = 0
        private set

    val inputSurface: Surface

    init {
        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, width * height * 4)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        inputSurface = encoder.createInputSurface()
        encoder.start()
    }

    /** Drains available encoded samples. Call after each EGL swap and at stop. */
    fun drain(endOfStream: Boolean) {
        check(!ended) { "Encoder has already ended." }
        if (endOfStream) encoder.signalEndOfInputStream()
        while (true) {
            when (val outputIndex = encoder.dequeueOutputBuffer(bufferInfo, 10_000)) {
                MediaCodec.INFO_TRY_AGAIN_LATER -> if (!endOfStream) return
                MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    check(!muxerStarted) { "Muxer format changed twice." }
                    videoTrackIndex = muxer.addTrack(encoder.outputFormat)
                    muxer.start()
                    muxerStarted = true
                }
                else -> if (outputIndex >= 0) {
                    val encoded = requireNotNull(encoder.getOutputBuffer(outputIndex))
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }
                    if (bufferInfo.size > 0) {
                        check(muxerStarted) { "Encoder emitted video before muxer initialization." }
                        encoded.position(bufferInfo.offset)
                        encoded.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(videoTrackIndex, encoded, bufferInfo)
                        durationUs = maxOf(durationUs, bufferInfo.presentationTimeUs)
                    }
                    val eos = bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                    encoder.releaseOutputBuffer(outputIndex, false)
                    if (eos) {
                        ended = true
                        return
                    }
                }
            }
        }
    }

    fun release() {
        inputSurface.release()
        encoder.stop()
        encoder.release()
        if (muxerStarted) muxer.stop()
        muxer.release()
    }
}
