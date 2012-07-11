require 'patron'
require 'uri'

%w(experiment request request_manager screen).each do |file|
  require_relative "front_end_loader/#{file}"
end

module FrontEndLoader
  VERSION = '0.2.2'
end
