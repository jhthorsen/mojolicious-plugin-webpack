// Autogenerated by Mojo::Alien::rollup 1.01
const commonjs = require('@rollup/plugin-commonjs');
const {nodeResolve} = require('@rollup/plugin-node-resolve');

module.exports = function(config) {
  config.plugins.push(nodeResolve());
  config.plugins.push(commonjs());
};
