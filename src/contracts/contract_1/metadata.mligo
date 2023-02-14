type t = (string,bytes) big_map

let metadata = [%bytes
{|{
	"name":"WULF FA2",
	"description":"Example FA2 implementation",
	"version":"0.1.0",
	"license":{"name":"MIT"},
	"authors":["Pierre-Emmanuel Wulfman<pierre-emmanuel@wulfman.fr>"],
	"homepage":"",
	"source":{"tools":["Ligo"], "location":"https://github.com/pewulfman/Tezos-TZIP-implementation/blob/main/TZIP-12%20(FA2)%20/"},
	"interfaces":["TZIP-012"],
	"errors":[],
	"views":[]

}|}]

let init () : t = Big_map.literal [
	("", [%bytes {|tezos-storage:data|}]);
	("data", metadata);
]