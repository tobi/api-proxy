require 'rubygems'
require "test/unit"
require "proxy_endpoint"
require 'mocha'
          
# Mock out http calls       
require 'fakeweb'
FakeWeb.allow_net_connect = false
                      
class FakeCache < Hash  
  def get(key); self[key]; end
  def set(key,val); self[key] = val; end
end                      

FakeWeb.register_uri(:get, "http://x.shopifyapps.com/endpoint", :string => "Third party content")
FakeWeb.register_uri(:post, "http://x.shopifyapps.com/endpoint", :string => "Third party post content")
                                                                                                 

class TestProxyEndpoint < Test::Unit::TestCase
  
  def setup                                                                                          
    $cache = FakeCache.new    
  end                     
  
  def test_proxy_root    
    assert_equal 'http://127.0.0.1/a/b', ProxyEndpoint.new('http://127.0.0.1/a/b').proxy_root
    assert_equal 'http://127.0.0.1/a-b/b_c', ProxyEndpoint.new('http://127.0.0.1/a-b/b_c').proxy_root
    assert_equal 'http://www.proxyserver.com:81/path/to', ProxyEndpoint.new('http://www.proxyserver.com:81/path/to/endpoint?with=param').proxy_root
  end

  def test_invalid_proxy_root
    assert_raise ProxyEndpoint::Error do
      ProxyEndpoint.new('http://127.0.0.1/').proxy_root
    end
    
    assert_raise ProxyEndpoint::Error do
      ProxyEndpoint.new('http://127.0.0.1/?params=true').proxy_root
    end
    
    assert_raise ProxyEndpoint::Error do
      ProxyEndpoint.new('http://127.0.0.1/a?params=true').proxy_root
    end
    
    assert_raise ProxyEndpoint::Error do
      ProxyEndpoint.new('http://127.0.0.1/a/?params=true').proxy_root
    end    
  end
  
  def test_get_forward                       
    
    proxy = ProxyEndpoint.new('http://127.0.0.1/a/b')      
    
    $cache.set 'proxy/http://127.0.0.1/a/b', 'http://x.shopifyapps.com/endpoint'
    
    request = stub(:method => 'GET')
    
    proxy.forward(request)
    
    assert_equal 'Third party content', proxy.content
    assert_equal '200', proxy.status
    
  end  
  
  def test_post_forward                           
    proxy = ProxyEndpoint.new('http://127.0.0.1/a/b')      
    
    $cache.set 'proxy/http://127.0.0.1/a/b', 'http://x.shopifyapps.com/endpoint'
    
    request = stub(:method => 'POST', :content_type => 'plain/text', :raw_content => 'Content for endpoint')
    
    proxy.forward(request)
    
    assert_equal 'Third party post content', proxy.content
    assert_equal '200', proxy.status    
  end


end