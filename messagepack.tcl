package provide messagepack 0.1.0

namespace eval messagepack {
    variable id 0
    proc gensym {prefix} {
        variable id
        return "$prefix[incr id]"
    }
    
    proc unpack_and_callback {read out {eofvar ""} {count -1}} {
        if {$count == 0} return
        while {[set byte [{*}$read 1]] != ""} {
            binary scan $byte {c} byte
            if {$byte == 192} {
                # 0xc0: nil
                {*}$out ""
            } elseif {$byte == 194} {
                # 0xc2: false
                {*}$out false
            } elseif {$byte == 195} {
                # 0xc3: true
                {*}$out true
            } elseif {$byte >= 0 && $byte <= 127 ||
                      $byte >= -32 && $byte <= -1} {
                # 0XXXXXXX or 111YYYYY: positive/negative fixnum
                {*}$out $byte
            } elseif {$byte == -52} {
                # 0xcc: uint 8 
                set bytes [{*}$read 1]
                binary scan $bytes {c} num
                {*}$out [expr $num & 0xff]
            } elseif {$byte == -51} {
                # 0xcd: uint 16 
                set bytes [{*}$read 2]
                binary scan $bytes {S} num
                {*}$out [expr $num & 0xffff]
            } elseif {$byte == -50} {
                # 0xce: uint 32 
                set bytes [{*}$read 4]
                binary scan $bytes {I} num
                {*}$out [expr $num & 0xffffffff]
            } elseif {$byte == -49} {
                # 0xcf: uint 64 
                set bytes [{*}$read 8]
                binary scan $bytes {W} num
                {*}$out [expr $num & 0xffffffffffffffff]
            } elseif {$byte == -48} {
                # 0xd0: int 8 
                set bytes [{*}$read 1]
                binary scan $bytes {c} num
                {*}$out $num
            } elseif {$byte == -47} {
                # 0xd1: int 16 
                set bytes [{*}$read 2]
                binary scan $bytes {S} num
                {*}$out $num
            } elseif {$byte == -46} {
                # 0xd2: int 32 
                set bytes [{*}$read 4]
                binary scan $bytes {I} num
                {*}$out $num
            } elseif {$byte == -45} {
                # 0xd3: int 64 
                set bytes [{*}$read 8]
                binary scan $bytes {W} num
                {*}$out $num
            } elseif {$byte == -54} {
                # 0xca: float 32
                set bytes [{*}$read 4]
                binary scan $bytes {R} num
                {*}$out $num
            } elseif {$byte == -53} {
                # 0xcb: float 32
                set bytes [{*}$read 4]
                binary scan $bytes {Q} num
                {*}$out $num
            } elseif {$byte >= -96 && $byte <= -65} {
                # 101XXXXX: fixstr
                set len [expr {$byte & 0x1f}]
                {*}$out [list %str [{*}$read $len]]
            } elseif {$byte == -39} {
                # 0xd9: str 8
                set len [{*}$read 1]
                binary scan $len {c} len
                set len [expr {$len & 0xff}]
                {*}$out [list %str [{*}$read $len]]
            } elseif {$byte == -38} {
                # 0xda: str 16
                set len [{*}$read 2]
                binary scan $len {S} len
                set len [expr {$len & 0xffff}]
                {*}$out [list %str [{*}$read $len]]
            } elseif {$byte == -37} {
                # 0xdb: str 32
                set len [{*}$read 4]
                binary scan $len {I} len
                set len [expr {$len & 0xffffffff}]
                {*}$out [list %str [{*}$read $len]]
            } elseif {$byte == -60} {
                # 0xc4: bin 8
                set len [{*}$read 1]
                binary scan $len {c} len
                set len [expr {$len & 0xff}]
                {*}$out [list %bin [{*}$read $len]]
            } elseif {$byte == -59} {
                # 0xc5: bin 16
                set len [{*}$read 2]
                binary scan $len {S} len
                set len [expr {$len & 0xffff}]
                {*}$out [list %bin [{*}$read $len]]
            } elseif {$byte == -58} {
                # 0xc6: bin 32
                set len [{*}$read 4]
                binary scan $len {I} len
                set len [expr {$len & 0xffffffff}]
                {*}$out [list %bin [{*}$read $len]]
            } elseif {$byte >= -112 && $byte <= -97} {
                # 1001XXXX: fixarray
                set len [expr {$byte & 0x0f}]

                set nsname [gensym ns]
                namespace eval $nsname {
                    variable array [list %lst]
                }
                unpack_and_callback $read [list lappend ${nsname}::array] $eofvar $len
                {*}$out [set ${nsname}::array]
                namespace delete $nsname
            } elseif {$byte == -36} {
                # 0xdc: array 16
                set len [{*}$read 2]
                binary scan $len {S} len
                set len [expr {$len & 0xffff}]

                set nsname [gensym ns]
                namespace eval $nsname {
                    variable array [list %lst]
                }
                unpack_and_callback $read [list lappend ${nsname}::array] $eofvar $len
                {*}$out [set ${nsname}::array]
                namespace delete $nsname
            } elseif {$byte == -35} {
                # 0xdd: array 32
                set len [{*}$read 4]
                binary scan $len {I} len
                set len [expr {$len & 0xffffffff}]

                set nsname [gensym ns]
                namespace eval $nsname {
                    variable array [list %lst]
                }
                unpack_and_callback $read [list lappend ${nsname}::array] $eofvar $len
                {*}$out [set ${nsname}::array]
                namespace delete $nsname
            } elseif {$byte >= -128 && $byte <= -113} {
                # fixmap
                error {fixmap unimplemented}
            } elseif {$byte == -34} {
                # 0xde: map 16
                error {map 16 unimplemented}
            } elseif {$byte == -33} {
                # 0xdf: map 32
                error {map 32 unimplemented}
            } elseif {$byte == -44} {
                # 0xd4: fixext 1
                error {fixext 1 unimplemented}
            } elseif {$byte == -43} {
                # 0xd5: fixext 2
                error {fixext 2 unimplemented}
            } elseif {$byte == -42} {
                # 0xd6: fixext 4
                error {fixext 4 unimplemented}
            } elseif {$byte == -41} {
                # 0xd7: fixext 8
                error {fixext 8 unimplemented}
            } elseif {$byte == -40} {
                # 0xd8: fixext 16
                error {fixext 16 unimplemented}
            } elseif {$byte == -57} {
                # 0xc7: ext 8
                error {ext 8 unimplemented}
            } elseif {$byte == -56} {
                # 0xc8: ext 16
                error {ext 8 unimplemented}
            } elseif {$byte == -55} {
                # 0xc9: ext 32
                error {ext 8 unimplemented}
            } else {
                error "unknown byte: $byte"
            }
            incr count -1
            if {$count == 0} return
        }
        if {$eofvar != ""} {
            upvar $eofvar done
            set done true
        }
    }
}
