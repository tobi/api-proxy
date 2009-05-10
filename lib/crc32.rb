def crc32
  Zlib.crc32(@body, 0)
end 

def String  
  def crc32
    Kernel.crc32(self)
  end
end
