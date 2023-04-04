Content-Type: multipart/mixed; boundary="12345"
MIME-Version: 1.0

--12345
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"


LICENSE-TOKEN: ${flexvm_token}

--12345
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system global
  set hostname ${hostname}
end
config system global
    set admintimeout 50
end
config system interface
    edit port1
      set mode static
      set ip ${port1_ip}/32
      set secondary-IP enable
      config secondaryip
        %{ for eip in frontends}
          edit 0
          set ip ${eip}/32
          set allowaccess probe-response
          next
        %{ endfor }
      end
    next
    edit port2
      set mode static
      set ip ${port2_ip}/32
    next
    edit port3
      set dhcp-classless-route-addition enable
    next
    edit port4
      set dhcp-classless-route-addition enable
    next
end
config router static
  edit 0
  set device port1
  set gateway ${port1_gw}
  next
  edit 0
  set device port2
  set gateway ${port2_gw}
  set dst ${port2_subnet}
  next
  %{ for cidr in hq_subnets }
  edit 0
  set dst ${cidr}
  set gateway ${hq_via}
  set device port7
  next
  %{ endfor }
end

config system probe-response
    set mode http-probe
    set http-probe-value OK
    set port ${healthcheck_port}
end
config system api-user
  edit terraform
    set api-key ${api_key}
    set accprofile "prof_admin"
    config trusthost
    %{ for cidr in api_acl ~}
      edit 0
        set ipv4-trusthost ${cidr}
      next
    %{ endfor ~}
    end
  next
end
config system sdn-connector
    edit "gcp"
        set type gcp
        set ha-status enable
    next
end
config system dns
  set primary 169.254.169.254
  set protocol cleartext
  unset secondary
end

config system ha
    set session-pickup enable
    set session-pickup-connectionless enable
    set session-pickup-nat enable
end

config system standalone-cluster
    set group-member-id ${ha_indx}
    config cluster-peer
        %{ for peer in ha_peers }
        edit 0
        set peerip ${peer}
        next
        %{ endfor }
    end
end

${fgt_config}

--12345--
