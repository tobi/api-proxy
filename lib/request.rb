
class Request
  Command = /(GET|POST) (\/\S*)/
  Host = /^(Host\: .*)$/        
  Headers = /^([\w\-]+)\:(.*)$/
  Content = /\r\n\r\n(.*)/m
  
  attr_reader :headers, :data,  :method, :path

  def initialize(data)
    @data = data         
    @method, @path = data.scan(Command).first    
  end            
  
  def content_type
    headers['Content-Type']
  end                                        
  
  def headers
    @headers ||= @data.scan(Headers).inject(Hash.new) do |hash, (k, v)|
      hash[k] = v.strip; hash
    end    
  end
  
  def add_header(name, value)
    @headers = nil
    @data.sub!(Host, "\\1\n#{name}: #{value}\r")
  end         
    
  def raw_content
    @data.scan(Content).flatten.first
  end
end                                      
