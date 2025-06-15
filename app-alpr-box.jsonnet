(import 'app-nvr.jsonnet') + {
  
  local alpr = import 'alpr-vit.jsonnet',
  
  make_app (cid, conf):
    super.make_app (cid, conf) + {
      mk_proc_worker_name: function (cid, id)
        alpr.mk_alpr_object_name(cid, id),
      mk_proc_worker (id, rendererName, procDetails, orig):
        local dnnDevices = alpr.dnnDevices[conf.app.dnnDevices];
        local alprSettings = alpr.alprSettings[conf.app.alprSettings];
        alpr.mk_alpr_object (id, rendererName, dnnDevices, alprSettings),

      mk_proc_handler_name: function (cid, id)
        "script_" + cid + "_" + id,
      mk_proc_handler (id, workerName, procDetails, orig):
        alpr.mk_rtms_export_script_object (self.mk_proc_handler_name(cid, id),
                                           workerName, orig.camName, orig, conf.app)
    },

}
