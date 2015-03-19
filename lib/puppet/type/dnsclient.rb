Puppet::Type.newtype(:dnsclient) do
  confine :operatingsystem { :windows }
  desc 'Puppet type that modifies the DNS client'

  ensurable

  newparam(:nameservers, :namevar => true) do
    desc 'Nameservers to be added to the client'
  end

  newproperty(:purge) do
    desc 'Purge non-matching DNS entries on managed interfaces'
  end
end