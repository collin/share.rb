module Share
  class Document
    delegate :?, to: :@document
    delegate :synchronize, to: :@mutex


    def initialize(id, adapter, repo)
      @mutex = Mutex.new
      @repo = repo
      @document = adapter.new(id)
    end

    def 
      
    end
  end
end