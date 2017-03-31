Const ForReading = 1    
Const ForWriting = 2

strCurrentDirectory = left(WScript.ScriptFullName,(Len(WScript.ScriptFullName))-(len(WScript.ScriptName)))
strFileName = strCurrentDirectory + "Service References\GmCore\Reference.cs"



Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(strFileName, ForReading)
strText = objFile.ReadAll()
objFile.Close

strText = Replace(strText, "(GamMatrixAPI.GmCore.Game)", "(GamMatrixAPI.GreenTubeGame)")
strText = Replace(strText, "GamMatrixAPI.GmCore.Game ", "GamMatrixAPI.GreenTubeGame ")
strText = Replace(strText, "GamMatrixAPI.GmCore", "GamMatrixAPI")

strText = Replace(strText, " class Game ", " class GreenTubeGame ")
nIndex = InStr(strText,"namespace ") - 1
strText = RIGHT(strText,Len(strText)-nIndex)

Set objFile = objFSO.OpenTextFile(strFileName, ForWriting)
objFile.Write strText
objFile.Close