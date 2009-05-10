require "test/unit"

require "request"

class TestRequest < Test::Unit::TestCase
  
  def setup            
    @req = Request.new(raw_request)
  end

  def test_method_parsing
    assert_equal 'GET', @req.method
  end

  def test_path_parsing
    assert_equal '/path/and?param=true', @req.path
  end   
  
  def test_headers                    
    assert ! @req.headers.empty?
    assert_equal 'en-us', @req.headers['Accept-Language']
  end
  
  def test_add_header
    @req.add_header 'X-Custom-Header1', 'true'
    @req.add_header 'X-Custom-Header2', 'true'
        
    assert @req.data =~ Request::Host
    
    assert_equal 'true', @req.headers['X-Custom-Header1']
    assert_equal 'true', @req.headers['X-Custom-Header2']
    
    assert_equal 'localhost:3005', @req.headers['Host']
  end
  
  def test_parse_content
    post_req = Request.new(raw_post_request)
    
    assert_equal "Here be the content\r\n", post_req.raw_content
  end
  
  private
  
  def raw_request
    "GET /path/and?param=true HTTP/1.1\r\nUser-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1\r\nAccept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5\r\nAccept-Language: en-us\r\nAccept-Encoding: gzip, deflate\r\nConnection: keep-alive\r\nHost: localhost:3005\r\n\r\n"
  end

  def raw_post_request
    "POST /path/and?param=true HTTP/1.1\r\nUser-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1\r\nAccept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5\r\nAccept-Language: en-us\r\nAccept-Encoding: gzip, deflate\r\nConnection: keep-alive\r\nHost: localhost:3005\r\n\r\nHere be the content\r\n"
  end
end