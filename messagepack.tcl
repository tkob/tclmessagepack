package provide messagepack 0.1.0

namespace eval messagepack {
    variable id 0
    proc gensym {prefix} {
        variable id
        return "$prefix[incr id]"
    }
    
    proc unpack_and_callback {read out {ext cons_ext} {eofvar ""} {count -1}} {
        if {$count == 0} return
        while {[set byte [{*}$read 1]] != ""} {
            binary scan $byte {c} byte
            if {$byte == -64} {
                # 0xc0: nil
                {*}$out %nil
            } elseif {$byte == -62} {
                # 0xc2: false
                {*}$out false
            } elseif {$byte == -61} {
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
                # 0xcb: float 64
                set bytes [{*}$read 8]
                binary scan $bytes {Q} num
                {*}$out $num
            } elseif {$byte >= -96 && $byte <= -65} {
                # 101XXXXX: fixstr
                set len [expr {$byte & 0x1f}]
                {*}$out [list %str [encoding convertfrom utf-8 [{*}$read $len]]]
            } elseif {$byte == -39} {
                # 0xd9: str 8
                set len [{*}$read 1]
                binary scan $len {c} len
                set len [expr {$len & 0xff}]
                {*}$out [list %str [encoding convertfrom utf-8 [{*}$read $len]]]
            } elseif {$byte == -38} {
                # 0xda: str 16
                set len [{*}$read 2]
                binary scan $len {S} len
                set len [expr {$len & 0xffff}]
                {*}$out [list %str [encoding convertfrom utf-8 [{*}$read $len]]]
            } elseif {$byte == -37} {
                # 0xdb: str 32
                set len [{*}$read 4]
                binary scan $len {I} len
                set len [expr {$len & 0xffffffff}]
                {*}$out [list %str [encoding convertfrom utf-8 [{*}$read $len]]]
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
                unpack_and_callback $read [list lappend ${nsname}::array] $ext $eofvar $len
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
                unpack_and_callback $read [list lappend ${nsname}::array] $ext $eofvar $len
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
                unpack_and_callback $read [list lappend ${nsname}::array] $ext $eofvar $len
                {*}$out [set ${nsname}::array]
                namespace delete $nsname
            } elseif {$byte >= -128 && $byte <= -113} {
                # 1000XXXX: fixmap
                set len [expr {($byte & 0x0f) * 2}]

                set nsname [gensym ns]
                namespace eval $nsname {
                    variable dict [list]
                }
                unpack_and_callback $read [list lappend ${nsname}::dict] $ext $eofvar $len
                {*}$out [list %map [set ${nsname}::dict]]
                namespace delete $nsname
            } elseif {$byte == -34} {
                # 0xde: map 16
                set len [{*}$read 2]
                binary scan $len {S} len
                set len [expr {($len & 0xffff) * 2}]

                set nsname [gensym ns]
                namespace eval $nsname {
                    variable dict [list]
                }
                unpack_and_callback $read [list lappend ${nsname}::dict] $ext $eofvar $len
                {*}$out [list %map [set ${nsname}::dict]]
                namespace delete $nsname
            } elseif {$byte == -33} {
                # 0xdf: map 32
                set len [{*}$read 4]
                binary scan $len {I} len
                set len [expr {($len & 0xffffffff) * 2}]

                set nsname [gensym ns]
                namespace eval $nsname {
                    variable dict [list]
                }
                unpack_and_callback $read [list lappend ${nsname}::dict] $ext $eofvar $len
                {*}$out [list %map [set ${nsname}::dict]]
                namespace delete $nsname
            } elseif {$byte == -44} {
                # 0xd4: fixext 1
                set type [{*}$read 1]
                binary scan $type {c} type
                set data [{*}$read 1]
                {*}$out [{*}$ext $type $data]
            } elseif {$byte == -43} {
                # 0xd5: fixext 2
                set type [{*}$read 1]
                binary scan $type {c} type
                set data [{*}$read 2]
                {*}$out [{*}$ext $type $data]
            } elseif {$byte == -42} {
                # 0xd6: fixext 4
                set type [{*}$read 1]
                binary scan $type {c} type
                set data [{*}$read 4]
                {*}$out [{*}$ext $type $data]
            } elseif {$byte == -41} {
                # 0xd7: fixext 8
                set type [{*}$read 1]
                binary scan $type {c} type
                set data [{*}$read 8]
                {*}$out [{*}$ext $type $data]
            } elseif {$byte == -40} {
                # 0xd8: fixext 16
                set type [{*}$read 1]
                binary scan $type {c} type
                set data [{*}$read 16]
                {*}$out [{*}$ext $type $data]
            } elseif {$byte == -57} {
                # 0xc7: ext 8
                set len [{*}$read 1]
                binary scan $len {c} len
                set len [expr {$len & 0xff}]
                set type [{*}$read 1]
                binary scan $type {c} type
                set data [{*}$read $len]
                {*}$out [{*}$ext $type $data]
            } elseif {$byte == -56} {
                # 0xc8: ext 16
                set len [{*}$read 2]
                binary scan $len {S} len
                set len [expr {$len & 0xffff}]
                set type [{*}$read 1]
                binary scan $type {c} type
                set data [{*}$read $len]
                {*}$out [{*}$ext $type $data]
            } elseif {$byte == -55} {
                # 0xc9: ext 32
                set len [{*}$read 4]
                binary scan $len {I} len
                set len [expr {$len & 0xffffffff}]
                set type [{*}$read 1]
                binary scan $type {c} type
                set data [{*}$read $len]
                {*}$out [{*}$ext $type $data]
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

    proc read_string {source nsname num} {
        namespace upvar $nsname cursor cursor
        set data [string range $source $cursor [expr {$cursor + $num - 1}]]
        set len [string length $data]
        set cursor [expr {$cursor + $len}]
        return $data
    }

    proc cons_ext {type data} {
        return [list %ext $type $data]
    }

    proc unpack_string {data} {
        set nsname [gensym ns]
        namespace eval $nsname {
            variable cursor 0
            variable sink [list]
        }

        unpack_and_callback [list read_string $data $nsname] [list lappend ${nsname}::sink]

        set result [set ${nsname}::sink]
        namespace delete $nsname
        return $result
    }

    proc unpack_chan {channelId} {
        set nsname [gensym ns]
        namespace eval $nsname {
            variable sink [list]
        }

        unpack_and_callback [list chan read $channelId] [list lappend ${nsname}::sink]

        set result [set ${nsname}::sink]
        namespace delete $nsname
        return $result
    }

    proc unpack_file {fileName} {
        set f [open $fileName]
        try {
            fconfigure $f -translation binary
            return [unpack_chan $f]
        } finally {
            close $f
        }
    }

    namespace export unpack_*
}
