from collections import OrderedDict
import msgpack

map65535 = OrderedDict()
for n in xrange(0, 65535):
    map65535[n] = n

map65536 = OrderedDict()
for n in xrange(0, 65536):
    map65536[n] = n

fixture = {
    "nil": None,
    "true": True,
    "false": False,
    "0": 0,
    "127": 127,
    "128": 128,
    "255": 255,
    "256": 256,
    "65535": 65535,
    "65536": 65536,
    "4294967295": 4294967295,
    "4294967296": 4294967296,
    "18446744073709551615": 18446744073709551615,
    "map65535": map65535,
    "map65536": map65536,
}

for key in fixture:
    o = fixture[key]
    with open('t/fixture/' + key, 'w') as f:
        msgpack.pack(o, f)
