
# requires
require 'rubygems'
require 'mongrel'

module Martinelli

# Arurenu8

  # DeviceResourceHandler
  #
  class ResourceHandler < Mongrel::HttpHandler

    # http 1.1 constants
    HEAD = "HEAD".freeze
    GET = "GET".freeze
    PUT = "PUT".freeze
    POST = "POST".freeze
    DELETE = "DELETE".freeze
    OPTIONS = "OPTIONS".freeze
    TRACE = "TRACE".freeze
    CONNECT = "CONNECT".freeze

    # format constants
    XML = "xml".freeze
    JSON = "json".freeze
    CSV = "csv".freeze
    XHTML = "xhtml".freeze
    TEXT = "text".freeze

    # parses REQUEST_PATH and return Array of path hierarchy
    #
    def self.request_path_parse(request_path)
      # should probably use heavy regex instead
      a = request_path.split("/")
      # split will always return at least empty string due to "/"
      a[0] = "/"
      return a
    end

    def preprocess(request, response)
      
      # GET default if REQUEST_METHOD undefined. Is REQUEST_METHOD valid?
      @request_method = request.params[Mongrel::Const::REQUEST_METHOD] || Mongrel::Const::GET
      if (@request_method != HEAD &&
          @request_method != GET &&
          @request_method != PUT &&
          @request_method != POST &&
          @request_method != DELETE &&
          @request_method != OPTIONS &&
          @request_method != TRACE &&
          @request_method != CONNECT) then
        raise "Hell" # Someone tried to access using none HTTP 1.1 request type
      end
      
      # parse QUERY_STRING into Hash - traditionally named 'params'
      @params = Mongrel::HttpRequest.query_parse(request.params["QUERY_STRING"])
    
      # JSON default if format undefined
      @format_type = @params["format"] || TEXT
      @content_type = "text/plain"
      case @format_type
      when TEXT
        #
      when JSON
        #@content_type = "application/json"
      when XML
        #@content_type = "application/xml"
      when CSV
        #@content_type = "text/csv"
      #when XHTML # not supported yet
      #  content_type = "application/xhtml+xml"
      else
        raise "Hell"
      end

      # parse REQUEST_PATH into Array
      @parsed_request_path = ResourceHandler::request_path_parse(request.params["REQUEST_PATH"])

      # this is bad. very bad.
      # request body should be specified ahead of time
      # right now it's equivalent to QUERY_STRING
      # but it may be JSON or XML
      #@body = Mongrel::HttpRequest.query_parse(request.body.string)
      @body = request.body.string

      return request, response # do we even need to be sending these this back? they weren't changed
    end
  end
end