/user
add name=igor password=123 group=full
remove admin

/ip address
add address=10.10.7.2/30 interface=ether2
add address=10.10.6.1/30 interface=ether3

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.4/32 interface=loopback network=10.255.255.4

/routing ospf instance
add name=inst router-id=10.255.255.4
set inst redistribute-connected=as-type-1
/routing ospf area
add name=backbonev28 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev28 network=10.10.6.0/30
add area=backbonev28 network=10.10.7.0/30
add area=backbonev28 network=10.255.255.4/32
/routing ospf instance set inst redistribute-connected=as-type-1

/mpls ldp
set lsr-id=10.255.255.4
set enabled=yes transport-address=10.255.255.4
/mpls ldp advertise-filter 
add prefix=10.255.255.0/24 advertise=yes
add advertise=no
/mpls ldp accept-filter 
add prefix=10.255.255.0/24 accept=yes
add accept=no
/mpls ldp interface
add interface=ether2
add interface=ether3

/system identity
set name=R01.MSK
