/user
add name=igor password=123 group=full
remove admin

/ip address
add address=10.10.1.1/30 interface=ether2
add address=10.10.7.1/30 interface=ether3
add address=192.168.28.1/24 interface=ether4

/ip pool
add name=dhcp-pool ranges=192.168.28.10-192.168.28.100
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether4 name=dhcp-server
/ip dhcp-server network
add address=192.168.28.0/24 gateway=192.168.28.1

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.2/32 interface=loopback network=10.255.255.2

/routing ospf instance
add name=inst router-id=10.255.255.2
set inst redistribute-connected=as-type-1
/routing ospf area
add name=backbonev28 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev28 network=10.10.1.0/30
add area=backbonev28 network=10.10.7.0/30
add area=backbonev28 network=192.168.28.0/24
add area=backbonev28 network=10.255.255.2/32

/mpls ldp
set lsr-id=10.255.255.2
set enabled=yes transport-address=10.255.255.2
/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no
/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no
/mpls ldp interface
add interface=ether2
add interface=ether3
add interface=ether4

/interface bridge
add name=vpn
/interface vpls
add disabled=no name=SGIPC remote-peer=10.255.255.7 cisco-style=yes cisco-style-id=0
/interface bridge port
add interface=SGIPC bridge=vpn


/system identity
set name=R01.SPB
