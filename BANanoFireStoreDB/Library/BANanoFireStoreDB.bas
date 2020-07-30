B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private firebaseConfig As Map
	Public apiKey As String
	Public authDomain As String
	Public databaseURL As String
	Public projectId As String
	Public storageBucket As String
	Public messagingSenderId As String
	Public appId As String
	Public measurementId As String
	Private BANano As BANano
	Private firebase As BANanoObject
	Private firebaseApp As BANanoObject
	Private firestore As BANanoObject
	'
	Private fromCollection As String
	Private whereClauses As List
	'
	Public const FB_EQ As String = "=="
	Public const FB_GT As String = ">"
	Public const FB_GE As String = ">="
	Public const FB_LT As String = "<"
	Public const FB_LE As String = "<="
	Public const FB_IN As String = "in"
	Public const FB_CONTAINS_ANY As String = "array-contains-any"
	Public const FB_CONTAINS As String = "array-contains"
	Public const FB_NE As String = "ne"
	Public const FB_ASC As String = "asc"
	Public const FB_DESC As String = "desc"
	Private ordering As Map
	Private limitSelectionTo As Int
	Private ostartAt As Object
	Private oendAt As Object
End Sub

'Notes: https://firebase.google.com/docs/firestore/quickstart
'NOTES: update permissions here, https://firebase.google.com/docs/firestore/security/get-started#auth-required
'NOTES on queries, https://firebase.google.com/docs/firestore/query-data/queries

'initialize the bv class
Public Sub Initialize() As BANanoFireStoreDB
	BANano.DependsOnAsset("vuefire.min.js")
	'
	firebaseConfig.Initialize
	apiKey = ""
	authDomain = ""
	databaseURL = ""
	projectId = ""
	storageBucket = ""
	messagingSenderId = ""
	appId = ""
	measurementId = ""
	firebase.Initialize("firebase")
	Return Me
End Sub

'build up the config connection string
Sub Connect() As BANanoFireStoreDB
	firebaseConfig.put("apiKey", apiKey)
	firebaseConfig.put("authDomain", authDomain)
	firebaseConfig.put("databaseURL", databaseURL)
	firebaseConfig.put("projectId", projectId)
	firebaseConfig.put("storageBucket", storageBucket)
	firebaseConfig.put("messagingSenderId", messagingSenderId)
	firebaseConfig.put("appId", appId)
	firebaseConfig.put("measurementId", measurementId)
	'initialize the app
	firebaseApp = firebase.RunMethod("initializeApp", firebaseConfig)
	'start analytics
	firebase.RunMethod("analytics", Null)
	'get the db
	firestore = firebaseApp.RunMethod("firestore", Null)
	Return Me
End Sub

'detect changes when made
Sub onSnapshot(Collection As String, Module As Object, methodName As String)
	methodName = methodName.ToLowerCase
	Dim doc As Map
	Dim cb As BANanoObject = BANano.CallBack(Module, methodName, Array(doc))
	getCollection(Collection).RunMethod("onSnapshot", cb)
End Sub

'enable persistence
Sub enablePersistence() As BANanoPromise
	Dim boOffline As BANanoObject = firestore.RunMethod("enablePersistence", Null)
	Return boOffline
End Sub

'disableNetwork
Sub disableNetwork() As BANanoPromise
	Dim boOffline As BANanoObject = firestore.RunMethod("disableNetwork", Null)
	Return boOffline
End Sub

'enableNetwork
Sub enableNetwork() As BANanoPromise
	Dim boOffline As BANanoObject = firestore.RunMethod("enableNetwork", Null)
	Return boOffline
End Sub

'get the auth object
private Sub getAuth() As BANanoObject
	Dim boAuth As BANanoObject = firebaseApp.RunMethod("auth", Null)
	Return boAuth
End Sub

'get a collection
private Sub getCollection(colName As String) As BANanoObject
	Dim boTable As BANanoObject = firestore.RunMethod("collection", Array(colName))
	Return boTable
End Sub

'add a record
Sub collectionAdd(Collection As String, record As Map) As BANanoPromise
	'execute the addition
	Dim promAdd As BANanoPromise = getCollection(Collection).RunMethod("add", Array(record))
	Return promAdd
End Sub

'update a record using a primary autoincrement id
'dont pass the id as part of the record map
Sub collectionUpdate(Collection As String, colID As String, record As Map) As BANanoPromise
	'execute the update
	Dim promAdd As BANanoPromise = getCollection(Collection).RunMethod("doc", Array(colID)).RunMethod("update", Array(record))
	Return promAdd
End Sub

'delete a record using a primary autoincrement id
Sub collectionDelete(Collection As String, colID As String) As BANanoPromise
	'execute the update
	Dim promDel As BANanoPromise = getCollection(Collection).RunMethod("doc", Array(colID)).RunMethod("delete", Null)
	Return promDel
End Sub

'get all records
Sub collectionGetAll(collection As String, sOrderBy As String) As BANanoPromise
	Dim boTable As BANanoObject = getCollection(collection)
	If sOrderBy <> "" Then
		If sOrderBy.IndexOf(" ") = -1 Then
			boTable = boTable.RunMethod("orderBy", Array(sOrderBy, "asc"))
		Else
			boTable = boTable.RunMethod("orderBy", Array(sOrderBy, "desc"))
		End If
	End If
	'execute the addition
	Dim promGet As BANanoPromise = boTable.RunMethod("get", Null)
	Return promGet
