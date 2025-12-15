University: [ITMO University](https://itmo.ru/ru/)<br />
Faculty: [FICT](https://fict.itmo.ru)<br />
Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)<br />
Year: 2025/2026<br />
Group: K3320<br />
Author: Yakovlev Igor Sergeevich<br />
Lab: Lab3<br />
Date of create: 14.12.25<br />
Date of finished: 14.12.25<br />

# Задание

Вам необходимо сделать IP/MPLS сеть связи для "RogaIKopita Games" изображенную на рисунке 1 в ContainerLab. Необходимо создать все устройства указанные на схеме и соединения между ними.


- Помимо этого вам необходимо настроить IP адреса на интерфейсах.
- Настроить OSPF и MPLS.
- Настроить EoMPLS.
- Назначить адресацию на контейнеры, связанные между собой EoMPLS.
- Настроить имена устройств, сменить логины и пароли.


# Конфиг yaml

Конфигурация сети аналогична вариантом предыдущим лабораторным работам.
```
name: lab3
mgmt:
  network: lab-3
  ipv4-subnet: 172.10.0.0/24

topology:

  nodes:
    R01.SPB:
      kind: vr_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.101
      startup-config: configs/R01.SPB.rsc
    R01.HKI:
      kind: vr_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.102
      startup-config: configs/R01.HKI.rsc
    R01.MSK:
      kind: vr_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.103
      startup-config: configs/R01.MSK.rsc
    R01.LND:
      kind: vr_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.104
      startup-config: configs/R01.LND.rsc
    R01.LBN:
      kind: vr_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.105
      startup-config: configs/R01.LBN.rsc
    R01.NY:
      kind: vr_ros
      image: vrnetlab/mikrotik_routeros:6.47.9
      mgmt-ipv4: 172.10.0.106
      startup-config: configs/R01.NY.rsc
    PC1:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.10.0.2
      binds:
        - ./config:/config
      exec:
        - sh /config/PC.sh
    SGI-PRISM:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.10.0.3
      binds:
        - ./config:/config
      exec:
        - sh /config/PC.sh


  links:
    - endpoints: ["R01.SPB:eth1","R01.HKI:eth1"]
    - endpoints: ["R01.SPB:eth2","R01.MSK:eth1"]
    - endpoints: ["R01.SPB:eth3","PC1:eth1"]
    - endpoints: ["R01.HKI:eth3","R01.LBN:eth3"]
    - endpoints: ["R01.HKI:eth2","R01.LND:eth1"]
    - endpoints: ["R01.MSK:eth2","R01.LBN:eth1"]
    - endpoints: ["R01.LND:eth2","R01.NY:eth1"]
    - endpoints: ["R01.LBN:eth2","R01.NY:eth2"]
    - endpoints: ["R01.NY:eth3", "SGI-PRISM:eth1"]

```
# Конфиги

## Роутеры

В system identity указывается новый пользователь и удаляется админ, по классике. Дальше интересно:

1) Прописываем, как обычно, интерфейсы на всех портах по нарисованной схеме. Прописываем в роутерах NY и SPB dhcp-сервера.
2) Настраиваем динамическую маршрутизацию osfp:
- /interface bridge add name=loopback (в ospf хорошо использовать loopback, т.к. это интерфейс с IP-адресом, который никогда не упадёт без вмешательства администратора)
- /ip address interface=loopback
- /routing ospf instance (указываем в router-id адрес loopback интерфейса)
- /routing ospf area (всего 6 роутеров, достаточно одной зоны для всех устройств, например, 0.0.0.0)
- /routing ospf network (указываем имя зоны из предыдущего пункта, а в сетях все физические подключения)
3) Настраиваем MPLS:
- /mpls ldp (для transport-address тоже для удобства используем адрес loopback. В lsr-id можно тоже его указать, ведь адрес уникальный)
- /mpls ldp advertise-filter & accept-filter (Можно ограничить, какие префиксы сетей будут получать ярлыки. Необязательный пункт для нашей сети! Это актуально для больших корпоративных сетей. Я попробовала ввести префикс интерфейсов loopback-а, после чего связь по обычным адресам 10.20.x.x не сопровождается присваиванием ярлыков, а вот по адресам loopback-а в traceroute можно увидеть, как mpls включается в работу.)
/mpls ldp interface (просто указываем все интерфейсы роутеров)
4) Настраиваем VPLS (только на NY и SPB роутерах)
- /interface bridge (наш впн, который соединим с интерфейсом vpls и портом каким-нибудь)
- /interface vpls (remote-peer: айпи loopback-интерфейса другого роутера)
- /interface bridge port

