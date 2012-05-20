require 'process_builder'

describe ProcessBuilder do
  context "build" do
    it "returns a new ProcessBuilder object" do
      p = ProcessBuilder.build
      p.should be_kind_of(ProcessBuilder)
    end

    it "optionally takes command line arguments" do
      p = ProcessBuilder.build('command', 'arg1', 'arg2')
      p.command_line.should == %w[command arg1 arg2]
    end

    it "yields a ProcessBuilder::Builder object if given a block" do
      yielded = false
      process = ProcessBuilder.build do |p|
        yielded = true
        p.should be_kind_of(ProcessBuilder::Builder)
      end
      yielded.should be_true
    end

    it "copies the values set on the builder object in the block" do
      process = ProcessBuilder.build('command', 'arg1') do |builder|
        builder.command_line << 'arg2'
        builder.directory = "#{ENV['HOME']}/fakedir"
        builder.environment['ULTIMATE_ANSWER'] = 42
        builder.environment['NILVAR'] = nil
      end
      process.command_line.should == %w[command arg1 arg2]
      process.directory.should == Pathname("#{ENV['HOME']}/fakedir")
      process.environment.should == {
        'ULTIMATE_ANSWER' => 42,
        'NILVAR' => nil
      }
    end
  end

  context "copy" do
    let(:initializer) {
      ->(builder) do
        builder.directory = 'somedir'
        builder.environment['SOMEVAR'] = 'someval'
      end
    }
    it "copies all attributes of the other process builder" do
      p1 = ProcessBuilder.build('command', 'arg1', &initializer)
      p2 = ProcessBuilder.copy(p1) do |p|
        p.directory = 'anotherdir'
        p.environment['ANOTHERVAR'] = 'anotherval'
      end
      p2.command_line.should == %w[command arg1]
      p2.directory.should == Pathname('anotherdir')
      p2.environment.should == {
        'SOMEVAR' => 'someval',
        'ANOTHERVAR' => 'anotherval'
      }
    end
  end

  context "#spawn_args" do
    let(:process) {
      ProcessBuilder.build('command', 'arg1') do |p|
        p.directory = 'somedir'
        p.environment['SOMEVAR'] = 'someval'
        p.pgroup = true
        p.redirection[:err] = 'error.log'
        p.umask = 42
        p.rlimit['core'] = [0, 100]
        p.rlimit[:nice] = 20
      end
    }

    it "converts all attributes into arguments for Process.spawn" do
      spawn_args = process.spawn_args
      spawn_args.should == [
        {'SOMEVAR' => 'someval'},
        'command', 'arg1',
        {
          :chdir => 'somedir',
          :pgroup => true,
          :err => 'error.log',
          :umask => 42,
          :rlimit_core => [0, 100],
          :rlimit_nice => 20
        }
      ]
    end
  end

  it "can spawn a new process" do
    p = ProcessBuilder.build('ruby', '--version') do |p|
      p.redirection[:err] = :close
    end
    pid = p.spawn
    pid.should be_kind_of(Integer)
  end

  context "popen" do
    let(:process) {
      ProcessBuilder.build('ruby', '--version')
    }

    it "supports popen2" do
      stdin, stdout, wait_thread = process.popen2
      stdin.should be_kind_of(IO)
      stdout.should be_kind_of(IO)
      wait_thread.should be_kind_of(Thread)
      stdin.close
      stdout.close

      process.popen2 do |stdin, stdout, wait_thread|
        stdin.should be_kind_of(IO)
        stdout.should be_kind_of(IO)
        wait_thread.should be_kind_of(Thread)
      end
    end

    it "supports popen3" do
      stdin, stdout, stderr, wait_thread = process.popen3
      stdin.should be_kind_of(IO)
      stdout.should be_kind_of(IO)
      stderr.should be_kind_of(IO)
      wait_thread.should be_kind_of(Thread)
      stdin.close
      stdout.close
      stderr.close

      process.popen3 do |stdin, stdout, stderr, wait_thread|
        stdin.should be_kind_of(IO)
        stdout.should be_kind_of(IO)
        stderr.should be_kind_of(IO)
        wait_thread.should be_kind_of(Thread)
      end
    end
  end

  context "capture" do
    it "supports capture2" do
      process = ProcessBuilder.build('ruby')
      stdout_string, status = process.capture2("puts('Hello world!')")
      stdout_string.should == "Hello world!\n"
      status.should be_kind_of(Process::Status)
    end

    it "supports capture3" do
      process = ProcessBuilder.build('ruby')
      ruby_code = %Q{puts("Hello world!"); $stderr.puts("42")}
      stdout_string, stderr_string, status = process.capture3(ruby_code)
      stdout_string.should == "Hello world!\n"
      stderr_string.should == "42\n"
      status.should be_kind_of(Process::Status)
    end
  end
end
