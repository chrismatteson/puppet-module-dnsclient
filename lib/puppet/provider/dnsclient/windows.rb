# Windows provider for dnsclient
# Puppet::Type.type(:dnsclient).provide(:windows) do

  servers = ["4.2.2.2", "8.8.8.8"]
  nameservershash = {}
  purge = true

  def create(nameservers, purge)
    nameservershash = buildhash
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
    nameservershash = buildhash
    updatehash = removeservers(nameservers, nameservershash)
    if updatehash.eql? 0
      puts 'return 0'
    else
      puts updatehash
      updatedns updatehash
    end
  end

#  def exists?(nameservers, purge)
#    nameservershash = buildhash
#    if not buildhash.return == 0
#      return 1
#    else
#      return 0
#  end

  def buildhash
    nameservershash = {}
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
    puts nameservershash.inspect
    puts nameservers.inspect
    nameservers.each do |nameserver|
      interface = `powershell.exe "Find-NetRoute -RemoteIPAddress #{nameserver} | select -expand InterfaceAlias | Get-Unique"`
      interface = interface.chomp
      nameserversarray = (nameservershash[:"#{interface}"]).split(",").map { |a| a }
      if purge == false
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
      else
        if updatehash.has_key?(:"#{interface}")
          updatehash[:"#{interface}"] << ",#{nameserver}"
        else
          updatehash[:"#{interface}"] = "#{nameserver}"
        end
      end
    end
    updatehash
  end

  def removeservers(nameservers, nameservershash)
    updatehash = {}
    nameservers.each do |nameserver|
      nameservershash.each do |key, value|
        nameserversarray = ("#{value}").split(",").map { |a| a }
        if nameserversarray.include? nameserver
          if updatehash.has_key?(:"#{key}")
            if (updatehash[:"#{key}"]).include? ','
              updateserversarray = (updatehash[:"#{key}"]).split(",").map { |a| a }
            else
              updateserversarray = updatehash[:"#{key}"]
            end
            updateserversarray.delete("#{nameserver}")
            updatehash[:"#{key}"] = updateserversarray
          else
            updateserversarray = nameserversarray
            updateserversarray.delete("#{nameserver}")
            updatehash[:"#{key}"] = updateserversarray
          end
        end
      end
    end
    puts updatehash
    puts nameservershash
    if updatehash.empty?
      return 0
    else
      puts 'im changing stuff'
      puts updatehash
    end
    updatehash
  end

  def updatedns(updatehash)
    updatehash.each do |key, value|
      if value.empty?
        `powershell.exe "Set-DNSClientServerAddress -InterfaceAlias #{key} -ResetServerAddresses"`
      else
        value = "#{value.join(',')}"
        `powershell.exe Set-DNSClientServerAddress -InterfaceAlias #{key} -ServerAddresses #{value}`
      end
    end
  end

#  create(servers, purge)
  destroy(servers)