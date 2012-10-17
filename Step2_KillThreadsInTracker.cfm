<!---
	CFThreadTracker (**Experimental**)

      This code is HIGHLY experimental and is distributed "AS IS" WITHOUT 
      WARRANTIES OR CONDITIONS OF ANY KIND. Use it at your own risk.

 	@author     http://cfsearching.blogspot.com/
 	@version    0.1, October 31, 2009
--->

	<cfoutput>
	<h1>Step 2: Kill All Threads in CFThreadTracker (**Experimental**)</h1>
	<div>
		<!--- lazy cache killer --->
		<p> Select the active/pending threads you wish to kill or 
			<a href="Step1_CreateNewThreads.cfm?rd=#now().getTime()#">Create more threads</a> <br />
		</p> 	

		<p style="font-style: italic; color: red;">
		* Note: Threads are only added to the tracker AFTER they are started. So if you are <br>
		limited to ten (10) concurrent threads, this list will only display a maximum of ten (10) <br>
		threads at a time<br />
		</p>	
	</div>

	<!---
		Self-Post:  Kill the selected threads 
	--->
	<cfif structKeyExists(FORM, "killType")>
		<cfparam name="form.threadList" default="" />
		
		<!--- get the threads to be killed --->		
		<cfif form.killType eq "Selected">
			<cfset threadsToKill = form.threadList />
		<cfelse>
			<cfset threadsToKill = form.allThreads />
		</cfif>

		<cfoutput>
		<cfloop list="#threadsToKill#" index="key">
			<cfset status 	 = application.threadTracker.getThreadStatus( key ) />
			<cfset result 	 = application.threadTracker.killThread( key ) />
			
			<cfif result.wasKilled >
				* Successfully killed thread #result.name# [#result.status#] / #key# <br />
				<cfdump var="#status#" label="Thread #result.name#" />
			<cfelse>
				* Thread #key# was already dead or finished <br/>
			</cfif>
		</cfloop>
		</cfoutput>

	</cfif>

	<!--- 
		Display the active threads in the tracker  
	--->
	<cfset myThreads = application.threadTracker.getThreadTasks() />
		<strong>
			Active threads in CFThreadTracker [ #structCount(myThreads)# ]
			<a href="#CGI.SCRIPT_NAME#?rd=#now().getTime()#">Refresh</a> <br />
		</strong><hr />
	
		<cfif structCount(myThreads)>
			<form method="post" action="Step2_KillThreadsInTracker.cfm">
				<cfloop collection="#myThreads#" item="key">
					<input type="checkbox" name="threadList" value="#key#"> Thread #myThreads[key].name# / #key#<br />
				</cfloop>	
				<input type="hidden" name="allThreads" value="#structKeyList(myThreads)#" />
				
				<input type="submit" name="killType" value="Selected" />
				<input type="submit" name="killType" value="All" />
			</form>
		</cfif>
	</cfoutput>
	
	
	