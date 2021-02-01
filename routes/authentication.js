const express = require('express');
const router = new express.Router();
const authentication = require('../controllers/authentication');



router.post('/login', async (req, res, next) => {

    const options = {
        body: req.body
    };

    try {
        const result = await authentication.postLogin(options);
        res.status(result.status || 200).send(result.data);
    } catch (err) {
        next(err);
    }

});

router.post('/refresh', async (req, res, next) => {

    const options = {
        body: req.body
    };

    try {
        const result = await authentication.postRefresh(options);
        res.status(result.status || 200).send(result.data);
    } catch (err) {
        next(err);
    }

});

module.exports = router;