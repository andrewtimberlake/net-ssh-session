require 'spec_helper'

describe Net::SSH::SessionHelpers do
  let(:session) do
    class Session
      include Net::SSH::SessionHelpers
    end
    Session.new
  end

  describe '#chdir' do
    before do
      session.stub(:run).with("cd /tmp").
        and_return(fake_run("cd /tmp", "", 0))

      session.stub(:run).with("cd /foo/bar").
        and_return(fake_run("cd /foo/bar", "-bash: cd: /foo/bar: No such file or directory\r\n", 1))
    end

    it 'returns true if directory was changed' do
      session.chdir("/tmp").should eq(true)
    end

    it 'returns false if unable to change directory' do
      session.chdir("/foo/bar").should eq(false)
    end
  end

  describe '#pwd' do
    before do
      session.stub(:run).with("pwd").and_return(fake_run("pwd", "/tmp\r\n", 0))
    end

    it 'returns current work directory' do
      session.pwd.should eq("/tmp")
    end
  end

  describe '#capture' do
    before do
      session.stub(:run).with("uname").and_return(fake_run("uname", "Linux\r\n"))
      session.stub(:run).with("ls").and_return(fake_run("ls", "\r\n", 1))
      session.stub(:run).with("date").and_return(fake_run("date", nil, 1))
    end

    it 'returns command output' do
      session.capture("uname").should eq("Linux")
      session.capture("ls").should eq("")
      session.capture("date").should eq("")
    end
  end

  describe '#read_file' do
    before do
      session.stub(:run).with('cat /tmp/file').
        and_return(fake_run('cat /tmp/file', "Hello\n\n", 0))

      session.stub(:run).with('cat /foo').
        and_return(fake_run('cat /foo', nil, 1))
    end

    it 'returns file contents as is' do
      session.read_file("/tmp/file").should eq("Hello\n\n")
    end

    it 'returns empty string if files does not exist' do
      session.read_file("/foo").should eq("")
    end
  end

  describe '#directory_exists?' do
    before do
      session.stub(:run).with('test -d /tmp').and_return(fake_run('test -d /tmp', nil, 0))
      session.stub(:run).with('test -d /foo').and_return(fake_run('test -d /foo', nil, 1))
    end

    it 'returns true if directory exists' do
      session.directory_exists?('/tmp').should be_true
    end

    it 'returns false if directory does not exist' do
      session.directory_exists?('/foo').should be_false
    end
  end

  describe '#file_exists?' do
    before do
      session.stub(:run).with('test -f /f1').and_return(fake_run('test -f /f1', nil, 0))
      session.stub(:run).with('test -f /f2').and_return(fake_run('test -f /f2', nil, 1))
    end

    it 'returns true if file exists' do
      session.file_exists?('/f1').should be_true
    end

    it 'returns false if file does not exist' do
      session.file_exists?('/f2').should be_false
    end
  end

  describe '#process_exists?' do
    before do
      session.stub(:run).with('ps -p 123').and_return(fake_run('ps -p 123', nil, 0))
      session.stub(:run).with('ps -p 345').and_return(fake_run('ps -p 345', nil, 1))
    end

    it 'returns true if process exists' do
      session.process_exists?(123).should be_true
    end

    it 'returns true if process does not exist' do
      session.process_exists?(345).should be_false
    end
  end

  describe '#with_timeout' do
    let(:worker) do
      proc { sleep 1 }
    end

    it 'raises timeout error if exceded' do
      expect { session.with_timeout(0.5, &worker) }.to raise_error Timeout::Error
    end

    it 'runs normally' do
      expect { session.with_timeout(2, &worker) }.not_to raise_error Timeout::Error
    end
  end
end