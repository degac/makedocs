
Strict

Import BRL.MaxUtil

Import "bbdoc.bmx"
Import "docnode.bmx"
Global BmxDocDir$=BlitzMaxPath()+"/docs/html"
Global NodeKinds$[]=[ "/","Module","Type" ]
Global LeafKinds$[]=[ "Const","Field","Global","Method","Function","Keyword" ]
Global AllKinds$[]=NodeKinds+LeafKinds

Type TDocStyle Extends TBBLinkResolver

	Field html$
	Field doc:TDocNode
	Field children:TMap
	Field docURL$
	Field absDocDir$		'where output doc goes
	Field relRootDir$		'relative path to root doc dir
	
	Global commands:TMap=New TMap

	Method NodeIsleaf( NODE:TDocNode )
		For Local t$=EachIn LeafKinds
			If t=NODE.kind Return True
		Next
	End Method
	
	Method FindNode:TDocNode( NODE:TDocNode,id$ )

		If NODE.id.ToLower()=id Return NODE

		If NODE.path.Tolower().EndsWith( "/"+id ) Return NODE

		For Local t:TDocNode=EachIn NODE.children
			Local p:TDocNode=FindNode( t,id )
			If p Return p
		Next
	End Method
	
	Method NodeURL$( NODE:TDocNode )
		If NODE.kind="Topic"
			Return NODE.path+".html"
		Else If NodeIsLeaf( NODE )
			Return ExtractDir( NODE.path )+"/index.html#"+NODE.id
		Else If NODE.path<>"/"
			Return NODE.path+"/index.html"
		Else
			Return "/index.html"
		EndIf
	End Method
	
	Method ResolveLink$( link$ )
		Local id$=link.ToLower()

		Local NODE:TDocNode=FindNode( doc,id )
		
		If Not NODE 
			NODE=FindNode( TDocNode.ForPath( "/" ),id )
		EndIf
		
		If Not NODE 
			Print "Error: Unable to resolve link '"+link+"'"
			Return link
		EndIf

		Local url$=nodeURL( NODE )
		
		'optimize links...
		If url.StartsWith( docURL+"#" )
			url=url[ docURL.length.. ]
		Else If url.StartsWith( doc.path+"/" )
			url="~q"+url[ doc.path.length+1.. ]+"~q"
		Else
			url="~q"+relRootDir+url+"~q"
		EndIf
		Return "<a href="+url+">"+link+"</a>"
	End Method
	
	Method EmitDoc( NODE:TDocNode )
		
		Print "Building: "+NODE.id
		
		html=""
		doc=NODE
		children=New TMap
		docURL=NodeURL( doc )
		absDocDir=BmxDocDir+ExtractDir( docURL )
		relRootDir=""

		Local p$=ExtractDir( docURL )
		While p<>"/"
			If relRootDir relRootDir:+"/"
			relRootDir:+".."
			p=ExtractDir( p )
		Wend
		If Not relRootDir relRootDir="."

		CreateDir absDocDir,True
		
		If doc.docDir CopyDir doc.docDir,absDocDir

		If docURL.EndsWith( "/index.html" )
			Local intro$=absDocDir+"/index.bbdoc"
			If FileType( intro )<>FILETYPE_FILE intro$=absDocDir+"/intro.bbdoc"
			If FileType( intro )=FILETYPE_FILE
				Local t$=LoadText( intro )
				If t.find( "commands.html" )<>-1
					Print "Error: Document contains 'commands.html'"
				EndIf
				doc.about=t+doc.about
			EndIf
		EndIf

		For Local t:TDocNode=EachIn doc.children

			Local list:TList=TList( children.ValueForKey( t.kind ) )
			If Not list
				list=New TList
				children.Insert t.kind,list
			EndIf

			list.AddLast t
			
			'update commands.txt
			Select t.kind
			Case "Keyword"
				commands.Insert t.id+" : "+t.bbdoc,NodeURL( t )
			Case "Const","Global","Function","Type"	',"Module"
				Local i=t.proto.Find( " " )
				If i<>-1 commands.Insert t.proto[i+1..].Trim()+" : "+t.bbdoc,NodeURL( t )
			End Select
		Next
		
		EmitHeader
		
		For Local t$=EachIn NodeKinds
			EmitLinks t
		Next
		
		For Local t$=EachIn LeafKinds
			EmitLinks t
		Next
		
		For Local t$=EachIn LeafKinds
			EmitDecls t
		Next
		
		EmitFooter
		
		html=BBToHtml( html,Self )
		
		SaveText html,BmxDocDir+docURL

		For Local t$=EachIn NodeKinds
			EmitNodes t
		Next
	
	End Method
	
	Method EmitNodes( kind$ )
		Local list:TList=TList( children.ValueForKey( kind ) )
		If Not list Return
		For Local t:TDocNode=EachIn list
			EmitDoc t
		Next
	End Method
	
	Method Emit( t$ )
		html:+t+"~n"
	End Method
	
	Method ChildList:TList( kind$ )
		Return TList( children.ValueForKey( kind ) )
	End Method
	
	Method EmitHeader() Abstract
	
	Method EmitFooter() Abstract
	
	Method EmitLinks( kind$ ) Abstract
	
	Method EmitDecls( kind$ ) Abstract
	
End Type
