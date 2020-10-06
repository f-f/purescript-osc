var Osc = require('osc-js');

exports._connect = function (address, port) {
  return function () {
    return new Osc({
      plugin: new Osc.DatagramPlugin({ send: { port: port, host: address } })
    });
  };
};

exports._listen = function (address, port) {
  return function () {
    var server = new Osc({
      plugin: new Osc.DatagramPlugin({ open: { port: port, host: address } })
    });
    server.open();
    return server;
  };
};

// note: timestamp here is in milliseconds
exports._send = function(client, timestamp, message) {
  return function () {
    var oscMessage = new Osc.Message(message.path, ...message.msg);
    var date = new Date(timestamp);
    var oscBundle = new Osc.Bundle([oscMessage], date);
    client.send(oscBundle);
  };
};

var getPSType = function (s) {
  switch (s) {
    case 's': return 'OscString';
    case 'i': return 'OscInt';
    case 'f': return 'OscFloat';
  };
};

exports._on = function(server, messageCallback) {
  return function () {
    server.on('*', function (msg) {
      console.log(msg)
      var values = msg.args.map(function(val, i) {
        return { type: getPSType(msg.types[i+1]), value: val }
      });
      var msgObj = { path: msg.address, msg: values };
      messageCallback(msgObj)();
    });
  };
};

exports._closeClient = function(client) {
  return function () {
    client.close();
  };
};

exports._closeServer = function(server) {
  return function () {
    server.close();
  };
};
