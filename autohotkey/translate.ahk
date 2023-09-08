/*
 * Translate
 * Author: LiuJiuzhou
 * Mail: 2267719005@qq.com
 * Date: 2021年2月11日
 */

; 选中文本后按 Ctrl + Space 翻译

#NoEnv	
#SingleInstance Force

Menu, tray, NoStandard	
Menu,tray,Add,Translate,Ctrl & Space
Menu, tray, Tip , Translate
Menu, tray, Add, About
Menu, tray, Add, Exit
Menu,tray,default,Translate
Menu, tray,Click,1

ToolTip The program has started in the tray. (程序启动在托盘)
Sleep 3000
ToolTip

Return

Ctrl & Space::
	翻译(选中的文本())
	return

About:
	Gui, FormTranslate:New,,Translate
	Gui, Font, Bold
	Gui, FormTranslate:Add, Text,,`nTranslate 1.0 `n`n
	Gui, Font, Norm
	Gui, Add, Link,, Selected text press Ctrl + Space `n`n`nQ Q：2267719005`n`nSite：<a href="http://3ghh.cn">http://3ghh.cn</a>
	Gui, FormTranslate:Add, Text,,
	Gui, FormTranslate:Add, Button, default w50 h25 x240, OK
	Gui, FormTranslate:Show,w300, Translate
	Return

FormTranslateButtonOK:
	WinClose, A
	return


Exit:
		ExitApp
	return


翻译(t="")
{
    global textRaw

    if(t="")
    {
        Gui, FormTranslate:New,,文本
        设置窗口样式()
        Gui, FormTranslate:Add, Edit, vtextRaw w350 r8 -WantReturn,%clipboard%
        Gui, FormTranslate:Add, Button, default w50 h25 x256,->中 ;加个按钮减55 x35
        Gui, FormTranslate:Add, Button, x+5 w50 h25,->EN
        Gui, FormTranslate:Show,, Translate
    }
    else
    {
        消息窗口(谷歌翻译(t))
    }
    return

    FormTranslateButton->中:
        Gui, FormTranslate:Submit    
        消息窗口(谷歌翻译(textRaw))
        Return
    FormTranslateButton->EN:
        Gui, FormTranslate:Submit
        消息窗口(必应词典(textRaw,"zh-Hans","en"))
        Return
    FormTranslateGuiEscape:
        WinClose,A
        Return
}

设置窗口样式()
{
    Gui +LastFound +Resize 
    Gui, Color,, ;窗口背景色 控件背景色
    Gui, Font, cgray, 等线 ; Microsoft JhengHei
}

HttpRequest(url,method:="GET",data:="")
{
    whr:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.SetTimeouts(0,500,30000,30000) ;解析,连接,发送,接收
    whr.Open(method, url, true)
    whr.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
    whr.SetRequestHeader("User-Agent","Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36 Edg/80.0.361.66")
    whr.Send(data)
    whr.WaitForResponse()
    return whr
}

谷歌翻译(content, src := "auto", dst := "zh")
{

    url := "http://translate.google.cn/translate_a/single?client=gtx&dt=t&dj=1&ie=UTF-8&sl=" src "&tl=" dst "&q=" content
	response:=HttpRequest(url).ResponseText
	obj := Jxon_Load(response)
	res:=""
	_enum := (obj.sentences)._NewEnum()
	while _enum.Next(Key, Value)
	{
		res:=res Value.trans "`r`n"	 
	}
	return res
}

必应词典(text,from="en",to="zh-Hans")
{
	url:="https://cn.bing.com/tlookupv3?isVertical=1&&IG=D736B3EDFC4E44BA8A0F6A85A50ADBFE&IID=translator.5027.7"
	data:="from=" from "&to=" to "&text=" text
    response:=HttpRequest(url,"POST",data).ResponseText
	obj := Jxon_Load(response)
	
	res:=""
	_enum := (obj.1.translations)._NewEnum()
		while _enum.Next(Key, Value)
		{
			r:="`t"
			_enu := (Value.backTranslations)._NewEnum()
			while _enu.Next(K, V)
			{
				r:=r V.normalizedText " , "
			}
			r:=SubStr(r, 1, -3) ;从字符串末尾删除2个字符
			if Value.transliteration
			transliteration:=" (" Value.transliteration ")"
			res:=res Value.normalizedTarget transliteration r "`r`n"
		}
	return res
}

