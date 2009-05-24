require 'logger'
require 'lib/crc32'
require 'lib/em-proxy' 
require 'lib/request'  
require 'lib/proxy_endpoint'
require 'memcached'
require 'httparty'                   
require 'zlib'

$cache = Memcached.new('localhost:11211')
$logger = Logger.new(STDOUT)               

class Resolver                    
  Interesting = /^\/proxy/   
    
  def self.dispatch(request)                                 
    if Interesting.match(request.path)                   
      
      proxy = ProxyEndpoint.new(request.request_uri)
      
      if proxy.available?  
        $logger.info "  * Contacting endpoint at #{proxy.endpoint_location}"
      
        proxy.forward(request)
        
        cache_key = "proxy-content/#{crc32(proxy.content)}"
        
        $cache.set cache_key, proxy.content       
        
        $logger.info "  * Endpoint returned Status:#{proxy.status}, #{proxy.content.length}b content"
        
        request.add_header('X-Proxy-Content', cache_key)
        request.add_header('X-Proxy-Status', proxy.status)
      else
        $logger.info "  * No endpoint found for #{proxy.endpoint_location}"
      end      
    end
  end
    
end


Proxy.start(:host => "0.0.0.0", :port => 3005) do |conn|
  conn.server :shopify, :host => "127.0.0.1",  :port => 2222

  conn.on_data do |data|   
    
    request = Request.new(data)    

    $logger.info "*** Request for #{request.request_uri}"
    
    Resolver.dispatch(request)    
    
    $logger.info "*** Forwarding to backend"

    p request.data
    request.data

  end
 
  conn.on_response do |backend, resp|
    resp
  end
end