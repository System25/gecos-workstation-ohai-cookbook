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
    cmd = ENV['SystemRoot'] + "\\System32\\net user"
    output = %x( #{cmd} )
    
    output = output.to_s.split("\n")
    
    # Remove last line
    output.pop

    # Remove first four lines (header)
    output.shift 
    output.shift 
    output.shift 
    output.shift 

    userProfileBase = 'C:\\Users\\'

    # Extract usernames from output
    output = output.join(" ")
    output = output.gsub('\r', ' ').gsub('\n', ' ').gsub('\t', ' ')
    userdata = output.split()
    
    # Get administrators local group
    adminLocalGroup = ''
    
    cmd = ENV['SystemRoot'] + "\\System32\\net localgroup | findstr Administrators"
    output = %x( #{cmd} )    
    if output.chomp == "*Administrators"
        adminLocalGroup = 'Administrators'
    else
        cmd = ENV['SystemRoot'] + "\\System32\\net localgroup | findstr Administradores"
        output = %x( #{cmd} )    
        if output.chomp == "*Administradores"
            adminLocalGroup = 'Administradores'
        end
    end
    
    # Check users
    userdata.each do |username|
        print username
        isadmin = false
        cmd = ENV['SystemRoot'] + "\\System32\\net localgroup #{adminLocalGroup} | findstr #{username}"
        output = %x( #{cmd} )
        
        if output.chomp == username
            isadmin = true
        end
        
        if File.directory?("#{userProfileBase}#{username}")
            if username != "" and username != "Administrador" and username != "Administrator" and username != "DefaultAccount" and username != "Invitado" and username != "Guest"
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

