local constants = {
  isWindows: std.extVar('OSName')=='Msys', //false,

  tls: {
    path: if constants.isWindows then "c:/Program Files/Viinex/etc/ssl/private/sample-" else "/etc/viinex.conf.d/",
    key: self.path + "privkey.pem",
    certificate: self.path + "certificate.pem"
  },

  storageRoot: if constants.isWindows then "c:/viinexvideo" else "/vnxdata"
};

constants
