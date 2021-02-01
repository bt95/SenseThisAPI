'use strict'

const fs = require('fs');
const path = require('path');
const Sequelize = require('sequelize');
const basename = path.basename(__filename);
const db = {};

var masterDB = new Sequelize('sensethis', process.env.MASTER_DB_USERNAME, process.env.MASTER_DB_PASSWORD, {
    host: process.env.MASTER_DB_ADDRESS,
    dialect: 'postgres',
    port: process.env.MASTER_DB_PORT,
  });

masterDB.authenticate()
  .then(function(err) {
      console.log('Successfully connected to the MASTER DB!');
  })
  .catch(function(err) {
      console.error('Unable to connect to the MASTER DB!', err);
  })

var slaveDB = new Sequelize('sensethis', process.env.SLAVE_DB_USERNAME, process.env.SLAVE_DB_PASSWORD, {
    host: process.env.SLAVE_DB_ADDRESS,
    dialect: 'postgres',
    port: process.env.SLAVE_DB_PORT,
  });

slaveDB.authenticate()
  .then(function(err) {
      console.log('Successfully connected to the SLAVE DB!');
  })
  .catch(function(err) {
      console.error('Unable to connect to the SLAVE DB!', err);
  })

  var localDB = new Sequelize('sensethis', process.env.LOCAL_DB_USERNAME, process.env.LOCAL_DB_PASSWORD, {
    host: process.env.LOCAL_DB_ADDRESS,
    dialect: 'postgres',
    port: process.env.LOCAL_DB_PORT,
  });

localDB.authenticate()
  .then(function(err) {
      console.log('Successfully connected to the LOCAL DB!');
  })
  .catch(function(err) {
      console.error('Unable to connect to the LOCAL DB!', err);
  })




fs.readdirSync(__dirname).filter(file => {
      return (file.indexOf('.') !== 0) && (file !== basename) && (file.slice(-3) === '.js');
    })
    .forEach(file => {
      const model = require(path.join(__dirname, file))(masterDB, Sequelize.DataTypes);
      db[model.name] = model;
    });
  
  Object.keys(db).forEach(modelName => {
    if (db[modelName].associate) {
      db[modelName].associate(db);
    }
  });
  
db.masterDB = masterDB;
db.slaveDB = slaveDB;
db.localDB = localDB;
db.Sequelize = Sequelize;
  
module.exports = db;