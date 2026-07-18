package com.minibanter.minibanter_compositor

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Registers typed Pigeon commands for the native Android compositor. */
class MinibanterCompositorPlugin : FlutterPlugin {
    private var session: AndroidCompositorSession? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val compositorSession = AndroidCompositorSession()
        session = compositorSession
        CompositorHostApi.setUp(binding.binaryMessenger, compositorSession)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CompositorHostApi.setUp(binding.binaryMessenger, null)
        session?.dispose { }
        session = null
    }
}
