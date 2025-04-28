local common = import 'common.jsonnet';

local nvr = import 'nvr-app.jsonnet';

local cid = std.extVar('CID');

local conf = std.parseYaml(std.extVar('confYaml'));

common.build_viinex_config(cid, nvr.make_app(cid, conf))
