<!---
 CFThreadTracker (**Experimental**)

 This code is HIGHLY experimental and is distributed "AS IS" WITHOUT 
 WARRANTIES OR CONDITIONS OF ANY KIND. Use it at your own risk.

 @author     http://cfsearching.blogspot.com/
 @version    0.1, October 31, 2009
---->
<h1>Step 1: Create Threads with CFThreadTracker (**Experimental**)</h1>

<cfoutput>
<div>
	<p>
		<!--- lazy cache killer --->
		Create eight (8) new cfthreads that will run for 40 seconds or 
		<a href="Step2_KillThreadsInTracker.cfm?r=#now().getTime()#">kill active threads</a><br />
	</p>
	<p style="font-style: italic;">
		* Note: This example use cflog to log debugging information. Check your log<br />
		directory for the results ie C:\ColdFusion8\logs\CFZombieThreadTracker.log <hr />
	</p>
</div>
</cfoutput>


<!---
	Initialize variables
--->
<cfset numOfThreads = 8 /> 
<cfset newThreads = [] />

<!---
	Create the specified number of threads
--->
<cfloop from="1" to="#numOfThreads#" index="x">
	
	<!--- 
		Generate a dynamic thread name and record it in our array  
	--->
	<cfset newThreadName = "CFZombieThread_"& x />
	<cfset arrayAppend(newThreads, newThreadName) />
	
	<!--- Start the new thread ---->
	<cfthread action="run" name="#newThreadName#" >
			
			<cfset var myThreadUUID = "" />
			<cfset var myThreadContext = getPageContext().getFusionContext() />
			<cfset var myThreadName = myThreadContext.getCurrentUserThreadName() />

			<!---
				First, the thread will add itself to the tracker object
			--->			
			<cfset myThreadUUID = application.threadTracker.addThread(
										threadName = myThreadName,
										threadTask = myThreadContext.getUserThreadTask(myThreadName)		
									) />

			<!---
				Record the start of this thread to our log file
			--->	
			<cflog file="CFZombieThreadTracker" 
    				text="***THREAD: Zombie thread #myThreadName# awakening from trance..." />
							
			<!--- 
				Generate a few lines of meaningless output. Force the thread to
				sleep in between each line, to simulate a long running task  
			--->			
			<cfloop from="1" to="10" index="counter">
	
				<cfoutput>
					Mindless groan from zombie thread #myThreadName# ...
				</cfoutput>
			
				<!--- 
					Force the thread to sleep 4 seconds  
				--->			
				<cfset sleep(4 * 1000) />
				
			</cfloop>
	

			<!---
				Finally, the finished thread will remove itself from
				the application tracker object 
			--->			
			<cfset application.threadTracker.removeThread(
										threadUUID = myThreadUUID,
										threadName = myThreadName
									) />
	</cfthread>

</cfloop>

<!---
	Display the results
--->
<cfoutput>
	<strong>Finished Creating [#numOfThreads#] Threads at #Now()#</strong>
</cfoutput>

<cfloop array="#newThreads#" index="t">
	<cfdump var="#cfthread[t]#" label="New Thread #t#" />
</cfloop>