End Sub

'get a record
Sub collectionGet(collection As String, colID As String) As BANanoPromise
	Dim promGet As BANanoPromise = getCollection(collection).RunMethod("doc", Array(colID)).RunMethod("get", Null)
	Return promGet
End Sub


'register a user
Sub createUserWithEmailAndPassword(emailaddress As String, password As String) As BANanoPromise
	Dim promRegister As BANanoPromise = getAuth.RunMethod("createUserWithEmailAndPassword", Array(emailaddress, password))
	Return promRegister
End Sub


'sign in
Sub signInWithEmailAndPassword(emailaddress As String, password As String) As BANanoPromise
	Dim promRegister As BANanoPromise = getAuth.RunMethod("signInWithEmailAndPassword", Array(emailaddress, password))
	Return promRegister
End Sub


'update display name
Sub updateDisplayName(res As BANanoObject, displayName As String) As BANanoPromise
	Dim rec As Map = CreateMap("displayName": displayName)
	Dim promUpdate As BANanoPromise = res.getfield("user").RunMethod("updateProfile", Array(rec))
	Return promUpdate
End Sub

'convert docs to list
Sub FromJSON(response As Map) As List
	'get the returned docs
	Dim docs As List = response.Get("docs")
	Dim recs As List
	recs.Initialize
	For Each userx As BANanoObject In docs
		Dim uid As String = userx.Getfield("id").Result
		Dim udata As Map = userx.RunMethod("data", Null).Result
		udata.Put("id", uid)
		recs.Add(udata)
	Next
	Return recs
End Sub

'get the id
Sub getID(response As Map) As String
	Dim res As String = response.Get("id")
	Return res
End Sub

'get the message
Sub getMessage(error As Map) As String
	Dim res As String = error.Get("message")
	Return res
End Sub

'get the complete record including the id
Sub getRecord(response As BANanoObject) As Map
	Dim id As String = response.GetField("id").Result
	Dim data As Map = response.RunMethod("data", Null).Result
	data.Put("id", id)
	Return data
End Sub

'create a select where
Sub selectFrom(collectionFrom As String) As BANanoFireStoreDB
	fromCollection = collectionFrom
	whereClauses.Initialize
	ordering.Initialize 
	limitSelectionTo = -1
	ostartAt = Null
	oendAt = Null
	Return Me  
End Sub

'specify start at
Sub startAt(startValue As Object) As BANanoFireStoreDB
	ostartAt = startValue
	Return Me
End Sub

'specify end at
Sub endAt(endValue As Object) As BANanoFireStoreDB
	oendAt = endValue
	Return Me
End Sub


'order in ascending order
Sub orderBy(fld As String) As BANanoFireStoreDB
	ordering.Put(fld, FB_ASC)
	Return Me
End Sub

'specify order by
Sub orderBy1(fld As String, ordertype As String) As BANanoFireStoreDB
	ordering.Put(fld, ordertype)
	Return Me
End Sub

'specify the conditions
Sub whereCondition(fieldName As String, fieldOperation As String, fieldValue As Object) As BANanoFireStoreDB
	Dim wherem As Map = CreateMap()
	wherem.Put("fld", fieldName)
	wherem.Put("oper", fieldOperation)
	wherem.Put("value", fieldValue)
	whereClauses.Add(wherem)
	Return Me
End Sub

'execute the query
Sub execute As BANanoPromise
	'get the collection
	Dim boTable As BANanoObject = getCollection(fromCollection)
	'get the where clauses
	Dim wc As List = whereClauses
	For Each wm As Map In wc
		Dim fld As String = wm.Get("fld")
		Dim oper As String = wm.Get("oper")
		Dim value As Object = wm.Get("value")
		'
		Select Case oper
		Case "ne"
			'this is not supported, create it
			boTable = boTable.RunMethod("where", Array(fld, "<", value))
			boTable = boTable.RunMethod("where", Array(fld, ">", value))
		Case Else
			boTable = boTable.RunMethod("where", Array(fld, oper, value))
		End Select
	Next
	'get ordering
	For Each fld As String In ordering.Keys
		Dim fldo As String = ordering.Get(fld)
		boTable = boTable.RunMethod("orderBy", Array(fld, fldo))
	Next
	'has a limig
	limitSelectionTo = BANano.parseInt(limitSelectionTo)
	If limitSelectionTo > 0 Then
		boTable.RunMethod("limit", Array(limitSelectionTo))
	End If
	'start and end clauses
	If BANano.IsNull(ostartAt) = False Then
		boTable.RunMethod("startAt", Array(ostartAt))
	End If
	'end and end clauses
	If BANano.IsNull(oendAt) = False Then
		boTable.RunMethod("endAt", Array(oendAt))
	End If
	'cler everything else
	fromCollection = "" 
	whereClauses.Initialize
	ordering.Initialize
	limitSelectionTo = -1
	ostartAt = Null
	oendAt = Null
	Dim promExec As BANanoPromise = boTable.RunMethod("get", Null)
	Return promExec
End Sub

'set a limit to the number of pages
Sub LimitTo(lt As Int) As BANanoFireStoreDB
	limitSelectionTo = lt
	Return Me
End Sub