消息窗口(文本,标题="")
{
    Gui, 消息窗口:New,,
    Gui +LastFound +Resize

    Gui, 消息窗口:Add, Edit,AW AH w350 Multi,%文本%
    Gui, 消息窗口:Add, Button, AX AY  w50 h25 xs x+-50  ,确定
    Gui, 消息窗口:Show,, %标题%
    ; 设置窗口最低高度
    WinGetPos , , , , h
    if h<=144
        WinMove, , , , , , 180
    Return

消息窗口GuiEscape:
    WinClose,A
    Return
消息窗口Button确定:
    WinClose,A
    Return
}

选中的文本()
{	
	_clipboard:=clipboard
	clipboard=
	Send ^c
	ClipWait 0.1
	if !ErrorLevel
	{
		result:=clipboard
		clipboard:=_clipboard
		return % result
	}
	else 
	{ 
		clipboard:=_clipboard
	}
}

Jxon_Load(ByRef src, args*)
{
	static q := Chr(34)

	key := "", is_key := false
	stack := [ tree := [] ]
	is_arr := { (tree): 1 }
	next := q . "{[01234567890-tfn"
	pos := 0
	while ( (ch := SubStr(src, ++pos, 1)) != "" )
	{
		if InStr(" `t`n`r", ch)
			continue
		if !InStr(next, ch, true)
		{
			ln := ObjLength(StrSplit(SubStr(src, 1, pos), "`n"))
			col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

			msg := Format("{}: line {} col {} (char {})"
			,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
			  : (next == "'")     ? "Unterminated string starting at"
			  : (next == "\")     ? "Invalid \escape"
			  : (next == ":")     ? "Expecting ':' delimiter"
			  : (next == q)       ? "Expecting object key enclosed in double quotes"
			  : (next == q . "}") ? "Expecting object key enclosed in double quotes or object closing '}'"
			  : (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
			  : (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
			  : [ "Expecting JSON value(string, number, [true, false, null], object or array)"
			    , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
			, ln, col, pos)

			throw Exception(msg, -1, ch)
		}

		is_array := is_arr[obj := stack[1]]

		if i := InStr("{[", ch)
		{
			val := (proto := args[i]) ? new proto : {}
			is_array? ObjPush(obj, val) : obj[key] := val
			ObjInsertAt(stack, 1, val)
			
			is_arr[val] := !(is_key := ch == "{")
			next := q . (is_key ? "}" : "{[]0123456789-tfn")
		}

		else if InStr("}]", ch)
		{
			ObjRemoveAt(stack, 1)
			next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
		}

		else if InStr(",:", ch)
		{
			is_key := (!is_array && ch == ",")
			next := is_key ? q : q . "{[0123456789-tfn"
		}

		else ; string | number | true | false | null
		{
			if (ch == q) ; string
			{
				i := pos
				while i := InStr(src, q,, i+1)
				{
					val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
					static end := A_AhkVersion<"2" ? 0 : -1
					if (SubStr(val, end) != "\")
						break
				}
				if !i ? (pos--, next := "'") : 0
					continue

				pos := i ; update pos

				  val := StrReplace(val,    "\/",  "/")
				, val := StrReplace(val, "\" . q,    q)
				, val := StrReplace(val,    "\b", "`b")
				, val := StrReplace(val,    "\f", "`f")
				, val := StrReplace(val,    "\n", "`n")
				, val := StrReplace(val,    "\r", "`r")
				, val := StrReplace(val,    "\t", "`t")

				i := 0
				while i := InStr(val, "\",, i+1)
				{
					if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
						continue 2

					; \uXXXX - JSON unicode escape sequence
					xxxx := Abs("0x" . SubStr(val, i+2, 4))
					if (A_IsUnicode || xxxx < 0x100)
						val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
				}

				if is_key
				{
					key := val, next := ":"
					continue
				}
			}

			else ; number | true | false | null
			{
				val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
			
			; For numerical values, numerify integers and keep floats as is.
			; I'm not yet sure if I should numerify floats in v2.0-a ...
				static number := "number", integer := "integer"
				if val is %number%
				{
					if val is %integer%
						val += 0
				}
			; in v1.1, true,false,A_PtrSize,A_IsUnicode,A_Index,A_EventInfo,
			; SOMETIMES return strings due to certain optimizations. Since it
			; is just 'SOMETIMES', numerify to be consistent w/ v2.0-a
				else if (val == "true" || val == "false")
					val := %value% + 0
			; AHK_H has built-in null, can't do 'val := %value%' where value == "null"
			; as it would raise an exception in AHK_H(overriding built-in var)
				else if (val == "null")
					val := ""
			; any other values are invalid, continue to trigger error
				else if (pos--, next := "#")
					continue
				
				pos += i-1
			}
			
			is_array? ObjPush(obj, val) : obj[key] := val
			next := obj==tree ? "" : is_array ? ",]" : ",}"
		}
	}

	return tree[1]
}
