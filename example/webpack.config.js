const isDev = process.env.NODE_ENV !== 'production';
const sassIncludePaths = (process.env.SASS_INCLUDE_PATHS || '').split(':');
const sassPrepend = '$env: ' + (process.env.WEBPACK_ENV || process.env.NODE_ENV || 'development') + ';';
const sourceMap = process.env.WEBPACK_SOURCE_MAPS || (isDev ? true : false);

const path = require('path');

const CleanWebpackPlugin = require('clean-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');

const WebpackMd5Hash = require('webpack-md5-hash');

module.exports = {
  mode: isDev ? 'development' : 'production',
  entry: {
    cool_app: './assets/js/app.js',
    example: './assets/sass/scss-example.scss'
  },
  output: {
    filename: isDev ? '[name].dev.js' : '[name].[chunkhash].js',
    path: path.resolve(__dirname, './public/asset')
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [
          MiniCssExtractPlugin.loader,
          {loader: 'css-loader', options: {sourceMap: true}}
        ]
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.s(a|c)ss$/,
        use: [
          MiniCssExtractPlugin.loader,
          {loader: 'css-loader', options: {sourceMap: sourceMap}},
          {loader: 'sass-loader', options: {data: sassPrepend, includePaths: sassIncludePaths, sourceMap: sourceMap}}
        ]
      }
    ]
  },
  optimization: {
    minimizer: [
      new UglifyJsPlugin({cache: true, parallel: true, sourceMap: sourceMap}),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  plugins: [
    new CleanWebpackPlugin('./public/asset', {}),
    new MiniCssExtractPlugin({
      filename: isDev ? '[name].dev.css' : '[name].[contenthash].css',
    }),
    new HtmlWebpackPlugin({
      // favicon: '',
      cache: true,
      filename: './demo.' + (isDev ? 'dev' : 'prod') + '.html',
      hash: false,
      inject: 'head',
      minify: false,
      showErrors: true,
      template: './assets/webpack.html',
      xhtml: false
    }),
    new WebpackMd5Hash()
  ]
};
