# Windows provider for dnsclient
# Puppet::Type.type(:dnsclient).provide(:windows) do

  servers = ["4.2.2.3", "8.8.8.8"]
  nameservershash = {}
  purge = false

  def create(nameservers, purge)
    nameservershash = buildhash nameservers
    updatehash = addservers(nameservers, nameservershash, purge)
    puts updatehash
    if updatehash.empty?
      puts 'return 0'
      return 0
    else
      updatedns updatehash
    end
  end

  def destroy(nameservers)
    nameservershash = buildhash nameservers
    updatehash = removeservers(nameservers, nameservershash)
    updatedns updatehash
  end
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
    nameservershash
  end

  def addservers(nameservers, nameservershash, purge=false)
    updatehash = {}
    nameservers.each do |nameserver|
      interface = `powershell.exe "Find-NetRoute -RemoteIPAddress #{nameserver} | select -expand InterfaceAlias | Get-Unique"`
      interface = interface.chomp
      nameserversarray = (nameservershash[:"#{interface}"]).split(",").map { |a| a }
      if not nameserversarray.include? nameserver	
        if updatehash.has_key?(:"#{interface}")
          updatehash[:"#{interface}"] << ",#{nameserver}"
        else
          if purge == false && nameservershash.has_key?(:"#{interface}")
            updatehash[:"#{interface}"] = nameservershash[:"#{interface}"]
            updatehash[:"#{interface}"] << ",#{nameserver}"
          else
            updatehash[:"#{interface}"] = "#{nameserver}"
          end
        end
      end
    end
    updatehash
  end

  def removeservers(nameservers, nameservershash)
    updatehash = {}
    nameservers.each do |nameserver|
      interface = `powershell.exe "Find-NetRoute -RemoteIPAddress #{nameserver} | select -expand InterfaceAlias | Get-Unique"`
      interface = interface.chomp
      nameserversarray = (nameservershash[:"#{interface}"]).split(",").map { |a| a }
      if nameserversarray.include? nameserver
        if updatehash.has_key?(:"#{interface}")
          updateserversarray = (updatehash[:"#{interface}"]).delete("#{nameserver}")
          updatehash[:"#{interface}"] = updateserversarray
         else
          updateserversarray = (nameservershash[:"#{interface}"]).delete("#{nameserver}")
          updatehash[:"#{interface}"] = updateserversarray
        end
      end
    end
    puts updatehash
    updatehash
  end

  def updatedns(updatehash)
    updatehash.each do |key, value|
      output = `powershell.exe Set-DNSClientServerAddress -InterfaceAlias "#{key} -ServerAddresses "#{value}`
      return output
    end
  end

#  create(servers, purge)
  destroy(servers)