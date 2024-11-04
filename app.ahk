#NoEnv
#NoTrayIcon
SetBatchLines, -1
#SingleInstance force

#Include html_gui.ahk

#Include %A_ScriptDir%\node_modules
#Include biga.ahk\export.ahk
#Include array.ahk\export.ahk
#Include neutron.ahk\export.ahk

; other dependancies
fileInstall, words.txt, words.txt

; variables
global A := new biga()
global commonAlpha := ["e", "a", "r", "i", "o", "t", "n", "s", "l", "c", "u", "d", "p", "m", "h", "g", "b", "f", "y", "w", "k", "v"
, "x", "z", "j", "q"]

global exploreWordsFlat
; global exploreWordsFlat


; Create a new NeutronWindow and navigate to our HTML page
neutron := new NeutronWindow()
neutron.Load("gui\index.html")
; Use the Gui method to set a custom label prefix for GUI events.
neutron.Gui("+LabelNeutron")
neutron.Show()


; read and parse needed stuff from cars object
FileRead, outputVar, % A_ScriptDir "\words.txt"
global wordsArr := A.map(strSplit(OutputVar, "`n", "`r"), A.trim)
return


; find button
fn_submit(neutron, event)
{
	; clear gui since this process may take a second or so
	neutron.qs("#ahk_output").innerHTML := ""
	neutron.qs("#ahk_canidatesCount").innerHTML := ""
	neutron.qs("#ahk_exploreoutput").innerHTML := ""
	neutron.qs("#ahk_proboutput").innerHTML := ""

	; form will redirect the page by default, but we want to handle the form data ourself.
	event.preventDefault()

	; Use Neutron's GetFormData method to process the form data into a form that is easily accessed
	formData := neutron.GetFormData(event.target)

	; formData
	; => {"input1":"", "input2":"", "input3":"", "input4":"", "input5":"", "blacklistedletters":"", "wrong1":"", "wrong2":"", "wrong3":"", "wrong4":"", "wrong5":""}

	; build valid letters object
	validletters := A.concat([], formData.wrong1, formData.wrong2, formData.wrong3, formData.wrong4, formData.wrong5)
	validletters := A.concat(validletters, formData.input1, formData.input2, formData.input3, formData.input4, formData.input5)
	validletters := A.compact(A.map(validletters, A.toLower))
	validletters := A.uniq(strSplit(A.join(validletters, "")))
	; do nothing if form is blank
	if (A.size(formData.blacklistedletters) == 0 && A.size(validletters) == 0) {
		return
	}

	canidatesArr := []
	blocklistedLetters := []
	; remove blacklisted letter words
	for _, word in wordsArr {
		thisWord := strSplit(word)
		if (A.size(formData.blacklistedletters) == 0) {
			canidatesArr.push(thisWord)
		} else {
			blocklistedLetters := A.uniq(A.compact(strSplit(formData.blacklistedletters)))
			blocklistedLetters := A.difference(blocklistedLetters, validletters)
			if (A.intersection(thisWord, blocklistedLetters).length() == 0) {
				canidatesArr.push(thisWord)
			}
		}
	}

	; remove words that don't contain all valid letters
	if (A.size(validletters) != 0) {
		canidatesArr2 := []
		for _, thisWord in canidatesArr {
			eachValidLetters := A.compact(validletters)
			if (A.intersection(thisWord, eachValidLetters).length() >= eachValidLetters.length()) {
				canidatesArr2.push(thisWord)
			}
		}
		canidatesArr := canidatesArr2.clone()
	}


	; build ideal letters object
	idealCanidateFn := A.matches(fn_customCompact({1: formData.input1, 2: formData.input2, 3: formData.input3, 4: formData.input4, 5: formData.input5}))
	; filter by ideal object
	canidatesArr := A.filter(canidatesArr, idealCanidateFn)


	; Correct letter, wrong spot
	; uses biga.reject to filter impossible words
	canidatesArr := fn_createAndFindAllMatches(canidatesArr, {1: formData.wrong1, 2: formData.wrong2, 3: formData.wrong3, 4: formData.wrong4, 5: formData.wrong5})

	; turn array into keyed array for html output
	; also .join any WordArr to a string
	canidatesArrOutput := []
	for _, wordArr in canidatesArr {
		canidatesArrOutput.push(biga.join(wordArr, ""))
	}

	html := gui_generateTable(A.chunk(canidatesArrOutput, 5), [1,2,3,4,5], false)
	neutron.qs("#ahk_output").innerHTML := html
	neutron.qs("#ahk_canidatesCount").innerHTML := canidatesArrOutput.count() " canidate words"

	; --- letter probablities ---
	; get the count of all remaining letters (valid letters will be 100% and blacklist will be 0%)
	letterProbabilitiesArr := fn_findAllLetterPobabilities(canidatesArr, validletters, blocklistedLetters)
	letterProbabilitiesTxt := fn_makeLetterProbablesHumanReadible(letterProbabilitiesArr)
	html := gui_generateTable(A.chunk(letterProbabilitiesTxt, 5), [1,2,3,4,5], false)
	neutron.qs("#ahk_proboutput").innerHTML := html

	; --- exploritory words ---
	exploreWords := fn_scoreWordSuggestions(wordsArr, letterProbabilitiesArr)
	exploreWordsFlat := []
	for key, value in exploreWords {
		exploreWordsFlat.push(value.word)
	}
	html := gui_generateTable(A.chunk(exploreWordsFlat, 5), [1,2,3,4,5], false)
	neutron.qs("#ahk_exploreoutput").innerHTML := html
}


