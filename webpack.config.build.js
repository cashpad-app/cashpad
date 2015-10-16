var path = require('path');
var webpack = require('webpack');
var webpackBase = require('./webpack.base');
var assign = require('object-assign');

var paths = {
  SRC: path.resolve(__dirname, './src')
};

module.exports = assign(webpackBase, {

  entry: paths.SRC + '/app.js',

  plugins: [
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify('production')
    }),
    new webpack.optimize.UglifyJsPlugin({
      compress: {
        warnings: false
      }
    })
  ]

});
