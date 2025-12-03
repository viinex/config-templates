{
  local common = import 'common.jsonnet',

  local metaNameDesc (c) =
    (if "name" in c then { name: c.name } else {}) +
    (if "desc" in c then { desc: c.desc } else {}) +
    (if "location" in c then { location: c.location } else {}) +
    (if "address" in c then { address: c.address } else {}) +
    (if "serial_number" in c then { serial_number: c.serial_number } else {}),

  local dynamic (confApp, c) = (!("rec" in c) || (c.rec == "none")) && (!("allowDynamicSources" in confApp) || confApp.allowDynamicSources),

  local camOrigMeta (cid, confApp, c) =
    local meta = metaNameDesc(c);
    {
      __orig:: c + {
        substreamOf: null,
        camName: common.mk_cam_name(cid, confApp, c.id),
        meta: meta,
      },
      meta: meta,
      dynamic: dynamic(confApp, self.__orig),
    },

  
  local camOrigMetaSub (cid, confApp, c, ss) =
    local origCamName = common.mk_cam_name(cid, confApp, c.id);
    local meta = metaNameDesc(c) + { origin: origCamName, stream: ss.suffix };
    {
      __orig:: c + {
        rec: if "rec" in ss then ss.rec else "none",
        substreamOf: c.id,
        id: c.id + "_" + ss.suffix,
        recEventSource: common.mk_cam_name(cid, confApp, c.id),
        camName: common.mk_cam_name_sub(cid, confApp, c.id, ss.suffix),
        meta: meta,
      } + (if "proc" in ss then { proc: ss.proc } else { proc: null }),
      meta: meta,
      dynamic: dynamic(confApp, self.__orig)
    },

  local substreams (c) = if "substreams" in c then c["substreams"] else [],
  
  make_app (cid, appDef): {
    local onvifSet = if "onvif" in appDef then appDef.onvif else [],

    local rtspSet = if "rtsp" in appDef then appDef.rtsp else [],

    local stripPathExt(p) =
      local s = std.split(p, '/');
      local basename = s[std.length(s)-1];
      local e = std.split(basename, '.');
      local res = std.join('.', e[:-1]);
      res,

    local mediafileSet = if "mediafile" in appDef then
                           std.map(function(p)
                               local res = {
                                 id: stripPathExt(p),
                                 path: p,
                               }; res,
                                  appDef.mediafile) else [],

    camOrigMeta: camOrigMeta,
    camOrigMetaSub: camOrigMetaSub,

    local mk_onvif_substreams(c) =
      [common.mk_onvif(common.mk_cam_name_sub(cid, confApp, c.id, ss.suffix),
                       c.addr,
                       appDef.creds[if "cred" in c then c["cred"] else 0],
                       ss.profile)
       + { enable: ['video', 'audio'] }
       + camOrigMetaSub(cid, confApp, c, ss)
       for ss in substreams(c)],
    local mk_rtsp_substreams(c) =
      [common.mk_rtsp(common.mk_cam_name_sub(cid, confApp, c.id, ss.suffix),
                      ss.url,
                      if "cred" in c then appDef.creds[c.cred] else null)
       + { enable: ['video', 'audio'] }
       + camOrigMetaSub(cid, confApp, c, ss)
       for ss in substreams(c)],

    local srcOnvif =
      std.map(function(c) common.mk_onvif(common.mk_cam_name(cid, confApp, c.id),
                                          c.addr,
                                          appDef.creds[if "cred" in c then c["cred"] else 0],
                                          if "profile" in c then c.profile else null) + camOrigMeta(cid, confApp, c),
              onvifSet),
    local srcRtsp =
      std.map(function(c) common.mk_rtsp(common.mk_cam_name(cid, confApp, c.id), c.url,
                                         if "cred" in c then appDef.creds[c.cred] else null)
              + camOrigMeta(cid, confApp, c),
              rtspSet),
    local srcMediafiles =
      std.map(function(c) local r = common.mk_mediafile(common.mk_cam_name(cid, confApp, c.id), c.path);
              r + camOrigMeta(cid, confApp, c) + {dynamic: false}, mediafileSet),
    local srcRtspSubstreams = std.flattenArrays(std.map(mk_rtsp_substreams, rtspSet)),
    local srcOnvifSubstreams = std.flattenArrays(std.map(mk_onvif_substreams, onvifSet)),
    sources: srcOnvif + srcRtsp + srcOnvifSubstreams + srcRtspSubstreams + srcMediafiles,
    local recPermanent = std.filter(function (s) "rec" in s.__orig && s.__orig.rec == "permanent", self.sources),
    local recMotion = std.filter(function (s) "rec" in s.__orig && s.__orig.rec == "motion", self.sources),
    record: if std.all(std.map(function(s) s.__orig.rec == "none", self.sources)) then null else { motion: recMotion, permanent: recPermanent },

    appDefault: {
      webrtc: true,
      rtspsrv: true,
      websrv: true,
      wamp: true,
      metrics: true,
      events: "sqlite",
      repl: null,
      zmq: null,

      preserveSourceIds: false,
      allowDynamicSources: true,
      recordRetainDaysMax: null,
    },

    local confApp = self.appDefault + if "app" in appDef then appDef.app else {},

    webrtc: confApp.webrtc,
    rtspsrv: confApp.rtspsrv,
    websrv: confApp.websrv,
    wamp: confApp.wamp,
    metrics: confApp.metrics,
    events: confApp.events,
    repl: confApp.repl,
    zmq: confApp.zmq,
    // construct media source ids as "cam_CLUSTER_CAMID" or preserve just "CAMID"
    preserveSourceIds: confApp.preserveSourceIds,
    // global switch to disable dynamic sources
    allowDynamicSources: confApp.allowDynamicSources,
    recordRetainDaysMax: confApp.recordRetainDaysMax,
  }

}
