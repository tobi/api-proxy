
require 'lib/em-proxy' 
require 'lib/request'  
require 'lib/proxy_endpoint'
require 'memcached'
require 'httparty'                   
require 'zlib'

$cache = Memcached.new('localhost:11211') 


Proxy.start(:host => "0.0.0.0", :port => 3005) do |conn|
  conn.server :shopify, :host => "127.0.0.1",  :port => 80

  conn.on_data do |data|       
    
    request = Request.new(data)   
    
    if request.path =~ /^\/proxy/   
                                             
      proxy = ProxyEndpoint.new(request.request_uri)
      
      if proxy.available?  
                      
        proxy.forward(request)
        
        cache_key = "proxy-content/#{proxy.content.crc32}"
                                                             
        $cache.set cache_key, proxy.content
                
        request.add_header('X-Proxy-Content', cache_key)
        request.add_header('X-Proxy-Status', proxy.status)
        request.data               
      end
      
      request.data
    else
      request.data
    end
  end
 
  conn.on_response do |backend, resp|
    resp
  end
end