config system global
  set hostname ${hostname}
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
          set allowaccess probe_response
          next
        %{ endfor }
      end
    next
    edit port2
      set mode static
      set ip ${port2_ip}/32
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
