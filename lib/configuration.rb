class Configuration
  include Enumerable

  Configuration::Version = '1.4.0'
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
    inherits = Hash === argv.last ? argv.pop : Hash.new
    @name = argv.shift
    @inherits = inherits
    instance_eval &block
  end

  def method_missing(method, *args, &block)
    if !args.empty?
      define_singleton_method(method, lambda { args.first })
    elsif block
      subconfig = self.class.new(method, @inherits[method], &block)
      define_singleton_method(method, lambda { subconfig })
    elsif @inherits[method]
      @inherits[method]
    else
      raise "Config #{method} not defined!"
    end
  end

  if !methods.include?(:define_singleton_method)
    def define_singleton_method(method, function)
      singleton = class << self; self end
      singleton.send(:define_method, method, function)
    end
  end

  def each
    (self.methods(false) + @inherits.keys).uniq.each{|v| yield v }
  end

  def to_hash
    inject({}){ |h,name|
      val = __send__(name.to_sym)
      h.update name.to_sym => Configuration == val.class ? val.to_hash : val
    }
  end

  def self.for(name, inherits = nil, &block)
    name = name.to_s
    inherits = inherits.to_hash if inherits.is_a?( Configuration )
    inherits = self.for(inherits).to_hash if inherits.is_a?( String )

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