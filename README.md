process-builder
===============

Simple object-oriented wrapper around Ruby's Process.spawn and Open3 library.

ProcessBuilder allows you to build a process description which can then be
used to spawn and interact with an external process.

Usage
-----

```require 'process-builder'

# Build a process description with the ProcessBuilder.build method.
process = ProcessBuilder.build('oggenc', 'track01.cdda.wav') do |builder|
  # The builder object passed to this block has methods for setting various
  # attributes of the process. See the RDoc for full details.
  builder.environment['LOG_DIR'] = '/var/log'
  builder.directory = "#{ENV['HOME']}/Music"
end

# Once the process description is built there are a variety of ways
# to spawn the process. One way is to call spawn:
pid = process.spawn
Process.wait(pid)

# Another way is to use any of the popen or capture methods defined by Open3:
stdin, stdout, stderr, wait_thread = process.popen3
status = wait_thread.value
stdin.close; stdout.close; stderr.close

# or in block form:
process.popen3 do |stdin, stdout, stderr, wait_thread|
  status = wait_thread.value
end
```

