Rem

Build new style docs.

Only builds official docs and brl, maxgui and pub modules.

Calls 'docmods' first, which builds 3rd party modules.


v.1.2 Degac
	+ added support for external commands to highlight in the IDE in /doc/bmxmods/commands.txt
	+ excluding module to NOT scan (just add in command line ie: pub.glew)
	+ support more than ONE example for command: just put in the DOC folder 
	  some .bmx files starting with THE SAME name of the 'command'
	  ie: AllocChannel.bmx AllocChannel.2.bmx AlloChannelanotherone.bmx
	
	  they will be loaded in the local help

v.1.3 Degac 22 oct 2017

	+ support for CMD LINE arguments
	  if there's no '-' (as in -help or -version) this means old way: only modules to skip

v.1.4 Degac 26-dec-2017
	
	+ added NAVIGATION_PATH to generated HTML pages


End Rem

Strict

Framework BRL.Basic



'Global html_root:String=BlitzMaxPath()+"/docs/htmls/index.html"


Import "docnode.bmx"
Import "fredborgstyle.bmx"

system_ "~q"+BlitzMaxPath()+"/bin/docmods~q"
'---------------------------------------------- degac ------------
Global args:String[]=AppArgs  'degac
Global exc:String[]


Rem
		v.1.3	
				arguments	
				-exclude=a,b,c	    =used to exclude some modules to be analyzed
				-version			    =to report version
				-help, -h			    =to report this help
				-extern=filename.txt =to add new commands to highlighter



End Rem
Local newway:Int,extcommands$
For Local cmd$=EachIn args
	
	If cmd.tolower().startswith("-")=True Then newway=1
	If cmd.tolower().startswith("-version")	Print "MakeDocs - version 1.3";End
	If cmd.tolower().startswith("-h") Or cmd.tolower().startswith("-help")
		Print "~nMakeDocs - version 1.3~n"
		Print "Usage"
		Print "-exclude=mod1.mod,mod2.mod    to exclude module Mod1.mod, Mod2.mod etc"
		Print "-version                      to show current version"
		Print "-extern=file_path.txt         a .txt to add new commands to be highlighted"
		Print "-h, -help	                to show this help."
		End
	End If
	
	If cmd.tolower().startswith("-extern=")
	'add support for external commands
	extcommands=cmd[8..].Trim()	
	'Print "External command list <"+extcommands+">"
	End If
	
	If cmd.tolower().startswith("-exclude=")
		exc=cmd[9..].Trim().split(",")
	End If
	
Next
If newway=0
		 exc=args;Print "Old way on...."
		For Local e$=EachIn exc
			Print "Module to exclude <"+e+">"		
		Next
End If

Print "External commands : "+extcommands
Print "Modules to skip   : "+exc.length



'---------------------------------------------- degac - end ------------

Local style:TDocStyle=New TFredborgStyle

DeleteDir BmxDocDir,True

CopyDir BlitzMaxPath()+"/docs/src",BmxDocDir

Local root:TDocNode=TDocNode.Create( "BlitzMax Help","/","/" )
root.about=LoadText( BmxDocDir+"/index.html" )
'html_root=BmxDocDir+"/index.html"

'Print "DocMods"
DocMods
'Print "DocBBDocs"
DocBBDocs "/"
'Print "Commands"
style.EmitDoc TDocNode.ForPath( "/" )
Local t$
For Local kv:TKeyValue=EachIn TDocStyle.commands
	t:+String( kv.Key() )+"|/docs/html"+String( kv.Value() )+"~n"
Next
'degac - additional commands to be highlighted!
If extcommands<>""
	'Print "External commands "
		If FileType(extcommands)=FILETYPE_FILE
			Local tx$=LoadText(extcommands)
			For Local l:String=EachIn tx.split("~n")
				If l.Trim()<>"" 
					t:+l.Trim()+"~n"
			'		Print "New command '"+l+"'"
				End If
			Next
		Else
			Print "External command: error file"
		End If
End If

Local p$=BlitzMaxPath()+"/doc/bmxmods/commands.txt"
If FileType( p )=FILETYPE_FILE t:+LoadText( p )

SaveText t,BmxDocDir+"/Modules/commands.txt"
'Print "Clean up"
Cleanup BmxDocDir
'Print "Done"
'*****

Function Cleanup( dir$ )
	For Local e$=EachIn LoadDir( dir )
		Local p$=dir+"/"+e
		Select FileType( p )
		Case FILETYPE_DIR
			Cleanup p
		Case FILETYPE_FILE
			If ExtractExt( e )="bbdoc"
				DeleteFile p
			Else If e.ToLower()="commands.html"
				DeleteFile p
			EndIf
		End Select
	Next
End Function

Function DocMods()
	
	For Local modid$=EachIn EnumModules()
		If Not modid.StartsWith( "brl." ) And Not modid.StartsWith( "pub." ) And Not modid.StartsWith("maxgui.") Continue
		
        'degac - check what module to skip
       For Local i1:Int=0 Until exc.length
			If modid.tolower()=exc[i1].tolower()	Print "Skip module '"+modid+"'";modid=""
		Next
		'-------------------------------------------------

		Local p$=ModuleSource( modid )
		Try
			'Print "Doccing : "+p
			docBmxFile p,""
		Catch ex$
			Print "Error:"+ex
		End Try
	Next

