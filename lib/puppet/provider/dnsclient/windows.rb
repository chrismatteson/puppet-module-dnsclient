# Windows provider for dnsclient
# Puppet::Type.type(:dnsclient).provide(:windows) do

  servers = ["4.2.2.2", "8.8.8.8"]
  nameservershash = {}
  purge = true

#  def create(nameservers,purge)
#    buildhash (nameservers,purge)
#    nameservershash = buildhash.return
#    checkexisting nameservershash
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
#    checkexisting nameservershash
#    if not checkexisting.return == 0
#      return 1
#    else
#      return 0
#  end

  def buildhash(nameservers, purge=false)
    nameservershash = {}
    if purge == false
      interfaces = `powershell.exe "(Get-DNSClientServerAddress | select -expand InterfaceAlias | Get-Unique) -join ','"`
      interfaces = interfaces.chomp
      interfaces = interfaces.split(",").map { |a| a }
      interfaces.each do |interface|
        currentdns = `powershell.exe "Get-DNSClientServerAddress -InterfaceAlias '#{interface}' | select -expand ServerAddresses"`
        currentdns = currentdns.chomp
        nameservershash[:"#{interface}"] = "#{currentdns}"
      end
    end
    updatehash = {}
    puts nameservershash
    nameservers.each do |nameserver|
      interface = `powershell.exe "Find-NetRoute -RemoteIPAddress #{nameserver} | select -expand InterfaceAlias | Get-Unique"`
      interface = interface.chomp
      nameserversarray = (nameservershash[:"#{interface}"]).split(",").map { |a| a }
      if not nameserversarray.include? nameserver	
        if updatehash.has_key?(:"#{interface}")
          updatehash[:"#{interface}"] << ", #{nameserver}"
        else
          if nameservershash.has_key?(:"#{interface}")
            updatehash[:"#{interface}"] = nameservershash[:"#{interface}"]
            updatehash[:"#{interface}"] << ", #{nameserver}"
          else
            updatehash[:"#{interface}"] = "#{nameserver}"
          end
        end
      end
      puts updatehash
    end
    if updatehash.empty?
      return 0
    end
    puts "#{nameservershash}"
    updatedns updatehash
  end

  def updatedns(updatehash)
    updatehash.each do |key, value|
      output = `powershell.exe Set-DNSClientServerAddress -InterfaceAlias "#{key} -ServerAddresses "#{value}`
      return output
    end
  end

  buildhash (servers, purge)