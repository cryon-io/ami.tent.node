### xsg.node

SnowGem node AMI app.

**All commands should be executed as root or with `sudo`.**

#### Setup

1. Install `ami` if not installed already
    * `wget https://raw.githubusercontent.com/cryon-io/ami/master/install.sh -O /tmp/install.sh && sh /tmp/install.sh`
2. Create directory for your application (it should not be part of user home folder structure, you can use for example `/mns/xsg1`)
3. Create `app.json` or `app.hjson` with app configuration you like, e.g.:
```json
{
    "id": "xsg22",
    "type": "xsg.node",
    "configuration": {
        "DAEMON_CONFIGURATION": {
            "bind": "aaa.bbb.ccc.ddd",
            "rpcbind": "127.0.0.22",
            "port": 16113,
            "listen": 1,
            "server": 1,
            "txindex": 1,
            "masternode": 1,
            "rpcallowip": "127.0.0.0/8",
            "masternodeprivkey": "5JM..........QYhRN"
        }
    }
    "user": "xsg1"
}
```
Above example is a config file for 22nd masternode. Depending on the node You have to change these lines:
```
 "id": "xsg22",
 "bind": "aaa.bbb.ccc.ddd",
 "rpcbind": "127.0.0.22",
 "masternodeprivkey": "5JM..........QYhRN"
 ```
As You can see '22' appears in 'id' and 'rpcbind' IP. Of course each masternode uses different external IP and Private key ('masternodeprivkey'). 
 

4. Run `ami --path=<your app path> setup`
   * e.g. `ami --path=/mns/xsg1`
. Run `ami --path=<your app path> --help` to investigate available commands
5. Start your node with `ami --path=<your app path> start`
6. Check info about the node `ami --path=<your app path> info`

##### Configuration change: 
1. `ami --path=<your app path> stop`
2. change app.json or app.hjson as you like
3. `ami --path=<your app path> setup --configure`
4. `ami --path=<your app path> start`

##### Remove app: 
1. `ami --path=<your app path> stop`
2. `ami --path=<your app path> remove --all`

##### Reset app:
1. `ami --path=<your app path> stop`
2. `ami --path=<your app path> remove` - removes app data only
3. `ami --path=<your app path> start`

##### Remove snowgemd database: 
1. `ami --path=<your app path> stop`
2. `ami --path=<your app path> removedb`
3. `ami --path=<your app path> start`

#### Troubleshooting 

Run ami with `-ll=trace` to enable trace level printout, e.g.:
`ami --path=/mns/xsg1 -ll=trace setup`
