# Windows provider for dnsclient
#Puppet::Type.type(:dnsclient).provide(:windows) do

  servers = ["4.2.2.2"]
  nameservershash = {}

  def buildhash(nameservers)
    nameservershash = {}
    nameservers.each do |nameserver|
      interface = `powershell.exe "Find-NetRoute -RemoteIPAddress #{nameserver} | select -expand InterfaceAlias | Get-Unique"`
      interface = interface.chomp
      if nameservershash.has_key?(:"#{interface}")
        nameservershash[:"#{interface}"] << ", #{nameserver}"
      else
        nameservershash[:"#{interface}"] = "#{nameserver}"
      end
    end
    puts "#{nameservershash}"
    checkexisting nameservershash
  end

  def checkexisting(nameservershash)
    updatehash = {}
    nameservershash.each do |key, value|
      currentdns = `powershell.exe Get-DNSClientServerAddress -InterfaceAlias "#{key} | select -expand ServerAddresses`
      currentdns = currentdns.chomp
      if not value.eql? currentdns
        updatehash[:"#{key}"] = "#{value}"
        puts updatehash
      end
    end
    if updatehash.empty?
      puts 'They match!'
      return 0
    end
    puts updatehash
    updatedns updatehash
  end

  def updatedns(updatehash)
    updatehash.each do |key, value|
      output = `powershell.exe Set-DNSClientServerAddress -InterfaceAlias "#{key} -ServerAddresses "#{value}`
      return output
    end
  end

  buildhash servers