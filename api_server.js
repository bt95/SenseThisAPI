const express = require('express')
const app = express()
const bodyParser = require('body-parser');
require('dotenv').config();
const cors = require("cors");

app.use(bodyParser.urlencoded({
  extended: true
}));
app.use(bodyParser.json());
app.use(bodyParser.raw());

app.use(cors());
app.options('*', cors());

const db = require('./models/index');

app.use('/v1', require('./swagger/index'));
app.use('/v1', require('./routes/authentication'));

app.get("/", (req, res) => {
  res.json({
    message: { "status": "online" }
  });
});


app.use((req, res, next) => {
  res.status(404).send({ status: 404, message: 'Not found' });
});

app.use((err, req, res, next) => {
  const status = err.status || 500;
  const msg = err.error || err.message;
  res.status(status).send({
    success: false,
    errorCode: err.errorCode || 1000,
    message: msg
  });
});

app.listen(3000, () => console.log(`App listening on port 3000!`));