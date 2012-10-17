<!---
CFThreadTracker

This code is HIGHLY experimental and is distributed "AS IS" WITHOUT 
WARRANTIES OR CONDITIONS OF ANY KIND. Use it at your own risk.
	
@author     http://cfsearching.blogspot.com/
@version    0.1, October 31, 2009
---->
<cfcomponent>
	<cfset variables.instance = {} />	
	
	<cffunction name="init" returntype="CFThreadTracker">
		<cfargument name="debug" type="string" required="false" />
		<cfargument name="logName" type="string" default="" />

		<cfif arguments.debug AND NOT len(trim(arguments.logName))>
			<cfthrow message="Log name is required when debug = true" />
		</cfif>

		<cfset variables.instance.tracker 	= {} />
		<cfset variables.instance.uuid 		= createUUID() />
		<cfset variables.instance.debug  	= arguments.debug />
		<cfset variables.instance.log  		= arguments.logName />

		<cfreturn this />
	</cffunction>
	
	<cffunction name="addThread" returntype="UUID" access="public" output="false">
		<cfargument name="threadName" type="string" required="true" />
		<cfargument name="threadTask" type="any" required="true" />

		<cfset var threadUUID 	= createUUID() />
		<cfset var threadStatus = "" />
		<cfset var threadData 	= {} />
		
		<cfset threadData.name 	= arguments.threadName />
		<cfset threadData.task 	= arguments.threadTask />
		<cfset threadStatus 	= decodeStatus( arguments.threadTask.getStatus() ) />
		
		<!--- Add the new thread to the tracker --->
		<cflock name="#variables.instance.uuid#" type="exclusive" timeout="5" throwontimeout="false">
			<cfset variables.instance.tracker[threadUUID] = threadData />
		</cflock>

		<cfif variables.instance.debug>
			<cflog file="#variables.instance.log#" 
	    		text="TRACKER: Added thread #arguments.threadName# [#threadStatus#] /#threadUUID#" />
		</cfif>
		
		<cfreturn threadUUID />
	</cffunction>

	<cffunction name="removeThread" returntype="boolean" access="public" output="false">
		<cfargument name="threadUUID" type="uuid" required="true" />

		<cfset var threadTask 	= "" />
		<cfset var threadName 	= "" />
		<cfset var threadStatus = "" />
		<cfset var wasFound 	= false />
		
		<!--- Remove this thread from the tracker --->
		<cflock name="#variables.instance.uuid#" type="exclusive" timeout="5" throwontimeout="false">
			<cfif structKeyExists(variables.instance.tracker, arguments.threadUUID )>
				
				<cfset threadName 	= variables.instance.tracker[ arguments.threadUUID ].name />
				<cfset threadTask 	= variables.instance.tracker[ arguments.threadUUID ].task />
				<cfset threadStatus = decodeStatus( threadTask.getStatus() ) />
				<cfset wasFound 	= structDelete(variables.instance.tracker, arguments.threadUUID, true) />

			</cfif>
		</cflock>
		
		<!--- Record the action to our log file --->
		<cfif variables.instance.debug AND wasFound >
			<cflog file="#variables.instance.log#"
	    		text="TRACKER: Removed thread #threadName# [#threadStatus#] / #arguments.threadUUID# " />
		</cfif>	

		<cfreturn wasFound />				
	</cffunction>
	
	<cffunction name="getThreadTasks" returntype="struct" access="public" output="false">
		<cfset var copy = "" />
		
		<!--- Make a shallow copy of the tracker structure --->
		<cflock name="#variables.instance.uuid#" type="readonly" timeout="5" throwontimeout="false">
			<cfset copy = structCopy( variables.instance.tracker ) />
		</cflock>

		<cfreturn copy />
	</cffunction>

	<cffunction name="getThreadStatus" returntype="struct" access="public" output="false"
				hint="Returns the status of a thread (if it exists). Use the 'WasFound' key to test for existence." >
		<cfargument name="threadUUID" type="uuid" required="true" />
		<cfset var data 	= {} />
		<cfset var result 	= {} />
		
		<cfset result.wasFound 		=  false />
		<cfset result.name 	 		=  "" />
		<cfset result.elapsedTime 	=  0 />
		<cfset result.startTime 	=  0 />
		<cfset result.error 		=  "" />
		<cfset result.status 		=  "" />
		
		<cflock name="#variables.instance.uuid#" type="readonly" timeout="5" throwontimeout="false">
			<cfif structKeyExists(variables.instance.tracker, arguments.threadUUID)>

				<!--- Get the task / thread details --->
				<cfset data	 		 		= variables.instance.tracker[ arguments.threadUUID ] />
				<cfset result.name 	 		= data.name />
				<cfset result.status 		= decodeStatus( data.task.getStatus() ) />
				<cfset result.elapsedTime 	= data.task.getElapsedTime() />
				<cfset result.startTime 	= data.task.getStartTime() />
				<cfset result.error 		= data.task.getError() />
			</cfif>
		</cflock>
	
		<!--- The error key may be null. Fix it to prevent an undefined error ---> 
		<cfif NOT structKeyExists(result, "error")>
			<cfset result.error = "" />
		</cfif>
		
		<cfreturn result />
	</cffunction>
		
	<cffunction name="killThread" returntype="struct" access="public" output="false">
		<cfargument name="threadUUID" type="uuid" required="true" />

		<cfset var task 		= "" />
		<cfset var status 		= "" />
		<cfset var result   	= {} />
		
		<cfset result.name  	 = "" />
		<cfset result.status  	 = "" />
		<cfset result.wasKilled  = false />
		
		<cflock name="#variables.instance.uuid#" type="exclusive" timeout="5" throwontimeout="false">
			<cfif structKeyExists(variables.instance.tracker, arguments.threadUUID)>

				<!--- Get the task / thread details --->
				<cfset task	 		 = variables.instance.tracker[ arguments.threadUUID ].task />
				<cfset result.name 	 = variables.instance.tracker[ arguments.threadUUID ].name />
				<cfset result.status = decodeStatus( task.getStatus() ) />

				<!--- If the thread was not already terminated, kill it --->
				<cfif listFindNoCase("NOT_STARTED,RUNNING,WAITING", result.status)>
					<cfset task.cancel() />
					<cfset result.wasKilled = true />
				</cfif>

			</cfif>
		</cflock>
		
		<!--- If the task was found  ---->		
		<cfif len(result.name)>
		
			<!--- Give the thread a chance to die. Then remove it from the tracker --->
			<cfscript>
				sleep( 100 );
				removeThread( arguments.threadUUID );
			</cfscript>

			<!--- Record the action to our log file --->
			<cfif variables.instance.debug >
				<cflog file="#variables.instance.log#"
		    		text="TRACKER: Killed thread #result.name# [#result.status#] / #arguments.threadUUID# " />
			</cfif>	
			
		</cfif>
		
		<cfreturn result />	
	</cffunction>
	
	<cffunction name="decodeStatus" returntype="string" access="public" output="false"
				hint="Translates the coldfusion.thread.Task status codes to a user friendly string" >
		<cfargument name="statusNumber" type="numeric" required="true">

		<cfswitch expression="#arguments.statusNumber#">
			<cfcase value="0"><cfreturn "NOT_STARTED"></cfcase>
			<cfcase value="1"><cfreturn "RUNNING"></cfcase>
			<cfcase value="2"><cfreturn "WAITING"></cfcase>
			<cfcase value="3"><cfreturn "TERMINATED"></cfcase>
			<cfcase value="4"><cfreturn "FINISHED"></cfcase>
			<cfcase value="5"><cfreturn "FORCE_ABORTED"></cfcase>
		</cfswitch>
		
		<cfreturn "UKNOWN_ZOMBIE_STATE" />
	</cffunction>	
	
</cfcomponent>