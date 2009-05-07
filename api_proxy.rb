
require 'lib/em-proxy'
require 'memcached'
require 'httparty'                   
require 'zlib'

$cache = Memcached.new('localhost:11211')

class Request
  Command = /(GET|POST|PUT|HEAD|DELETE) (\/\S*)\r\n/
  Host = /^(Host\: .*\r\n)/
  
  attr_accessor :data, :method, :path

  def initialize(data)
    @data = data    
    _, @method, @path = *Command.scan(data)
  end            
  
  def add_header(name, value)
    @data.sub(Host, "#{$1}#{name}: #{value}\r\n")
  end         
end                                      

def Proxy
  def initialize(url)
    @body = url
  end
  
  def forward_request
    Net::HTTP.
  end
  
  def crc32
    Zlib.crc32(@body, 0)
  end
end

                              
                              # /proxy/*

Proxy.start(:host => "0.0.0.0", :port => 3005) do |conn|
  conn.server :shopify, :host => "127.0.0.1", :port => 80

  # put <pri> <delay> <ttr> <bytes>\r\n

  conn.on_data do |data|       
    request = Request.new(data)
    
    if request.path =~ /^\/proxy/
      proxy = Proxy.new(request.request_uri)
      
      if proxy.available?  
                      
        proxy.forward_request
                                                             
        $cache.set proxy.cache_key, proxy.content
                
        request.add_header('X-Proxy-Status', proxy.status)
        request.add_header('X-Proxy-Content', proxy.cache_key)
        request.data               
      end
      
      request.data
    end
  end
 
  conn.on_response do |backend, resp|
    resp
  end
end