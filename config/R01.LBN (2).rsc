/user
add name=igor password=123 group=full
remove admin

/ip address
add address=10.10.6.2/30 interface=ether2
add address=10.10.4.1/30 interface=ether3
add address=10.10.5.2/30 interface=ether4

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.5/32 interface=loopback network=10.255.255.5

/routing ospf instance
add name=inst router-id=10.255.255.5
set inst redistribute-connected=as-type-1
/routing ospf area
add name=backbonev28 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev28 network=10.10.5.0/30
add area=backbonev28 network=10.10.4.0/30
add area=backbonev28 network=10.10.6.0/30
add area=backbonev28 network=10.255.255.5/32
/routing ospf instance set inst redistribute-connected=as-type-1

/mpls ldp
set lsr-id=10.255.255.5
set enabled=yes transport-address=10.255.255.5
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

/system identity
set name=R01.LBN
