# Windows provider for dnsclient
# Puppet::Type.type(:dnsclient).provide(:windows) do

  servers = ["4.2.2.3", "8.8.4.4"]
  nameservershash = {}
  purge = true

#  def create(nameservers,purge)
#    buildhash (nameservers,purge)
#    nameservershash = buildhash.return
#    updatehash = checkexisting.return
#    updatedns updatehash
#  end
#
#  def destroy(nameservers)
#    purge = false
#    buildhash nameservers purge
#  end
#
#  def exists?(nameservers,purge)
#    buildhash (nameservers,purge)
#    if not buildhash.return == 0
#      return 1
#    else
#      return 0
#  end

  def buildhash(nameservers)
    nameservershash = {}
    puts nameservers
    interfaces = `powershell.exe "(Get-DNSClientServerAddress | select -expand InterfaceAlias | Get-Unique) -join ','"`
    interfaces = interfaces.chomp
    interfaces = interfaces.split(",").map { |a| a }
    interfaces.each do |interface|
      currentdns = `powershell.exe "Get-DNSClientServerAddress -InterfaceAlias '#{interface}' | select -expand ServerAddresses"`
      currentdns = currentdns.split("\n").join(",")
      nameservershash[:"#{interface}"] = "#{currentdns}"
    end
    puts nameservershash
#    return nameservershash
    checkexisting(nameservers, nameservershash)
  end

  def checkexisting(nameservers, nameservershash)
    updatehash = {}
    nameservers.each do |nameserver|
      interface = `powershell.exe "Find-NetRoute -RemoteIPAddress #{nameserver} | select -expand InterfaceAlias | Get-Unique"`
      interface = interface.chomp
      nameserversarray = (nameservershash[:"#{interface}"]).split(",").map { |a| a }
      if not nameserversarray.include? nameserver	
        if updatehash.has_key?(:"#{interface}")
          updatehash[:"#{interface}"] << ",#{nameserver}"
        else
          if nameservershash.has_key?(:"#{interface}")
            updatehash[:"#{interface}"] = nameservershash[:"#{interface}"]
            updatehash[:"#{interface}"] << ",#{nameserver}"
          else
            updatehash[:"#{interface}"] = "#{nameserver}"
          end
        end
      end
    end
    if updatehash.empty?
      puts 'They match!'
      return 0
    end
#    return updatehash
    updatedns updatehash
  end

  def updatedns(updatehash)
    updatehash.each do |key, value|
      output = `powershell.exe Set-DNSClientServerAddress -InterfaceAlias "#{key} -ServerAddresses "#{value}`
      return output
    end
  end

  buildhash servers