R01
```
/user
add name=igor password=123 group=full
remove admin
/ip address
add address=10.10.1.2/30 interface=ether2
add address=10.10.2.1/30 interface=ether3
add address=10.10.5.1/30 interface=ether4

/interface bridge
add name=loopback
/ip address 
add address=10.255.255.3/32 interface=loopback network=10.255.255.3

/routing ospf instance
add name=inst router-id=10.255.255.3
set inst redistribute-connected=as-type-1
/routing ospf area
add name=backbonev28 area-id=0.0.0.0 instance=inst
/routing ospf network
add area=backbonev28 network=10.10.1.0/30
add area=backbonev28 network=10.10.2.0/30
add area=backbonev28 network=10.10.5.0/30
add area=backbonev28 network=10.255.255.3/32
/routing ospf instance set inst redistribute-connected=as-type-1

/mpls ldp
set lsr-id=10.255.255.3
set enabled=yes transport-address=10.255.255.3
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
set name=R01.HKI
```
## Компьютеры

Аналогично предыдущим работам, компьютеры запрашивают айпи у соответствующего dhcp-сервера на eth1.
```
#!/bin/sh
ip route del default via 172.10.0.1 dev eth0
udhcpc -i eth1
```

# Результаты

Доказательство работы OSPF:

```

Flags: X - disabled, A - active, D - dynamic, C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADC  10.10.1.0/30       10.10.1.2       ether2                    0
 1 ADC  10.10.2.0/30       10.10.2.1       ether3                    0
 2 ADo  10.10.3.0/30                       10.10.2.2               110
 3 ADo  10.10.4.0/30                       10.10.5.2               110
 4 ADC  10.10.5.0/30       10.10.5.1       ether4                    0
 5 ADo  10.10.6.0/30                       10.10.5.2               110
 6 ADo  10.10.7.0/30                       10.10.1.1               110
 7 ADo  10.255.255.2/32                    10.10.1.1               110
 8 ADC  10.255.255.3/32    10.255.255.3    loopback                  0
 9 ADo  10.255.255.4/32                    10.10.1.1               110
                                           10.10.5.2         
10 ADo  10.255.255.5/32                    10.10.5.2               110
11 ADo  10.255.255.6/32                    10.10.2.2               110
12 ADo  10.255.255.7/32                    10.10.5.2               110
                                           10.10.2.2         
13 ADC  172.31.255.28/30   172.31.255.30   ether1                    0
14 ADo  192.168.14.0/24                    10.10.5.2               110
                                           10.10.2.2         
15 ADo  192.168.28.0/24                    10.10.1.1               110
```

Доказательство работы MPLS:

```

Flags: H - hw-offload, L - ldp, V - vpls, T - traffic-eng 
 #    IN-LABEL                                      OUT-LABELS                                   DESTINATION                    INTERFACE                                   NEXTHOP        
 0    expl-null                                    
 1  L 16                                                                                         10.255.255.2/32                ether2                                      10.10.1.1      
 2  L 17                                            18                                           10.255.255.4/32                ether2                                      10.10.1.1      
 3  L 18                                                                                         10.255.255.5/32                ether4                                      10.10.5.2      
 4  L 19                                                                                         10.255.255.6/32                ether3                                      10.10.2.2      
 5  L 20                                            20                                           10.255.255.7/32                ether4                                      10.10.5.2
```

Доказательство работы EoMPLS:

```

       remote-label: 21
        local-label: 21
      remote-status: 
          transport: 10.255.255.2/32
  transport-nexthop: 10.10.3.1
     imposed-labels: 16,21
```

```

       remote-label: 21
        local-label: 21
      remote-status: 
  transport-nexthop: 10.10.1.2
     imposed-labels: 20,21
```

<img src="ping.png" width=500px>

# Заключение

В ходе выполнения работы была настроена динамическая маршрутизация через osfp, поверх чего была положена сеть mpls, а также был проведён туннель vpls между роутерами NY и SPB. Все устройства успешно соединены, задачи работы выполнены.

