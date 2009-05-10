require 'zlib'
require 'net/http'
require 'net/https'

class ProxyEndpoint     
  attr_accessor :uri, :content, :status, :proxy_root
  
  class Error < StandardError; end  
  class ConnectionError < Error; end
  class TimeoutError < Error; end
  class MethodNotAllowed < Error; end
  
  ProxyRoot = /https?\:\/\/.*?\/[\w_-]+\/[\w_-]+/
    
  def initialize(uri)
    @uri = uri                                     
    @proxy_root = uri.scan(ProxyRoot).flatten.first

    if @proxy_root.nil?
      raise Error, "could not find proxy root for url"
    end
  end
  
  def endpoint_location    
    @endpoint_location ||= $cache.get("proxy/#{proxy_root}")
  end              
  
  def available?
    !endpoint_location.nil?
  end
  
  def forward(request) 
    uri = URI.parse(endpoint_location)
    
    http = Net::HTTP.new(uri.host, uri.port) 
    http.open_timeout = 10
    http.read_timeout = 10

    if http.use_ssl = (uri.scheme == 'https')
      http.verify_mode    = OpenSSL::SSL::VERIFY_PEER
    end              

    #headers = { 'X-Shopify-Proxied-For' => shop.local_domain.host }
    headers = {}
    
    response = case request.method
    when 'GET'
      http.get(uri.request_uri, headers)
    when 'POST'
      data = request.raw_content
      headers['Content-Type']   = request.content_type || 'application/html'
      headers['Content-Length'] = data.length.to_s
      http.post(uri.request_uri, data, headers)
    else                     
      raise MethodNotAllowed.new(api_client)
    end        

    if (200..299).include?(response.code.to_i)
      response.body
    else
      raise RequestError.new(api_client, response)
    end  
    
    self.content = response.body    
    self.status  = response.code    

  rescue EOFError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
    raise ConnectionError.new(api_client)
  rescue Timeout::Error, Errno::ETIMEDOUT => e
    raise TimeoutError.new(api_client)    
  end    
end


