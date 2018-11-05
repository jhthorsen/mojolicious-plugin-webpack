module.exports = function(config) {
  config.entry = {
    "add": config.assetsDir + '/js/process-js-add.js',
    "subtract": config.assetsDir + '/js/process-js-subtract.js'
  };
};
