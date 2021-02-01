'use strict';

module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('users', {
    id: { 
        type: DataTypes.INTEGER,
        primaryKey: true
    },
    description: {
        type: DataTypes.TEXT
    },
    display_in_metric: {
        type: DataTypes.BOOLEAN
    },
    email: {
        type: DataTypes.TEXT
    },
    first_name: {
        type: DataTypes.TEXT
    },
    is_active: {
        type: DataTypes.BOOLEAN
    },
    is_verified: {
        type: DataTypes.BOOLEAN
    },
    last_name: {
        type: DataTypes.TEXT
    },
    password: {
        type: DataTypes.TEXT
    },
    timezone: {
        type: DataTypes.STRING
    },
    translate_language_id: {
        type: DataTypes.INTEGER
    },
    username: {
        type: DataTypes.STRING
    },
    user_type_id: {
        type: DataTypes.INTEGER
    },
    verification_code: {
        type: DataTypes.TEXT
    },
    verification_code_expiration_date_utc: {
        type: DataTypes.DATE
    },
    createdAt: {
      allowNull: false,
      field: "created_at",
      type: DataTypes.DATE,
    },
    updatedAt: {
      allowNull: false,
      field: "updated_at",
      type: DataTypes.DATE,
    }
  }, {timestamps: false});
  User.associate = function(models) {
  };
  return User;
};