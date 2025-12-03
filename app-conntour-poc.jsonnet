(import 'app-nvr.jsonnet') + {
  local common = import 'common.jsonnet',

  dynamic(c): false, // pull data permanently
  
  make_app (cid, appDef):
    super.make_app (cid, appDef) + {
      appDefault: {
        webrtc: true,
        rtspsrv: true,
        websrv: true,
        wamp: true,
        metrics: true,
        events: null,
        repl: null,
        zmq: {
          scheme: { 
            type: "savant", 
            version: "1.10.1",
          },
          behavior: "$(env.ZMQ_SOCKET_BEHAVIOR)"
        },

        preserveSourceIds: true,
        allowDynamicSources: false,
        recordRetainDaysMax: 7,
      },
      sources: srcRtsp,
      record: { motion: [], permanent: srcRtsp },

      local confApp = self.appDefault + if "app" in appDef then appDef.app else {},

      local srcRtsp =
        std.map(function(c) common.mk_rtsp(common.mk_cam_name(cid, confApp, c.uuid), c.uri,
                                           if "username" in c && "password" in c then [c.username, c.password] else null)
                + self.camOrigMeta(cid, confApp, c),
                appDef.cameras),
    },

}
