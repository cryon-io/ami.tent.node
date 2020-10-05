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
    },
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

#### Cloning masternode:
1. Let's say we have one masternode in directory /mns/xsg1. We want to create another one in /mns/xsg2, so first we have to stop first masternode using command:
`ami --path=/mns/xsg1 stop`
2. We create a directory for masternode 2 using command:
`mkdir /mns/xsg2`
3. Next we copy all the files from /mns/xsg1 to /mns/xsg2 recursively:
`cp -R /mns/xsg1/* /mns/xsg2`
4. Then remember to edit app.json file in /mns/xsg2
5. Rebuild configuration for new MN:
`ami --path=/mns/xsg2 setup`
6. Start new MN:
`ami --path=/mns/xsg2 start`
7. Don't forget to start source MN which we stopped in first step:
`ami --path=/mns/xsg1 start`
8. Check if both masternodes are running well:
`ami --path=/mns/xsg1 info`
`ami --path=/mns/xsg2 info`


#### Troubleshooting 

Run ami with `-ll=trace` to enable trace level printout, e.g.:
`ami --path=/mns/xsg1 -ll=trace setup`
