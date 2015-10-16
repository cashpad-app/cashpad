var path = require('path');
var webpack = require('webpack');

var paths = {
  SRC: path.resolve(__dirname, './src'),
  DIST: path.resolve(__dirname, './lib')
};

module.exports = {

  output: {
    path: paths.DIST,
    filename: 'bundle.js'
  },

  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        loader: 'babel?stage=0&loose',
        include: [paths.SRC],
        exclude: /node_modules/
      }
    ],
    preLoaders: [
      {
        test: /\.jsx?$/,
        loader: 'eslint',
        include: paths.SRC + '/app.js',
        exclude: /node_modules/
      }
    ]
  }

};