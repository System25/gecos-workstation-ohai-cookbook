provides 'ohai_gecos'

if ohai_gecos.nil?
  ohai_gecos Mash.new
end

require 'etc'
require 'rest_client'
require 'json'
users = []
users_send = []

if Gem.win_platform?
    # -------------------- Windows  ------------------------
	excludeUsers = ['', "Administrador", "Administrator", "DefaultAccount", "Invitado", "Guest", "Default", "Default User", "Public", "All Users"]
    homedirs = Dir[ENV['SystemDrive'] + "/Users/*"].reject{ |f| not File.directory?(f) } + Dir[ENV['SystemDrive'] +"/Documents and Settings/*"].reject{ |f| not File.directory?(f) }
    homedirs.each do |homedir|
	  #print 'homedir='+homedir+"\n"
      temp = homedir.split('/')
      username=temp[temp.size()-1]
	  #print 'username='+username+"\n"
	  
	  
	  if  not excludeUsers.include? username
		    isadmin = false
		    cmd = ENV['SystemRoot'] + "\\System32\\net.exe localgroup #{$admin_group} | "+ ENV['SystemRoot'] + "\\System32\\findstr.exe #{username}"
		    # print "cmp = '#{cmd}' \n"
		    output = %x( #{cmd} )
			
		    #print "output = '#{output.chomp.strip}' username = '#{username}'\n"
		    if output.chomp.strip == username
			  isadmin = true
		    end
		  
			users << Mash.new(
			  :username => username,
			  :home     => "#{userProfileBase}#{username}",
			  :gid      => 0,
			  :uid      => 0,
			  :sudo     => isadmin
			)
			users_send << username
	  end
	  
    end	
    
else
    # -------------------- Linux  ------------------------
    # LikeWise create the user homes at /home/local/DOMAIN/
    homedirs = Dir["/home/*"] + Dir["/home/local/*/*"]
    grp_sudo = Etc.getgrnam('sudo')
    homedirs.each do |homedir|
      temp=homedir.split('/')
      user=temp[temp.size()-1]
      begin
        entry=Etc.getpwnam(user)
        users << Mash.new(
          :username => entry.name,
          :home     => entry.dir,
          :gid      => entry.gid,
          :uid      => entry.uid,
          :sudo     => grp_sudo.mem.include?(entry.name)
        )
        users_send << entry.name
      rescue Exception => e
        puts 'User ' + user + ' doesn\'t exists'
      end
    end

end

ohai_gecos['users'] = users

