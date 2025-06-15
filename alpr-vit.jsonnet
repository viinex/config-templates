{
  local defaultAlprSettings = {
    AORP_MODULE_PATH:"/opt/vodi/libexec/aorp/modules:/opt/edge/libexec/unity/aorp/modules",
    thread_max: 1,
    plate_width_min: 0.045,
  },

  alprSettings: {
    kz: {
      country_code: 398,
      modules: ["vpwi-kz"]
    },
    uz: {
      country_code: 860,
      modules: ["vpwi-uz"]
    },
  },

  local defaultAlprEnv = [
    ["LD_LIBRARY_PATH", "/opt/vodi/lib:/opt/vodi/lib/openvino:/opt/edge/lib:/opt/edge/lib/openvino"],
    ["VPW_PLATECANDS_METHODS", "4"],
    ["VPW_PLATECANDS_BY_DNN_VARIATE", "0"],
    ["VPW_PLATE_ANALYSE_METHODS", "32"],
    ["KMP_AFFINITY", "granularity=fine,compact,1,0"],
    ["OMP_NUM_THREADS", "1"],
    ["VPW_LOG_SETTINGS", "1"],
  ],
  
  dnnDevices: {
    npu: "[pd-2:npu+ncaps4,lsd:npu+ncaps2,ssd:npu+ncaps2,cd:npu+ncaps4]",
    cpu: "CPU",
    cpu2: "[pd-2:сpu,lsd:сpu,ssd:сpu,cd:сpu]",
  },

  mk_alpr_object_name (cid, id): "alpr_" + cid + "_" + id,
  
  mk_alpr_object (name, renderer_name, dnnDevices, alprSettings): {
    type: "process",
    name: name,
    executable: "/usr/lib/vnxlpr/vit-alpr",
    cwd: "/",
    env: defaultAlprEnv + [
      ["VPW_DNN_DEVICES", dnnDevices],
    ],
    restart: true,
    timeout: 10,
    init: defaultAlprSettings + alprSettings + {
      video_source: renderer_name,
    }
  },

  mk_rtms_export_script_object(name, alprName, videoSource, orig, app): {
    type: "script",
    name: name,
    inline: "require('vnx-script-instance')('rtms-kz.js');",
    init: {
      alpr_name: alprName,
      video_source: orig.camName,
      local origId = if orig.substreamOf != null then orig.substreamOf else orig.id,
      origin_id: origId,
      origin_name: if "name" in orig.meta then orig.meta.name else origId,
      origin_serial_number: if "serial_number" in orig.meta then orig.meta.serial_number else origId,
      origin_address: if "address" in orig.meta
                      then orig.meta.address
                      else (if "desc" in orig.meta
                            then orig.meta.desc
                            else origId),
      location: if "location" in orig.meta then orig.meta.location else null,
      endpoint: app.rtmsEndpoint
    }
  },


}
