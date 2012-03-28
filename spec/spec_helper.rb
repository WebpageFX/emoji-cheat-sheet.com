require 'rubygems'
require 'bundler'
Bundler.require
require 'minitest/autorun'

require 'mocha'

HTML_SOURCE = <<-HTML_STRING
  <!DOCTYPE html>
  <img src="/graphics/emojis/angry.png">
  <img src="/graphics/logo.png">
  <img src="/graphics/emojis/cloud.png">
HTML_STRING