End Function

Function DocBBDocs( docPath$ )

	Local p$=BmxDocDir+docPath
	
	For Local e$=EachIn LoadDir( p )

		Local q$=p+"/"+e

		Select FileType( q )
		Case FILETYPE_FILE
			Select ExtractExt( e )
			Case "bbdoc"
				Local id$=StripExt( e )
				If id="index" Or id="intro" Continue
				
				Local path$=(docPath+"/"+id).Replace( "//","/" )
				Local NODE:TDocNode=TDocNode.Create( id,path,"/" )
				
				NODE.about=LoadText( q )
			End Select
		Case FILETYPE_DIR
			DocBBDocs docPath+"/"+e
		End Select
	Next
	
End Function

Function docBmxFile( filePath$,docPath$ )

	If FileType( filePath )<>FILETYPE_FILE
		Print "Error: Unable to open '"+filePath+"'"
		Return
	EndIf

	Local docDir$=ExtractDir( filePath )+"/doc"
	If FileType( docDir )<>FILETYPE_DIR docDir=""

	Local inrem,typePath$,section$
	
	Local bbdoc$,returns$,about$,keyword$,params:TList
	
	Local Text$=LoadText( filepath )
	
	For Local line$=EachIn Text.Split( "~n" )

		line=line.Trim()
		Local tline$=line.ToLower()
		
		Local i
		Local id$=ParseIdent( tline,i )
		
		If id="end" id:+ParseIdent( tline,i )
		
		If i<tline.length And tline[i]=Asc(":")
			id:+":"
			i:+1
		EndIf
		
		If inrem
		
			If id="endrem"
			
				inrem=False
				
			Else If id="bbdoc:"
			
				bbdoc=line[i..].Trim()
				keyword=""
				returns=""
				about=""
				params=Null
				section="bbdoc"

			Else If bbdoc 
			
				Select id
				Case "keyword:"
					keyword=line[i..].Trim()
					section="keyword"
				Case "returns:"
					returns=line[i..].Trim()+"~n"
					section="returns"
				Case "about:"
					about=line[i..].Trim()+"~n"
					section="about"
				Case "param:"
					If Not params params=New TList
					params.AddLast line[6..].Trim()
					section="param"
				Default
					Select section
					Case "about"
						about:+line+"~n"
					Case "returns"
						returns:+" "+line
					Case "param"
						params.AddLast String( params.RemoveLast() )+" "+line
					Default
						'remaining sections 1 line only...
						If line Print "Error: Illegal bbdoc section in '"+filePath+"'"
					End Select
				End Select
			
			EndIf
		
		Else If id="rem"
		
			bbdoc=""
			inrem=True
			
		Else If id="endtype"

			If typePath
				docPath=typePath
				typePath=""
			EndIf
			
		Else If id="import" Or id="include"
		
			Local p$=ExtractDir( filePath )+"/"+ParseString( line,i )
			
			If ExtractExt( p ).ToLower()="bmx"
				docBmxFile p,docPath
			EndIf
		
		Else If bbdoc
		
			Local kind$,proto$
			
			If keyword
				id=keyword
				kind="Keyword"
				If id.StartsWith( "~q" ) And id.EndsWith( "~q" )
					id=id[1..id.length-1]
				EndIf
				proto=id
			Else If id
				For Local t$=EachIn AllKinds
					If id<>t.ToLower() Continue
					kind=t
					proto=line
					id=ParseIdent( line,i )
					Exit
				Next
			EndIf
			
			If kind

				Local path$

				Select kind
				Case "Type"
					If Not docPath Throw "No doc path"
					If typePath Throw "Type path already set"
					typePath=docPath
					docPath:+"/"+id
					path=docPath
				Case "Module"
					If docPath Throw "Doc path already set"
					If bbdoc.FindLast( "/" )=-1
						bbdoc="Other/"+bbdoc
					EndIf
					docPath="/Modules/"+bbdoc
					path=docPath
					Local i=bbdoc.FindLast( "/" )
					bbdoc=bbdoc[i+1..]
				Default
					If Not docPath Throw "No doc path"
					path=docPath+"/"+id
				End Select
				
				Local i=proto.Find( ")=" )
				If i<>-1 
					proto=proto[..i+1]
					If id.StartsWith( "Sort" ) proto:+" )"	'lazy!!!!!
				EndIf
				i=proto.Find( "=New" )
				If i<>-1
					proto=proto[..i]
				EndIf
				
				Local NODE:TDocNode=TDocNode.Create( id,path,kind )
				
				NODE.proto=proto
				NODE.bbdoc=bbdoc
				NODE.returns=returns
				NODE.about=about
				NODE.params=params
				
				If kind="Module" NODE.docDir=docDir
				
				Local edir$[]=LoadDir(docDir)
				Local cnt:Int
				For Local file$=EachIn edir
					If file.tolower().contains(id.tolower()) And ExtractExt(docDir+"/"+file)="bmx"
						'Print "Example file <"+file+">"
						If NODE.examples
						cnt=Len(NODE.examples)
						NODE.examples=NODE.examples[..cnt+1]
						NODE.examples[cnt]=StripDir(file)
						End If
					End If
				
				Next
			EndIf
			bbdoc=""
		EndIf
	Next
	
End Function