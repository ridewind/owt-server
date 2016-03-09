/*global exports, require*/
'use strict';
var serviceRegistry = require('./../mdb/serviceRegistry');
var cloudHandler = require('../cloudHandler');

var logger = require('./../logger').logger;

// Logger
var log = logger.getLogger('UsersResource');

var currentService;
var currentRoom;

/*
 * Gets the service and the room for the proccess of the request.
 */
var doInit = function (roomId, callback) {
    currentService = require('./../auth/nuveAuthenticator').service;
    serviceRegistry.getRoomForService(roomId, currentService, function (room) {
        currentRoom = room;
        callback();
    });
};

/*
 * Get Users. Represent a list of users of a determined room. This is consulted to cloudHandler.
 */
exports.getList = function (req, res) {
    doInit(req.params.room, function () {
        if (currentService === undefined) {
            res.status(404).send('Service not found');
            return;
        } else if (currentRoom === undefined) {
            log.info('Room ', req.params.room, ' not found');
            res.status(404).send('Room not found');
            return;
        }

        log.info('Representing users for room ', currentRoom._id, 'and service', currentService._id);
        cloudHandler.getUsersInRoom (currentRoom._id, function (users) {
            if (users === 'error') {
                res.send([]);
                return;
            }
            res.send(users);
        });
    });
};