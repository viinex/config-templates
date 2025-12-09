local constants = {
  isWindows: std.extVar('OSName')=='Msys', //false,

  tls: {
    path: if constants.isWindows then "c:/Program Files/Viinex/etc/ssl/private/sample-" else "/etc/viinex.conf.d/",
    key: self.path + "privkey.pem",
    certificate: self.path + "certificate.pem"
  },

  storageRoot: if constants.isWindows then "c:/viinexvideo" else "/vnxdata",

  docker: std.extVar('deploy')=='docker',
  
  rtspsrvPort: if self.docker then "$(env@json.RTSP_PORT)" else 554,
  webserverPort: if self.docker then "$(env@json.HTTP_PORT)" else 8880,

  refDeployParam(name): if self.docker
                        then "$(env." + name + ")"
                        else "$(var." + name + ")",
};

constants
