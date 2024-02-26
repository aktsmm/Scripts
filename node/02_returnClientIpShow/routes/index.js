var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function (req, res, next) {
  const ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
  res.render('index', { title: `IPアドレス確認くん`, ip: ip});
});

module.exports = router;