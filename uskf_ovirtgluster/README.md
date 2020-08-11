# uskf_ovirtgluster

oVirt HCI(Gluster)の物理ホストを構成するCookbook

oVirt用のGlusterボリューム（レプリカ３）を作成する。
Thinホストクラスタの場合、イメージバージョンをチェックして、各メジャーバージョンの最終リリースの場合、レポジトリを次のメジャーバージョンに切り替える

## Requirements

### Platforms
- CentOS 7 (oVirt 4.1～4.3)
- CentOS 8 (oVirt 4.4～)

### Chef

- Chef 14

### Cookbooks

## Recipes

### default

## Usage

## Attributes

|Key|Type|Description|
|:---|:---|:---|
|['ovirtgluster']['engine_fqdn']|String|Engine VM FQDN|
|['ovirtgluster']['peers']|Array|Gluster peer hostname & IP Address|
|['ovirtgluster']['peers'][n]['hostname']|String|Gluster Node Hostname|
|['ovirtgluster']['peers'][n]['peername']|String|Gluster Node Peer Name|
|['ovirtgluster']['peers'][n]['peeraddress']|String|Gluster Node Peer IPv4 Address|
|['ovirtgluster']['volumes']|Array|Gluster Volume Configuration|
|['ovirtgluster']['volumes'][n]['name']|String|Gluster Volume Name|
|['ovirtgluster']['volumes'][n]['brick']|String|Gluster Volume Brick path|

```json
"ovirtgluster": {
    "engine_fqdn": "ovirt.jail",
    "peers": [
        {
        "hostname": "hci1.jail",
        "peername": "hci1-gluster.jail",
        "peeraddress": "192.168.30.211"
        },
        {
        "hostname": "hci2.jail",
        "peername": "hci2-gluster.jail",
        "peeraddress": "192.168.30.212"
        },
        {
        "hostname": "hci3.jail",
        "peername": "hci3-gluster.jail",
        "peeraddress": "192.168.30.213"
        }
    ],
    "volumes": [
        {
        "name": "engine",
        "brick": "/gluster_bricks/engine/engine"
        },
        {
        "name": "data_vm1",
        "brick": "/gluster_bricks/data_vm1/data_vm1"
        },
        {
        "name": "data_vm2",
        "brick": "/gluster_bricks/data_vm2/data_vm2"
        }
    ]
}

```

## License & Authors

**Author**:uskf
