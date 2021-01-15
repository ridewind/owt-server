#!/usr/bin/env node
// Copyright (C) <2019> Intel Corporation
//
// SPDX-License-Identifier: Apache-2.0
'use strict';

(function () {
  var cipher = require('./cipher');
  var dirName = !process.pkg ? __dirname : require('path').dirname(process.execPath);
  var keystore = require('path').resolve(dirName, 'cert/' + cipher.kstore);
  cipher.lock(cipher.k, (process.argv[2] || ''), keystore, function cb(err) {
    console.log(err || 'done!');
  });
})();
