
#NoEnv
SendMode, Input
SetCapsLockState, AlwaysOff




CapsLock & w::
	send {blind}{up}
	return


CapsLock & s::
	send {blind}{down}
	return


CapsLock & a::
	send {blind}{left}
	return


CapsLock & d::
	send {blind}{right}
	return

CapsLock & r::
	send {blind}{backspace}
	return

CapsLock & q::
	send ^{left}
	return

CapsLock & e::
	send ^{right}
	return

CapsLock & z::
	send {blind}{home}
	return

CapsLock & x::
	send {blind}{end}
	return

CapsLock & f::
	send {blind}{enter}
	return

CapsLock & c::
	send {blind}{pgup}
	return

CapsLock & v::
	send {blind}{pgdn}
	return


<!,::
	send ，
	return
<!+,::
	send 《
	return
<!.::
	send 。
	return
<!+.::
	send 》
	return
<!/::
	send 、
	return
<!+/::
	send ？
	return

<![::
	send 【
	return

<!]::
	send 】
	return

<!9::
	send （
	return

<!0::
	send ）
	return