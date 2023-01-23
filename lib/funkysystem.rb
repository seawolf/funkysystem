require "funkysystem/version"
require 'io/nonblock'

module FunkySystem
  # Run block, but with output redirected to elsewhere
  #
  # @param outputs [Hash] :stdout & :stderr - either an IO object, a filename or nil to redirect stream to /dev/null
	def self.redirect_output(options = {}, &block)
		stderr_dup = STDERR.dup
		stdout_dup = STDOUT.dup
		begin
			output_to_writeable_io(options[:stdout]) do |out|
				STDOUT.reopen(out)
				output_to_writeable_io(options[:stderr]) do |err|
					STDERR.reopen(err)
					block.call
				end
			end
		ensure
			STDERR.reopen(stderr_dup)
			STDOUT.reopen(stdout_dup)
		end
	end
	def self.output_to_writeable_io(out, &block)
		case out
		when String
			File.open(out, 'w', &block)
		when IO
			yield(out)
		#when nil
		else
			File.open('/dev/null', 'w', &block)
		end
	end


	class ProgramOutput
		attr_reader :pid, :status, :stdout, :stderr, :unused_stdin
		def initialize(pid, status, stdout, stderr, unused_stdin)
			@pid, @status, @stdout, @stderr, @unused_stdin =
				pid, status, stdout, stderr, unused_stdin
		end
		def error?
			! @status.success?
		end
		def success?
			@status.success?
		end
	end
	def self.find_exec(name)
		ENV["PATH"].split(/:/).each do |bin|
			path = File.join(File.expand_path(bin), name)
			begin
				stat = File.stat(path)
				if stat.executable? && stat.file?
					return path
				end
			rescue Errno::ENOENT
			end
		end
		nil
	end
	def self.run(cmd, stdin=nil)
		fps = {
			:stdout => IO.pipe,
			:stderr => IO.pipe
		}
		
		fps[:stdin] = IO.pipe if stdin
		
		fps.each do |key,fpa|
			class << fpa
				alias :reader :first
				alias :writer :last
			end
		end
		
		pid = fork do
			keep = [STDERR, STDOUT, STDIN] + fps.values.flatten
			ObjectSpace.each_object(IO) { |io|
				begin
					io.close() unless keep.include?(io)
				rescue Exception
				end
			}
			if fps[:stdin]
				fps[:stdin].writer.close
				STDIN.reopen(fps[:stdin].reader)
				fps[:stdin].reader.close
			else
				# No input - child shouldn't
				# be allowed to expect any...
				STDIN.close()
			end
			
			fps[:stdout].reader.close
			STDOUT.reopen(fps[:stdout].writer)
			fps[:stdout].writer.close
			
			fps[:stderr].reader.close
			STDERR.reopen(fps[:stderr].writer)
			fps[:stderr].writer.close
			
			exec(* ( cmd.is_a?(Array) ? cmd : [cmd] ) )
		end
		
		fps[:stderr].writer.close
		fps[:stdout].writer.close
		
		if fps[:stdin]
			fps[:stdin].reader.close 
			out_fds = [fps[:stdin].writer]
		else
			out_fds = []
		end
		
		in_fds  = [fps[:stderr].reader, fps[:stdout].reader]
		all_fds = in_fds + out_fds
		
		all_fds.each { |fd| fd.nonblock = true }
		
		stdout = ''
		stderr = ''
		exited = nil
		exit_time = nil
		
		until exited && (in_fds.all? { |fd| fd.closed? or fd.eof? } || exit_time < (Time.now.to_i - 3) )
			exited ||= Process.waitpid2(pid, Process::WNOHANG)
			exit_time ||= Time.now.to_i if exited
			begin
				rd, wr, er = select(in_fds, out_fds, all_fds, 0.05)
			rescue IOError
				[in_fds, out_fds, all_fds].each { |grp|
					grp.reject!{ |fd| fd.closed? }
				}
				rd = wr = er = nil
			end
			wr.each do |fd|
				begin
					case fd
					when fps[:stdin].writer
						size = fd.syswrite(stdin)
						stdin = stdin.byteslice(size..)
						if stdin.empty?
							fd.close
							out_fds = []
							stdin = nil
						end
					end
				rescue Errno::EPIPE, IOError
				end
			end if wr.respond_to?(:each)
						
			rd.each do |fd|
				begin
					case fd
					when fps[:stderr].reader
						stderr << fd.sysread(4096 * 4)
					when fps[:stdout].reader
						stdout << fd.sysread(4096 * 4)
					end
				rescue Errno::EPIPE, IOError
				end
			end if rd.respond_to?(:each)

		end
		
		ProgramOutput.new(pid, exited.last, stdout, stderr, stdin)
	end

end



