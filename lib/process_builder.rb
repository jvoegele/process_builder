require 'pathname'
require 'open3'

# Object-oriented wrapper around Process.spawn and the Open3 library.
# ProcessBuilder is an immutable description of a process and its various
# attributes. ProcessBuilder objects are created with the
# ProcessBuilder.build method, and after having been created can be used
# to spawn the process in various ways, such as #spawn or #popen3.
#
# See the descriptions of the methods of this class for further details,
# and the documentation for Process.spawn and Open3 for full details of
# the arguments that each understands.
class ProcessBuilder
  VERSION = '0.5.0'

  # The command and arguments passed to Process.spawn
  attr_reader :command_line

  # Working directory for the process. Corresponds to the :chdir option of
  # Process.spawn
  attr_reader :directory

  # Hash representing environment variables for the process. Passed as the
  # optional [env] argument of Process.spawn.
  attr_reader :environment

  # If true, clear environment variables, other than specified explicitly
  # in environment.
  attr_reader :unsetenv_others
  alias unsetenv_others? unsetenv_others

  # Process group, corresponding to the :pgroup option of Process.spawn.
  attr_reader :pgroup

  # Hash specifying IO redirection for the child process, corresponding to
  # the redirection options of Process.spawn. Generally not used if using any
  # of the Open3 mechanisms for spawning the process.
  attr_reader :redirection

  # File descriptor inheritance, corresponding to the :close_others option of
  # Process.spawn.
  attr_reader :close_others

  # umask for the child process, corresponding to the :umask option of
  # Process.spawn.
  attr_reader :umask

  # Hash specifying resource limits. Process.spawn expects resource limits to
  # be specified as options in the form :rlimit_resourcename, where
  # resourcename is one of the resources understood by Process.setrlimit,
  # such as :rlimit_core for example.
  # The keys of this Hash will be used to construct the options, so setting
  # rlimit[:core] would result in an option named :rlimit_core.
  attr_reader :rlimit

  # Build a new process description using the given args as the process
  # command line. If a block is given, this method will yield a mutable
  # ProcessBuilder::Builder object to it so that the block can specify the
  # attributes of the process. The object returned by this method, however,
  # is an immutable (and frozen) instance of ProcessBuilder.
  def self.build(*args, &block)
    new(*args, &block)
  end

  # Build a new process description copied from the given other ProcessBuilder.
  # Like the build method, this method yields to the given block to allow for
  # customization of the process attributes.
  def self.copy(other)
    raise ArgumentError unless other.is_a?(ProcessBuilder)
    if block_given?
      builder = Builder.new(other)
      if block_given?
        yield builder
      end
      new(builder)
    else
      new(other)
    end
  end

  def initialize(*args)
    if args.size == 1 && args.first.is_a?(ProcessBuilder)
      self.copy_fields(args.first)
    else
      @command_line = array_copy(args)
      @environment = Hash.new
      @redirection = Hash.new
      @rlimit = Hash.new
      if block_given?
        builder = Builder.new(self)
        yield builder
        self.copy_fields(builder)
      end
    end
    self.freeze
  end

  def initialize_copy(other)
    super
    self.copy_fields(other)
  end

  # Spawn the process described by this ProcessBuilder using Process.spawn.
  # Returns the PID of the spawned process.
  def spawn
    Process.spawn(*spawn_args)
  end

  # Spawn the process described by this ProcessBuilder using Open3.popen2.
  def popen2(&block)
    Open3.popen2(*spawn_args, &block)
  end

  # Spawn the process described by this ProcessBuilder using Open3.popen2e.
  def popen2e(&block)
    Open3.popen2e(*spawn_args, &block)
  end

  # Spawn the process described by this ProcessBuilder using Open3.popen3.
  def popen3(&block)
    Open3.popen3(*spawn_args, &block)
  end

  # Execute the process described by this ProcessBuilder using Open3.capture2.
  # The argument to this method is used as the :stdin_data argument of
  # Open3.capture2.
  def capture2(stdin_data, &block)
    args = self.spawn_args
    args.last[:stdin_data] = stdin_data.to_s.dup
    Open3.capture2(*args, &block)
  end

  # Execute the process described by this ProcessBuilder using Open3.capture3.
  # The argument to this method is used as the :stdin_data argument of
  # Open3.capture3.
  def capture3(stdin_data, &block)
    args = self.spawn_args
    args.last[:stdin_data] = stdin_data.to_s.dup
    Open3.capture3(*args, &block)
  end

  # Returns an array of arguments as understood by Process.spawn.
  def spawn_args
    result = Array.new
    unless environment.empty?
      result << environment
    end
    result.concat(command_line)
    opts = Hash.new
    opts[:chdir] = directory.to_s unless directory.nil?
    opts[:pgroup] = pgroup unless pgroup.nil?
    opts[:umask] = umask unless umask.nil?
    opts[:unsetenv_others] = unsetenv_others unless unsetenv_others.nil?
    opts[:close_others] = close_others unless close_others.nil?
    rlimit.each do |key, value|
      opts["rlimit_#{key}".to_sym] = value
    end
    redirection.each do |key, value|
      opts[key] = value
    end
    result << opts
    result
  end

protected

  def copy_fields(other)
    @command_line = array_copy(other.command_line)
    @directory = Pathname(other.directory )if other.directory
    @environment = hash_copy(other.environment)
    @unsetenv_others = other.unsetenv_others
    @pgroup = other.pgroup
    @redirection = hash_copy(other.redirection)
    @close_others = other.close_others
    @umask = other.umask
    @rlimit = hash_copy(other.rlimit)
  end

private

  def copy_val(val)
    case val
    when NilClass, TrueClass, FalseClass, Numeric, Symbol
      val
    else
      val.dup.freeze
    end
  end

  def array_copy(array)
    [array].flatten.compact.map { |arg|
      copy_val(arg)
    }
  end

  def hash_copy(hash)
    hash ||= Hash.new
    result = Hash.new
    hash.each do |key, value|
      result[key] = copy_val(value)
    end
    result
  end

  class Builder < ProcessBuilder
    attr_writer :command_line, :directory, :environment, :pgroup,
                :rlimit_resourcename, :umask, :close_others

    def initialize(initial_state)
      self.copy_fields(initial_state)
    end
  end
end
