{
  local common = import 'common.jsonnet',

  local metaNameDesc (c) =
    (if "name" in c then { name: c.name } else {}) +
    (if "desc" in c then { desc: c.desc } else {}) +
    (if "location" in c then { location: c.location } else {}) +
    (if "address" in c then { address: c.address } else {}) +
    (if "serial_number" in c then { serial_number: c.serial_number } else {}),

  local dynamic (c) = !("rec" in c) || (c.rec == "none"),

  local camOrigMeta (cid, c) =
    local meta = metaNameDesc(c);
    {
      __orig:: c + {
        substreamOf: null,
        camName: common.mk_cam_name(cid, c.id),
        meta: meta,
      },
      meta: meta,
      dynamic: dynamic(self.__orig),
    },

  
  local camOrigMetaSub (cid, c, ss) =
    local origCamName = common.mk_cam_name(cid, c.id);
    local meta = metaNameDesc(c) + { origin: origCamName, stream: ss.suffix };
    {
      __orig:: c + {
        rec: if "rec" in ss then ss.rec else "none",
        substreamOf: c.id,
        id: c.id + "_" + ss.suffix,
        recEventSource: origCamName,
        camName: common.mk_cam_name_sub(cid, c.id, ss.suffix),
        meta: meta,
      } + (if "proc" in ss then { proc: ss.proc } else { proc: null }),
      meta: meta,
      dynamic: dynamic(self.__orig)
    },

  local substreams (c) = if "substreams" in c then c["substreams"] else [],
  
  make_app (cid, conf): {
    local onvifSet = if "onvif" in conf then conf.onvif else [],
    local rtspSet = if "rtsp" in conf then conf.rtsp else [],

    local mk_onvif_substreams(c) =
      [common.mk_onvif(common.mk_cam_name_sub(cid, c.id, ss.suffix),
                       c.addr,
                       conf.creds[if "cred" in c then c["cred"] else 0],
                       ss.profile)
       + { enable: ['video', 'audio'] }
       + camOrigMetaSub(cid, c, ss)
       for ss in substreams(c)],
    local mk_rtsp_substreams(c) =
      [common.mk_rtsp(common.mk_cam_name_sub(cid, c.id, ss.suffix),
                      ss.url)
       + (if "cred" in c then {auth: conf.creds[c.cred]} else {})
       + { enable: ['video', 'audio'] }
       + camOrigMetaSub(cid, c, ss)
       for ss in substreams(c)],

    local srcOnvif =
      std.map(function(c) common.mk_onvif(common.mk_cam_name(cid, c.id),
                                          c.addr,
                                          conf.creds[if "cred" in c then c["cred"] else 0],
                                          if "profile" in c then c.profile else null) + camOrigMeta(cid, c),
              onvifSet),
    local srcRtsp =
      std.map(function(c) common.mk_rtsp(common.mk_cam_name(cid, c.id), c.url) +
              (if "cred" in c then {auth: conf.creds[c.cred]} else {}) + camOrigMeta(cid, c),
              rtspSet),
    local srcRtspSubstreams = std.flattenArrays(std.map(mk_rtsp_substreams, rtspSet)),
    local srcOnvifSubstreams = std.flattenArrays(std.map(mk_onvif_substreams, onvifSet)),
    sources: srcOnvif + srcRtsp + srcOnvifSubstreams + srcRtspSubstreams,
    local recPermanent = std.filter(function (s) "rec" in s.__orig && s.__orig.rec == "permanent", self.sources),
    local recMotion = std.filter(function (s) "rec" in s.__orig && s.__orig.rec == "motion", self.sources),
    record: if std.all(std.map(function(s) s.__orig.rec == "none", self.sources)) then null else { motion: recMotion, permanent: recPermanent },

    appDefault: {
      webrtc: true,
      rtspsrv: true,
      websrv: true,
      wamp: false,
      metrics: true,
      events: "sqlite",
      repl: null,
    },

    local confApp = self.appDefault + if "app" in conf then conf.app else {},

    webrtc: confApp.webrtc,
    rtspsrv: confApp.rtspsrv,
    websrv: confApp.websrv,
    wamp: confApp.wamp,
    metrics: confApp.metrics,
    events: confApp.events,
    repl: confApp.repl,
  }
}
