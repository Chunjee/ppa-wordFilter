#NoEnv
#NoTrayIcon
SetBatchLines, -1
#SingleInstance force

#Include html_gui.ahk

#Include %A_ScriptDir%\node_modules
#Include biga.ahk\export.ahk
#Include array.ahk\export.ahk
#Include neutron.ahk\export.ahk


global A := new biga()

; Create a new NeutronWindow and navigate to our HTML page
neutron := new NeutronWindow()
neutron.Load("gui\index.html")
; Use the Gui method to set a custom label prefix for GUI events.
neutron.Gui("+LabelNeutron")
neutron.Show("w1400 h1000")


; read and parse needed stuff from cars object
FileRead, outputVar, % A_ScriptDir "\words.txt"
global wordsArr := A.map(strSplit(OutputVar, "`n", "`r"), A.trim)
return


; find button
fn_submit(neutron, event)
{
	; clear gui since this process may take a second or so
	neutron.qs("#ahk_output").innerHTML := ""

	; form will redirect the page by default, but we want to handle the form data ourself.
	event.preventDefault()

	; Use Neutron's GetFormData method to process the form data into a form that is easily accessed
	formData := neutron.GetFormData(event.target)

	; formData
	; "input1":"S", "input2":"H", "input3":"A", "input4":"", "input5":"", "validletters":"", "blacklistedletters":""

	canidatesArr := []
	; remove blacklisted letter words
	for _, word in wordsArr {
		thisWord := strSplit(word)
		if (A.size(formData.blacklistedletters) == 0) {
			canidatesArr.push(thisWord)
		} else {
			eachBlacklistedLetters := strSplit(formData.blacklistedletters)
			if (A.intersection(thisWord, eachBlacklistedLetters).length() == 0) {
				canidatesArr.push(thisWord)
			}
		}
	}

	; remove words that don't contain valid letters
	if (!A.size(formData.validletters) == 0) {
		canidatesArr2 := []
		for _, thisWord in canidatesArr {
			eachValidLetters := strSplit(formData.validletters)
			if (A.intersection(thisWord, eachValidLetters).length() > 0) {
				canidatesArr2.push(thisWord)
			}
		}
		canidatesArr := canidatesArr2.clone()
	}


	; build valid letters object
	idealCanidateFn := A.matches(fn_customCompact({1: formData.input1, 2: formData.input2, 3: formData.input3, 4: formData.input4, 5: formData.input5}))
	; print(canidatesArr)
	canidatesArr := A.filter(canidatesArr, idealCanidateFn)
	canidatesArrOutput := []
	for _, wordArr in canidatesArr {
		canidatesArrOutput.push({"word": A.join(wordArr, "")})
	}

	html := gui_generateTable(canidatesArrOutput, ["word"])
	neutron.qs("#ahk_output").innerHTML := html
}


; fileInstall all dependencies
fileInstall, gui\Bootstrap.html, gui\Bootstrap.html
fileInstall, gui\bootstrap.min.css, gui\bootstrap.min.css
fileInstall, gui\bootstrap.min.js, gui\bootstrap.min.js
fileInstall, gui\jquery.min.js, gui\jquery.min.js

NeutronClose:
exitApp
return



; ------------------
; functions
; ------------------

fn_customCompact(param_arr)
{
	l_obj := {}

	; create
	for key, value in param_arr {
		if (value == "" || value == 0) {
			continue
		}
		l_obj[key] := value
	}
	return l_obj
}
