local common = import 'common.jsonnet';

local cid = std.extVar('CID');

local conf = std.parseYaml(std.extVar('confYaml'));

local appTypeName = if "app" in conf && "type" in conf.app
                    then conf.app.type
                    else 'nvr';

local apps = {
  nvr: import "app-nvr.jsonnet",
  alprBox: import "app-alpr-box.jsonnet",
  conntourPoc: import "app-conntour-poc.jsonnet",
};

common.build_viinex_config(cid, apps[appTypeName].make_app(cid, conf))
