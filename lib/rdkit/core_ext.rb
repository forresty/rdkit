class Object
  unless self.respond_to?(:try)
    def try(method, *args)
      __send__(method, *args) rescue nil
    end
  end
end
