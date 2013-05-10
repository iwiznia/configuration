class Configuration
  instance_methods.each do |meth|
    # skipping undef of methods that "may cause serious problems"
    undef_method(meth) if meth !~ /^(__|object_id|class|include|instance_eval|define_singleton_method|methods|is_a\?|to_s|respond_to\?|send|inspect)/
  end

  Configuration::Version = '1.4.4'
  def Configuration.version
    Configuration::Version
  end

  Path = [
    if defined? CONFIGURATION_PATH
      CONFIGURATION_PATH
    else
      ENV['CONFIGURATION_PATH']
    end
  ].compact.flatten.join(File::PATH_SEPARATOR).split(File::PATH_SEPARATOR)

  Table = Hash.new
  Error = Class.new StandardError

  def initialize(*argv, &block)
    inherits = Configuration === argv.last ? argv.pop : nil
    @name = argv.shift
    @inherits = inherits
    instance_eval(&block) if block
  end

  def inherits
    @inherits
  end

  def method_missing(method, *args, &block)
    if !args.empty?
      define_singleton_method(method, lambda { args.first.is_a?(Proc) ? args.first.call : args.first })
    elsif block
      subconfig = self.class.new(method, @inherits && @inherits.respond_to?(method) ? @inherits.send(method) : nil, &block)
      define_singleton_method(method, lambda { subconfig })
    elsif @inherits && @inherits.respond_to?(method)
      if @inherits.send(method).is_a?(Configuration)
        self.class.new(method, @inherits.send(method))
      else
        @inherits.send(method)
      end
    else
      raise Error.new("Config #{method} not defined!")
    end
  end

  if !methods.include?(:define_singleton_method)
    def define_singleton_method(method, function)
      singleton = class << self; self end
      singleton.send(:define_method, method, function)
    end
  end

  def respond_to?(method)
    !!(super(method) || (@inherits && @inherits.respond_to?(method)))
  end

  def keys
    (self.methods(false) + (@inherits ? @inherits.keys : [])).uniq
  end

  def each
    self.keys.each{|v| yield v }
  end

  def to_hash
    {}.tap do |hash|
      self.each do|name|
        val = __send__(name)
        hash.update name.to_sym => Configuration == val.class ? val.to_hash : val
      end
    end
  end

  def self.for(name, inherits = nil, &block)
    name = name.to_s
    inherits = self.for(inherits) if inherits.is_a?( String )

    if inherits or block
      Table[name] = self.new(name, inherits || {}, &block)
    else
      Table.has_key?(name) ? Table[name] : load(name)
    end
  end

  def self.path(*value)
    return self.path = value.first unless value.empty?
    Path
  end

  def self.path=(value)
    Path.clear
    Path.replace [value].compact.flatten.join(File::PATH_SEPARATOR).split(File::PATH_SEPARATOR)
  end

  def self.load(name)
    name = name.to_s
    name = name + '.rb' unless name[%r/\.rb$/]
    key = name.sub %r/\.rb$/, ''
    load_path = $LOAD_PATH.dup
    begin
      $LOAD_PATH.replace(path + load_path)
      ::Kernel.load name
    ensure
      $LOAD_PATH.replace load_path
    end
    Table[key]
  end

  def self.const_missing(name)
    self.for(name.to_s.downcase)
  end
end
