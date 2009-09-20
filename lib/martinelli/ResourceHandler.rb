
# requires
require 'rubygems'
require 'mongrel'

module Martinelli

  # DeviceResourceHandler
  #
  class ResourceHandler < Mongrel::HttpHandler

    REST_OVER_GET_ALLOWED = true

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
    JSONP = "jsonp".freeze
    CSV = "csv".freeze
    XHTML = "xhtml".freeze
    TEXT = "text".freeze

    # Parses REQUEST_PATH and return Array of path hierarchy
    def self.request_path_parse(request_path)
      a = request_path.split("/") # should probably use heavy regex instead
      a[0] = "/" # split will always return at least empty string due to "/"
      return a
    end

    # Designed to be called at start of process()
    # * Checks that request method is valid. If it's not assigned then it uses GET
    # * Assigns query string parameters to array @params
    # * Parses request path into array @parsed_request_path
    # * Checks data type requested. If it's not assigned then it uses text
    #--
    # FIXME: Should be private
    def preprocess(request, response)
      
      @request_method = request.params[Mongrel::Const::REQUEST_METHOD] || Mongrel::Const::GET
      
      #if (REST_OVER_GET_ALLOWED && @request_method === GET && request.params["method"] != nil) then
      #  @request_method = request.params["method"]
      #end
      
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
      
      @params = Mongrel::HttpRequest.query_parse(request.params["QUERY_STRING"])
      @parsed_request_path = ResourceHandler::request_path_parse(request.params["REQUEST_PATH"])
      @data_type = @params["format"] || TEXT

      
      # FIXME: this shouldn't be handled here
      # JSON default if format undefined
      @content_type = "text/plain"
      case @data_type
      when TEXT
        #
      when JSON
        #@content_type = "application/json"
      when JSONP
        # hmm
      when XML
        #@content_type = "application/xml"
      when CSV
        #@content_type = "text/csv"
      #when XHTML # not supported yet
      #  content_type = "application/xhtml+xml"
      else
        raise "Hell"
      end

      # this is bad. very bad.
      # request body should be specified ahead of time
      # right now it's equivalent to QUERY_STRING
      # but it may be JSON or XML
      #@body = Mongrel::HttpRequest.query_parse(request.body.string)
      @body =  request.body.string

      return request, response # do we even need to be sending these this back? they weren't changed
    end
  end
end