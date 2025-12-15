/user
add name=igor password=123 group=full
remove admin

/ip address
add address=10.10.2.2/30 interface=ether2
add address=10.10.3.1/30 interface=ether3

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.6/32 interface=loopback network=10.255.255.6

/routing ospf instance
add name=inst router-id=10.255.255.6
set inst redistribute-connected=as-type-1
/routing ospf area
add name=backbonev28 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev28 network=10.10.2.0/30
add area=backbonev28 network=10.10.3.0/30
add area=backbonev28 network=10.255.255.6/32
/routing ospf instance set inst redistribute-connected=as-type-1

/mpls ldp
set lsr-id=10.255.255.6
set enabled=yes transport-address=10.255.255.6
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
set name=R01.LND
