require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'minitest/mock'
require 'minitest/spec'
require 'minitest/autorun'

HTML_SOURCE = <<-html_string
  <!DOCTYPE html>
  <html>
    <img src="/graphics/emojis/angry.png">
    <img src="/graphics/logo.png">
    <img src="/graphics/emojis/cloud.png">
  </html>
html_string

