require 'rubygems'
require 'sinatra'                                        
require 'memcached'

$cache = Memcached.new('localhost:11211')
            

# Set endpoint location for localhost address to be google.com
$cache.set 'proxy/http://localhost:3005/proxy/test', 'http://www.example.com'


get '/' do  
  "<h1>Proxy Test</h1><p>Go to <a href='/proxy/test'>Test page</a>"  
end
                               

get '/proxy/test' do   
  
  content_key = request.env['HTTP_X_PROXY_CONTENT'] ||'nothing'
  status  = request.env['HTTP_X_PROXY_STATUS'] ||'nothing'
  
  content = $cache.get(content_key)
  
  "<h1>Proxy Test</h1><p>Proxy Status: #{status}</p><p>Proxy Key: #{content_key}</p><p>Proxy Content: #{content.length} bytes</p><blockquote style='padding:10px; border: 1px solid #ccc;'>#{content}</blockquote>"  
end