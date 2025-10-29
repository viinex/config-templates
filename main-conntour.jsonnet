local common = import 'common.jsonnet';

// vnx-class defines CID and confYaml.
// CID is set into the name of the cluster, and confYaml
// holds the content of yaml file for that viinex cluster.
local cid = std.extVar('CID');

local conf = std.parseYaml(std.extVar('confYaml'));

local appTypeName = if "app" in conf && "type" in conf.app
                    then conf.app.type
                    else 'conntourPoc';

local apps = {
  nvr: import "app-nvr.jsonnet",
  alprBox: import "app-alpr-box.jsonnet",
  conntourPoc: import "app-conntour-poc.jsonnet",
};

common.build_viinex_config(cid, apps[appTypeName].make_app(cid, conf))
