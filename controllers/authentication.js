var jwt = require('jsonwebtoken');

const models = require('../models/index');
const sequelize = models.sequelize;
const User = models.users;

const accessTokenKey = process.env.ACCESS_TOKEN_SECRET;
const accessTokenKeyExpirySeconds = process.env.ACCESS_TOKEN_LIFE;
const refreshTokenKey = process.env.REFRESH_TOKEN_SECRET;
const refreshTokenKeyExpirySeconds = process.env.REFRESH_TOKEN_LIFE;

module.exports.postLogin = async (options) => {
    return new Promise((resolve, reject)=>{
        if (!options.body.username || !options.body.password)
        {
            return reject({
                status: 400,
                errorCode: 1001,
                message: 'Missing username or password'
            })
        }
        else {
            User.findOne({
                attributes: [
                    'id',
                    'is_verified'
                ],
                where: {
                    username: options.body.username,
                    is_active: true,
                    password: sequelize.fn('crypt', options.body.password, sequelize.col('password'))
                }
            }).then((user)=>{
                if(user){
                    if (user.dataValues.is_verified === false) {
                        return reject({
                            status: 400,
                            errorCode: 1003,
                            message: 'Account not verified'
                        })
                    }
                    else
                    {

                        var access_token = jwt.sign({
                            user_id: user.dataValues.id,
                            user_type_id: user.dataValues.user_type_id
                        }, accessTokenKey, {
                            algorithm: 'HS256',
                            expiresIn: accessTokenKeyExpirySeconds
                        });

                        var refresh_token = jwt.sign({
                            user_id: user.dataValues.id,
                            user_type_id: '2'
                        }, refreshTokenKey, {
                            algorithm: 'HS256',
                            expiresIn: refreshTokenKeyExpirySeconds
                        });

                        return resolve({
                            status: 200,
                            data: {
                                success: true,
                                message: 'Login Successful',
                                access_token,
                                refresh_token
                            }
                        })
                    }
                }
                else {
                    return reject({
                        status: 400,
                        errorCode: 1002,
                        message: 'Incorrect username or password'
                    })
                }
            }).catch((err)=>{
                return reject({
                    status: 400,
                    message: err.message
                })
            });
        }
    })
}

module.exports.postRefresh = async (options) => {
    return new Promise((resolve, reject)=>{
        if (!options.body.refresh_token)
        {
            return reject({
                status: 400,
                errorCode: 1004,
                message: 'Missing refresh token'
            })
        }
        else{
            jwt.verify(options.body.refresh_token, refreshTokenKey, function (err, decoded_payload) {
                if (err) {
                    return reject({
                        status: 400,
                        errorCode: 1007,
                        message: err.message
                    })
                }
                else
                {
                  if (decoded_payload.user_id === undefined) {
                    return reject({
                        status: 400,
                        errorCode: 1008,
                        message: 'Wrong refresh token payload, cannot create refresh token'
                    })
                  }
                  else{
                    User.findOne({
                      attributes: [
                        'id',
                        'is_active'
                      ],
                      where: {
                        id: decoded_payload.user_id
                      }
                    }).then(user=>{
                    if(user)
                    {
                        if (user.dataValues.is_active === false) {
                            return reject({
                                status: 400,
                                errorCode: 1006,
                                message: 'User has been deactived, cannot refresh token'
                            })
                        }
                        else {
                    
                            var access_token = jwt.sign({
                                user_id: user.dataValues.id,
                                user_type_id: user.dataValues.user_type_id
                            }, accessTokenKey, {
                                algorithm: 'HS256',
                                expiresIn: accessTokenKeyExpirySeconds
                            });
                        
                            var refresh_token = jwt.sign({
                                user_id: user.dataValues.id,
                                user_type_id: user.dataValues.user_type_id
                            }, refreshTokenKey, {
                                algorithm: 'HS256',
                                expiresIn: refreshTokenKeyExpirySeconds
                            });

                            return resolve({
                                status: 200,
                                data: {
                                    success: true,
                                    message: 'Access token successfully refreshed',
                                    access_token,
                                    refresh_token
                                }
                            })
                        }
                    }
                    else {
                        return reject({
                            status: 400,
                            errorCode: 1005,
                            message: 'User does not exist, cannot refresh token'
                        })
                      }
                    }).catch((err)=>{
                        return reject({
                            status: 400,
                            message: err.message
                        })
                    });
                  }
                }
            });
        }
    })
}


