{
  local common = import 'common.jsonnet',

  local camOrigMeta (c) = {
    __orig: c,
    meta: (if "name" in c then { name: c.name } else {}) +
          (if "desc" in c then { desc: c.desc } else {}),
    dynamic: !("rec" in c) || (c.rec == "none")
  },
  
  make_app (cid, conf): {
    local onvifSet = if "onvif" in conf then conf.onvif else [],
    local rtspSet = if "rtsp" in conf then conf.rtsp else [],
    local srcOnvif =
      std.map(function(c) common.mk_onvif(common.mk_cam_name(cid, c.id),
                                          std.strReplace(c.addr, ' ', ''),
                                          conf.creds[if "cred" in c then c["cred"] else 0],
                                          if "profile" in c then c.profile else null) + camOrigMeta(c),
              onvifSet),
    local srcRtsp =
      std.map(function(c) common.mk_rtsp(common.mk_cam_name(cid, c.id), c.url) +
              (if "cred" in c then {auth: conf.creds[c.creds]} else {}) + camOrigMeta(c),
              rtspSet),
    sources: srcOnvif + srcRtsp,
    local recPermanent = std.filter(function (s) "rec" in s.__orig && s.__orig.rec == "permanent", self.sources),
    local recMotion = std.filter(function (s) "rec" in s.__orig && s.__orig.rec == "motion", self.sources),
    record: if std.all(std.map(function(s) s.__orig.rec == "none", self.sources)) then null else { motion: recMotion, permanent: recPermanent },
    webrtc: true,
    rtspsrv: false,
    websrv: true,
    wamp: false,
    metrics: true,
    events: "sqlite"
  }
}
