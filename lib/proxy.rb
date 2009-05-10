require 'zlib'
require 'net/http'
require 'net/https'

def Proxy     
  attr_accessor :content, :status
  
  class Error < StandardError
  end
  
  class ConnectionError < Error; end
  class TimeoutError < Error; end
  class MethodNotAllowed < Error; end
    
  def initialize(uri)
    @uri = uri
  end
  
  def proxy_request_url
    @proxy_request_url ||= begin      
                                                 
      path = @uri.path.split('/')[0..1].join('/')
      
      "#{@uri.protocol}://#{@uri.hostname}/#{path}"
    end
  end
  
  def endpoint    
    @endpoint ||= $cache.get("proxy/#{proxy_root_url}")
  end              
  
  def available?
    endpoint
  end
  
  def forward_request 
    @endpoint = proxy_root_url
    
    http = Net::HTTP.new(@uri.host, @uri.port) 
    http.open_timeout = 10
    http.read_timeout = 10

    if http.use_ssl = (@uri.scheme == 'https')
      http.verify_mode    = OpenSSL::SSL::VERIFY_PEER
    end              

    headers = { 'X-Shopify-Proxied-For' => shop.local_domain.host }
    
    response = case request.method
    when :get
      http.get(@uri.request_uri, headers)
    when :post        
      data = request.raw_post
      headers['Content-Type']   = request.content_type.to_s
      headers['Content-Length'] = data.length.to_s
      http.post(@uri.request_uri, data, headers)
    else                     
      raise MethodNotAllowed.new(api_client)
    end        

    if (200..299).include?(response.code.to_i)
      response.body
    else
      raise RequestError.new(api_client, response)
    end  
    
    self.content = response.body    
    self.status  = response.status    

  rescue EOFError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
    raise ConnectionError.new(api_client)
  rescue Timeout::Error, Errno::ETIMEDOUT => e
    raise TimeoutError.new(api_client)    
  end
  
  def crc32
    Zlib.crc32(@body, 0)
  end
end


