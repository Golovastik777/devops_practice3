University: [ITMO University](https://itmo.ru/ru/)<br />
Faculty: [FICT](https://fict.itmo.ru)<br />
Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)<br />
Year: 2025/2026<br />
Group: K3323<br />
Author: Yakovlev Igor Sergeevich<br />
Lab: Lab3<br />
Date of create: 14.12.25<br />
Date of finished: 14.12.25<br />

# Задание

Вам необходимо сделать IP/MPLS сеть связи для "RogaIKopita Games" изображенную на рисунке 1 в ContainerLab. Необходимо создать все устройства указанные на схеме и соединения между ними.

<img src="images/task.png" width=500px>

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
  network: custom_mgmt
  ipv4-subnet: 172.16.16.0/24

topology:
  kinds:
    vr-ros:
      image: vrnetlab/mikrotik_routeros:6.47.9

  nodes:
    R01.NY:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.101
      startup-config: config/r01-ny.rsc
    R02:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.102
      startup-config: config/r02.rsc
    R03:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.103
      startup-config: config/r03.rsc
    R04:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.104
      startup-config: config/r04.rsc
    R05:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.105
      startup-config: config/r05.rsc
    R06.SPB:
      kind: vr-ros
      mgmt-ipv4: 172.16.16.106
      startup-config: config/r06-spb.rsc
    SGI-Prism:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.16.16.2
      binds:
        - ./config:/config
      exec:
        - sh /config/sgi-prism.sh
    Engineer-PC:
      kind: linux
      image: alpine:latest
      mgmt-ipv4: 172.16.16.3
      binds:
        - ./config:/config
      exec:
        - sh /config/engineer-pc.sh

  links:
    - endpoints: ["R01.NY:eth1", "R02:eth1"]
    - endpoints: ["R02:eth2", "R03:eth1"]
    - endpoints: ["R03:eth2", "R04:eth1"]
    - endpoints: ["R04:eth2", "R05:eth1"]
    - endpoints: ["R05:eth2", "R06.SPB:eth1"]
    - endpoints: ["R01.NY:eth2", "SGI-Prism:eth1"]
    - endpoints: ["R06.SPB:eth2", "Engineer-PC:eth1"]
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
# Настройка пользователя
/user
add name=admin password=admin123 group=full

/system identity
set name=R01.NY

/interface bridge
add name=loopback
add name=vpls-bridge

add address=10.20.1.1/30 interface=ether1
add address=10.100.1.1/24 interface=ether2
add address=10.255.255.1/32 interface=loopback

/ip pool
add name=dhcp-pool ranges=10.100.1.10-10.100.1.254
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=ether2 name=dhcp-server
/ip dhcp-server network
add address=10.100.1.0/24 gateway=10.100.1.1

/routing ospf instance
set [ find default=yes ] router-id=10.255.255.1
/routing ospf area
add name=backbone area-id=0.0.0.0
/routing ospf interface
add interface=ether1
add interface=loopback
/routing ospf network
add area=backbone network=10.20.1.0/30
add area=backbone network=10.255.255.1/32

/mpls ldp
set enabled=yes lsr-id=10.255.255.1 transport-address=10.255.255.1
/mpls ldp interface
add interface=ether1

/interface vpls
add name=vpls-to-spb disabled=no remote-peer=10.255.255.6

/interface bridge port
add bridge=vpls-bridge interface=ether2
add bridge=vpls-bridge interface=vpls-to-spb
```
## Компьютеры

Аналогично предыдущим работам, компьютеры запрашивают айпи у соответствующего dhcp-сервера на eth1.
```
#!/bin/sh
ip route del default via 172.16.16.1 dev eth0
udhcpc -i eth1
ip addr add 10.100.2.100/24 dev eth1 2>/dev/null || true
```

# Результаты

## 1: OSPF

Проверяем динамическую маршрутизацию... через таблицы маршрутизации!

<img src="images/ospf-1.png" width=500px>
<img src="images/ospf-2.png" width=500px>
<img src="images/ospf-3.png" width=500px>
<img src="images/ospf-4.png" width=500px>
<img src="images/ospf-5.png" width=500px>
<img src="images/ospf-6.png" width=500px>

Как можно заметить, нигде статические маршруты не были прописаны, всё настроено динамически.

## 2: MPLS

Без фильтрации:

<img src="images/mpls-1.png" width=500px>
<img src="images/mpls-2.png" width=500px>
<img src="images/mpls-3.png" width=500px>
<img src="images/mpls-4.png" width=500px>
<img src="images/mpls-5.png" width=500px>
<img src="images/mpls-6.png" width=500px>

С фильтрацией:

<img src="images/mpls-filter.png" width=500px>

## 3: VPLS

<img src="images/vpls-1.png" width=500px>
<img src="images/vpls-2.png" width=500px>

<img src="images/vpls-3.png" width=500px>
<img src="images/vpls-4.png" width=500px>

## Соединение компьютеров

<img src="images/ping.png" width=500px>

# Заключение

В ходе выполнения работы была настроена динамическая маршрутизация через osfp, поверх чего была положена сеть mpls, а также был проведён туннель vpls между роутерами NY и SPB. Все устройства успешно соединены, задачи работы выполнены.