fn_filter(neutron, event)
{
	event.preventDefault()
	formData := neutron.GetFormData(event.target)

	filteredSuggestions := []
	filterVals := biga.uniq(strSplit(formData.filtervals))
	for _, value in exploreWordsFlat {
		gateVar := true
		for _, letter in filterVals {
			if (!A.includes(value, letter)) {
				gateVar := false
			}
		}
		if (gateVar) {
			filteredSuggestions.push(value)
		}
	}
	html := gui_generateTable(A.chunk(filteredSuggestions, 5), [1,2,3,4,5], false)
	neutron.qs("#ahk_exploreoutput").innerHTML := html
}

; fileInstall all dependencies
fileInstall, gui\index.html, gui\index.html
fileInstall, gui\bootstrap.min.css, gui\bootstrap.min.css
fileInstall, gui\bootstrap.min.js, gui\bootstrap.min.js
fileInstall, gui\jquery.min.js, gui\jquery.min.js

NeutronClose:
exitApp
return

; ------------------
; subroutines
; ------------------

fn_scoreWordSuggestions(param_canidatesArr, param_remainingcharacters)
{
	canidatesArr := []
	for _, word in param_canidatesArr {
		letters := biga.uniq(strSplit(word))
		score := 0
		for _, letter in letters {
			score += biga.find(param_remainingcharacters, {"char": letter}).prob
		}
		; remember the word and uniq unknown letters
		canidatesArr.push({"word": word, "score": score})
	}
	; sort and reverse (larger missing numbers to smallest)
	return biga.reverse(biga.sortBy(canidatesArr, "score"))
}

; of remaining words, sort by ones with most missing characters
fn_sortByMissing(param_canidatesArr, param_remainingcharacters)
{
	canidatesArr := []
	for _, word in param_canidatesArr {
		letters := biga.intersection(strSplit(word), param_remainingcharacters)
		; remember the word and uniq unknown letters
		canidatesArr.push({"word": word, "letters": biga.size(biga.uniq(letters))})
	}
	; sort and reverse (larger missing numbers to smallest)
	return biga.reverse(biga.sortBy(canidatesArr, "letters"))
}

fn_findAllLetterPobabilities(param_haystack, param_validletters, param_blacklistletters)
{
	; get count of all letters in haystack
	flatstack := biga.flatten(param_haystack)

	; remove a blacklisted and valid letters
	filteredstack := []
	for key, letter in flatstack {
		if (!biga.includes(param_blacklistletters, letter) && !biga.includes(param_validletters, letter)) {
			filteredstack.push(letter)
		}
	}

	; sum of all letters
	freqArr := fn_frequencies(filteredstack)
	sum := biga.sum(freqArr)

	; find percent of each character
	probArr := []
	for key, value in freqArr {
		probArr.push({"prob": biga.round(biga.ceil((value / sum) * 100, 1), 1), "char": key})
	}
	; sort by highest to lowest
	probArr := biga.reverse(biga.sortBy(probArr, "prob"))
	return probArr
}

fn_makeLetterProbablesHumanReadible(param_arr)
{
	; convert to human readable string for html output
	readableOutput := []
	for key, value in param_arr {
		readableOutput.push(biga.toUpper(value.char) " " value.prob "%")
	}
	return readableOutput
}

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

fn_createAndFindAllMatches(param_haystack, param_object)
{
	for key, value in param_object {
		value := biga.toArray(value)
		for key2, value2 in value {
			param_haystack := biga.reject(param_haystack, biga.matchesProperty(key, value2))
			; msgbox, % biga.print(key ": " value2 " found these: " biga.print(param_haystack))
		}
	}
	return param_haystack
}

fn_joinDeep(param_array)
{
	l_array := []
	for _, value in param_array {
		l_array.push(biga.join(value, ""))
	}
	return l_array
}

fn_chunkTable(param_data)
{
	; would be nice if this lined them verticle, currently horizontal
	l_data := biga.chunk(param_data, 5)
	return l_data
}

fn_frequencies(param_array) {
	; prepare
	if (!isObject(param_array)) {
		param_array := strSplit(param_array)
	}

	; create
	l_array := []
	for key, value in param_array {
		if (l_array[value] == "") {
			l_array[value] := 0
		}
		l_array[value] := l_array[value] + 1
	}
	return l_array
}
