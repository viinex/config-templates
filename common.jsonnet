local common = {
  local constants = import 'constants.jsonnet',

  mk_webrtc: function (name) {
    type: "webrtc",
    name: "webrtc_" + name,
    stunsrv: 3478,
    ice_servers: [
      {
        "urls": "stun:demo.viinex.com:3478"
      }
    ],
    meta: {
      "ice_servers": [
        {
          "urls": "stun:demo.viinex.com:3478"
        }
      ],
      "stunsrv": 3478
    },
    key: constants.tls.key,
    certificate: constants.tls.certificate,
    events: true,
  },

  mk_mediafile: function (name, path) {
    type: "mediasourceplugin",
    name: name,
    dynamic: false,
    library: if constants.isWindows then "vnxvideo.dll" else "libvnxvideo.so",
    factory : "create_file_media_source",
    init : {
      file: path
    }
  },

  local parseRtspUrl (u) =
    local p = {
      at: std.findSubstr("@", u),
      semicolon: std.findSubstr(":", u),
      rtsp: std.startsWith(u, "rtsp://"),
    }; if !p.rtsp
       then error "RTSP URL should start with rtsp://, was given: "+u
       else {
         url: if std.length(p.at) > 0 then "rtsp://"+std.substr(u, p.at[0]+1, std.length(u)) else u,
         auth: if std.length(p.at) > 0
               then [std.substr(u, 7, p.semicolon[1]-7),
                     std.substr(u, p.semicolon[1]+1, p.at[0]-p.semicolon[1]-1)]
               else null
       },

  local cleanupOrig(o) = o + { __orig: null }, //std.objectRemoveKey(o, "__orig"),
  
  mk_cam_name: function (clusterId, camId) "cam_" + clusterId + "_" + camId,
  
  mk_rtsp: function (name, url) {
    type: "rtsp",
    name: name,
    local urlparsed = parseRtspUrl(url),
    url: urlparsed.url,
    auth: urlparsed.auth,
    transport: ["tcp"]
  },

  mk_onvif: function (name, addr, auth, profile) {
    type: "onvif",
    name: name,
    host: addr,
    auth: auth,
    profile: profile,
    enable: ["video", "audio", "events", "ptz"],
    rtpstats: true,
    transport: ["udp"],
  },

  mk_recctl: function(name, prerecord, postrecord) {
    type: "recctl",
    name: "recctl_" + name,
    prerecord: prerecord,
    postrecord: postrecord
  },

  mk_rule_motion: function(name) {
    type: "rule",
    name: "rule_" + name,
    filter: ["MotionAlarm"]
  },

  mk_webserver: function (name) {
    type: "webserver",
    name: "web_" + name,
    port: 8880,
    staticpath: if constants.isWindows then "c:/Program Files/Viinex/share/web" else "/usr/share/viinex/web/browser/en",
    "rem tls":{
      key: constants.tls.key,
      certificate: constants.tls.certificate
    },
    cors: "*",
    clusters: true,
  },

  mk_storage: function (name) {
    type: "storage",
    name: "stor_" + name,
    folder: constants.storageRoot + "/" + self.name,
    filesize: 16,
    limits: {
      keep_free_percents: 20
    }
  },

  mk_rtspsrv: function (name, port) {
    type: "rtspsrv",
    name: "rtspsrv_" + name,
    port: port
  },

  mk_metrics: function (cid) {
    type: "metrics",
    name: "metrics",
    labels: [['cluster', cid]],
  },

  mk_db_sqlite: function (name) {
    type: "sqlite",
    name: "db_" + name,
    connect: { database: constants.storageRoot + "/" + "db_" + name + ".sqlite3" },
    events: {
      store: true,
      writers: 1,
      limits: {
        storage_aware: true
      },
    },
  },

  namesOf: function (objects) std.map(function(x) x.name, objects),

  default_app: function () {
    sources: [],
    record: null,
    webrtc: true,
    rtspsrv: false,
    websrv: true,
    wamp: false,
    metrics: true
  },

  build_viinex_config: function (cid, app) {
    local mediaSources = app.sources,
    local storages = if app.record != null then [common.mk_storage(cid+"_1")] else [],
    local recctls = if app.record != null then [common.mk_recctl(s.__orig.id, 5, 5) for s in app.record.motion],
    local rules = if app.record != null then [common.mk_rule_motion(s.__orig.id) for s in app.record.motion],
    local linksRecctlRule = if app.record != null
                            then [[recctls[i].name, rules[i].name, common.mk_cam_name(cid, app.record.motion[i].__orig.id)]
                                  for i in std.range(0, std.length(app.record.motion)-1)]
                            else [],
    local linksRecPermanent = if app.record != null
                              then [[common.namesOf(storages), common.namesOf(app.record.permanent)]]
                              else [],
    local webrtcs = if app.webrtc then [common.mk_webrtc(cid+"_0")] else [],
    local rtspsrvs = if app.rtspsrv then [common.mk_rtspsrv(cid+"_0", 1554)] else [],
    local websrvs = if app.websrv then [common.mk_webserver(cid+"_0")] else [],
    local metrics = if app.metrics then [common.mk_metrics(cid)] else [],
    local databases = if app.events == "sqlite"
                      then [common.mk_db_sqlite(cid+"_1")]
                      else [],
    local wamps = [],
    local publishers = webrtcs + rtspsrvs + websrvs + wamps,
    local mediaPublishers = webrtcs + rtspsrvs + websrvs,
    local apiPublishers = websrvs + wamps,
    local apiProviders = mediaSources + storages + webrtcs + metrics + databases,
    local metricsProviders = mediaSources + storages,
    local eventProducers = mediaSources + storages,
    
    objects: std.map(cleanupOrig, mediaSources + storages + publishers + metrics + recctls + rules + databases),
    links: [
      [common.namesOf(mediaSources), common.namesOf(mediaPublishers)],
      [common.namesOf(mediaPublishers), common.namesOf(storages)],
      [common.namesOf(apiPublishers), common.namesOf(apiProviders)],
      [common.namesOf(metrics), common.namesOf(metricsProviders)],
      [common.namesOf(recctls), common.namesOf(storages)],
      [common.namesOf(databases), common.namesOf(eventProducers)]
    ] + linksRecctlRule + linksRecPermanent
  },

};

common
