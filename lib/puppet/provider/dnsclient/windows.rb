# Windows provider for dnsclient
# Puppet::Type.type(:dnsclient).provide(:windows) do

  servers = ["4.2.2.2"]
  nameservershash = {}
  purge = "false"

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
    updatehash = nameservershash
    puts nameservershash
    puts updatehash
    nameservers.each do |nameserver|
      interface = `powershell.exe "Find-NetRoute -RemoteIPAddress #{nameserver} | select -expand InterfaceAlias | Get-Unique"`
      interface = interface.chomp
      puts nameservershash[:"#{interface}"]
      nameserversarray = (nameservershash[:"#{interface}"]).split(",").map { |a| a }
      puts nameserversarray
      puts nameserver
      if not nameserversarray.include? nameserver	
        if nameservershash.has_key?(:"#{interface}")
          nameservershash[:"#{interface}"] << ", #{nameserver}"
        else
          nameservershash[:"#{interface}"] = "#{nameserver}"
        end
      end
      puts nameservershash
    end
    if updatehash.eql? nameservershash
      puts 'They match!'
      puts nameservershash
      puts updatehash
      return 0
    end
    puts "#{nameservershash}"
#    checkexisting nameservershash
    updatedns updatehash
  end

#  def checkexisting(nameservershash)
#    updatehash = {}
#    nameservershash.each do |key, value|
#      currentdns = `powershell.exe "Get-DNSClientServerAddress -InterfaceAlias '#{key}' | select -expand ServerAddresses"`
#      currentdns = currentdns.chomp
#      puts currentdns.inspect
#      puts value
#      if not value.eql? currentdns
#        updatehash[:"#{key}"] = "#{value}"
#        puts updatehash
#      end
#    end
#    if updatehash.empty?
#      return 0
#    end
#    puts updatehash
#    updatedns updatehash
#  end

  def updatedns(updatehash)
    updatehash.each do |key, value|
      output = `powershell.exe Set-DNSClientServerAddress -InterfaceAlias "#{key} -ServerAddresses "#{value}`
      return output
    end
  end

  buildhash (servers)