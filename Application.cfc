<!---
 	
CFThreadTracker (**Experimental**)

 This code is HIGHLY experimental and is distributed "AS IS" WITHOUT 
 WARRANTIES OR CONDITIONS OF ANY KIND. Use it at your own risk.
	
 @author     http://cfsearching.blogspot.com/
 @version    0.1, October 31, 2009
--->
<cfcomponent>
	<cfset this.name = "CFZombieThreadTracker">
	<cfset this.sessionManagement = true>
	<cfset this.loginStorage = "session">

	<cffunction name="onApplicationStart" returntype="void">
		<cfset var logName = "CFZombieThreadTracker" />
		<cfset application.threadTracker = createObject("component", "CFThreadTracker").init(true, logName) />
	</cffunction>
	
	<cffunction name="onApplicationEnd" returnType="void">
   		<cfargument name="appScope" required="true" />
   		<!---
			Do something with the tracker threads if desired ...
		--->
	</cffunction>
	
</cfcomponent>