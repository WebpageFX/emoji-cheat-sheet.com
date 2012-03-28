require 'rubygems'
require 'bundler'
Bundler.require
require 'minitest/autorun'

HTML_SOURCE = <<-html_string
  <!DOCTYPE html>
  <img src="/graphics/emojis/angry.png">
  <img src="/graphics/logo.png">
  <img src="/graphics/emojis/cloud.png">
html_string
