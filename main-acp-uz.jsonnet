{
  local conf = std.parseYaml(std.extVar('confYaml')),
  local def = std.parseYaml(std.extVar('def')),
  local cid = std.format("a%s", conf.acpAreaId),
  
  local names = {
    modbus: "modbus_" + cid,
    cam1: "cam_" + cid + "_1",
    cam2: "cam_" + cid + "_2",
    recctl1: self.cam1 + "_recctl",
    recctl2: self.cam2 + "_recctl",
    rend1: self.cam1 + "_rend",
    rend2: self.cam2 + "_rend",
    alpr1: "alpr_" + cid + "_1",
    alpr2: "alpr_" + cid + "_2",
    script: "script_" + cid,
    storage: "stor_" + cid,
    webrtc: "webrtc_" + cid,
    wamp: "wamp_" + cid,
    db: "db_" + cid,
  },

  "objects": [
    {
      "type": "modbus",
      "name": names.modbus,
      "host": def.modbusAddress,
      "unit_id": 1,
      "rem period": 1000,
      "rem device": "/dev/ttyUSB0",
      "rem slave_id": 1,
      "baudrate": 19200,
      "bits_per_word": 8,
      "stopbits": "one",
      "parity": "even",
      "flow_control": false,
      "timemout": 10,
      "inputs": {"start": 0, "count": 4},
      "outputs": {"start": 0, "count": 4}
    },
    {
      "type": "rtsp",
      "name": names.cam1,
      "host": def.cam1Address,
      "auth": [def.camLogin, def.camPassword],
      "enable": ["video"],
      "transport": ["tcp"]
    },
    {
      "type": "rtsp",
      "name": names.cam2,
      "host": def.cam2Address,
      "auth": [def.camLogin, def.camPassword],
      "enable": ["video"],
      "transport": ["tcp"]
    },

    {
      "type": "recctl",
      "name": names.recctl1,
      "prerecord": 15,
      "postrecord": 15
    },
    {
      "type": "recctl",
      "name": names.recctl2,
      "prerecord": 15,
      "postrecord": 15
    },

    {
      "type": "renderer",
      "name": names.rend1,
      "share": true,
      "layout": {
        "size": [0, 0],
        "viewports": [
          {
            "input": 0,
            "dst": [0,0,1,1]
          }
        ]
      },
      "encoder": {
        "type": "cpu",
        "quality": "small_size",
        "profile": "baseline",
        "preset": "ultrafast",
        "dynamic": true
      }
    },
    {
      "type": "renderer",
      "name": names.rend2,
      "share": true,
      "layout": {
        "size": [0, 0],
        "viewports": [
          {
            "input": 0,
            "dst": [0,0,1,1]
          }
        ]
      },
      "encoder": {
        "type": "cpu",
        "quality": "small_size",
        "profile": "baseline",
        "preset": "ultrafast",
        "dynamic": true
      }
    },

    {
      "type": "process",
      "name": names.alpr1,
      "executable": "/usr/lib/vnxlpr/vit-alpr",
      "rem executable": "/home/pi/alpr-emu.sh",
      "cwd": "/",
      "env": [
        ["LD_LIBRARY_PATH", "/opt/vodi/lib"],
        ["VPW_DNN_DEVICES", "[pd-2:npu+ncaps4,lsd:npu+ncaps2,ssd:npu+ncaps2,cd:npu+ncaps4]"],
        ["VPW_PLATECANDS_METHODS", "4"],
        ["VPW_PLATECANDS_BY_DNN_VARIATE", "0"],
        ["VPW_PLATE_ANALYSE_METHODS", "32"],
        ["KMP_AFFINITY", "granularity=fine,compact,1,0"],
        ["OMP_NUM_THREADS", "1"]
      ],
      "restart": true,
      "timeout": 10,
      "init": {
        "video_source": names.rend1,
        "AORP_MODULE_PATH":"/opt/vodi/libexec/aorp/modules",
        "thread_max": 4,
        "country_code": 860,
        "modules":["vpwi-uz"],
        "dynamic_output_framecount": 15,
        "dynamic_output_timeout": 3,
        "result_filter_mask": 13
      }
    },
    {
      "type": "process",
      "name": names.alpr2,
      "executable": "/usr/lib/vnxlpr/vit-alpr",
      "rem executable": "/home/pi/alpr-emu.sh",
      "cwd": "/",
      "env": [
        ["LD_LIBRARY_PATH", "/opt/vodi/lib"],
        ["VPW_DNN_DEVICES", "[pd-2:npu+ncaps4,lsd:npu+ncaps2,ssd:npu+ncaps2,cd:npu+ncaps4]"],
        ["VPW_PLATECANDS_METHODS", "4"],
        ["VPW_PLATECANDS_BY_DNN_VARIATE", "0"],
        ["VPW_PLATE_ANALYSE_METHODS", "32"],
        ["KMP_AFFINITY", "granularity=fine,compact,1,0"],
        ["OMP_NUM_THREADS", "1"]
      ],
      "restart": true,
      "timeout": 10,
      "init": {
        "video_source": names.rend2,
        "AORP_MODULE_PATH":"/opt/vodi/libexec/aorp/modules",
        "thread_max": 4,
        "country_code": 860,
        "modules":["vpwi-uz"],
        "dynamic_output_framecount": 15,
        "dynamic_output_timeout": 3,
        "result_filter_mask": 13
      }
    },

    {
      "type": "script",
      "name": names.script,
      "meta": {
        "type": "AutoCheckpoint",
        "name": std.format("Checkpoint %s", conf.acpAreaId),
        "desc": std.format("Checkpoint at area id %s", conf.acpAreaId),
        "directions": [
          {
            "name": std.format("Area %s Entrance", cid),
            "video_source": names.cam1,
            "io_type": 1
          },
          {
            "name": std.format("Area %s Exit", cid),
            "video_source": names.cam2,
            "io_type": 2
          }
        ]
      },
      "inline": "require('vnx-script-instance')('checkpoint-uz');",
      "init": {
        "directions": [
          {
            "name": std.format("Checkpoint %s Entrance", conf.acpAreaId),
            "video_source": names.cam1,
            "alpr": names.alpr1,
            "recctl": [names.recctl1],
            "io_type": 1
          },
          {
            "name": std.format("Checkpoint %s Exit", conf.acpAreaId),
            "video_source": names.cam2,
            "alpr": names.alpr2,
            "recctl": [names.recctl2],
            "io_type": 2
          }                    
        ],
        "acs": {
          "endpoint": def.acsEndpointUri,
          "auth": [def.acsEndpointLogin, def.acsEndpointPassword],
          "area_id": conf.acpAreaId,
          "num_retries": 3,
          "ignore_result": false
        },
        "actuator": {
          "name": names.modbus,
          "output_pin": "0",
          "input_pin": "0",
          "open_state": true,
          "close_timeout": 10,
          "expect_feedback": true
        }
      }
    },
    {
      "type": "script",
      "name": "acs_emu",
      "inline": "require('vnx-script-instance')('checkpoint-uz-acs-emulation');"
    },        

    {
      "type": "storage.local",
      "name": names.storage,
      "folder": "/var/vnxvideo",
      "filesize": 16,
      "limits": {
        "max_size_gb": 256,
        "keep_free_percents": 5
      }
    },
    {
      "type": "postgres",
      "name": names.db,
      "connect": {
        "host": "localhost",
        "port": 5432,
        "database": "vnx",
        "user": "vnx",
        "password": "vnx"
      },
      "connections": 4,
      "events": {
        "store": true,
        "writers": 1,
        "limits": {
          "max_depth_abs_hours": 720,
          "storage_aware": false
        }
      },
      "acls": false,
      "kvstore": {
        "enable": false
      }
    },
    {
      "type": "webserver",
      "name": "web0",
      "port": 8880,
      "staticpath": "/usr/share/viinex/web/browser/en"
    },
    {
      "type": "metrics",
      "name": "metrics",
      "labels": [["app", "acp"], ["cluster", cid]]
    },
    {
      "type": "wamp",
      "name": names.wamp,
      "realm": "$(var.REALM)",
      "auth": {
        "method": "cryptosign",
        "role": "$(var.AUTHID)",
        "secret": "$(var.PRIVATE_KEY)"
      },
      "url": "$(var.URL)",
      "app": "com.viinex.api",
      "prefix": cid,
      "clusters": false
    },
    {
      "type": "webrtc",
      "name": names.webrtc,
      "stunsrv": 3478,
      "ice_servers": [
        {
          "urls": "stun:" + def.turnAddress
        },
        {
          "urls": "turn:"  + def.turnAddress,
          "username": def.turnLogin,
          "credential": def.turnPassword
        }
      ],
      "meta": {
        "ice_servers": [
          {
            "urls": "stun:" + def.turnAddressClient
          },
          {
            "urls": "turn:"  + def.turnAddressClient,
            "username": def.turnLogin,
            "credential": def.turnPassword
          }
        ],
        "stunsrv": 3478
      },
      "key": "/etc/viinex.conf.d/privkey.pem",
      "certificate": "/etc/viinex.conf.d/certificate.pem",
      "events": true                
    }
  ],
  "links": [
    [["web0",names.webrtc,names.wamp], [names.cam1, names.cam2, names.storage]],
    
    [names.cam1, names.rend1],
    [names.cam2, names.rend2],

    [names.recctl1, [names.cam1, names.storage]],
    [names.recctl2, [names.cam2, names.storage]],

    [[names.alpr1, names.alpr2, names.modbus, names.cam1, names.cam2, names.recctl1, names.recctl2], names.script],
    [["web0",names.db, names.wamp], names.script],

    ["web0","acs_emu"],

    [["web0", names.wamp],"metrics"],
    ["metrics", [names.modbus, names.cam1, names.cam2, names.db, names.storage, names.rend1, names.rend2]],
    
    [["web0", names.wamp], [names.webrtc, names.db, names.modbus]]
  ]
}
