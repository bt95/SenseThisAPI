const express = require('express');
const swStats = require('swagger-stats');
const YAML = require('yamljs');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = YAML.load('./swagger/swagger.yaml');

const router = new express.Router();

router.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

router.use(swStats.getMiddleware({
  swaggerSpec: swaggerDocument,
  authentication: true
  // onAuthenticate: function (req, username, password) {
  //   // simple check for username and password
  //   return ((username === 'test')
  //     && (password === 'test'));
  // }
}));

module.exports = router;