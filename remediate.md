# Remediation Plan

1. Build Release Tool to meet controls

 - Control 1: An approved valid change is required in order to make a release 
 - Control 2: Package must be referenced in the change ticket to make release 
 - Control 3: It must not be possible to bypass inbuilt configuration checks 

 Requirements: 
  - Build service and ensure all controls are met including the ability to bypass configuration (No core team TPAM on CR)
  - Communicate change in process to customers along with a timeline (adding CR reference to GIT Pull Request for PROD Deployments to avoid failure)
  - Test tool in UAT 
  - Deploy and implement tool in PROD

Progress: POC Complete, further feature development required 

Timeline: Code completiong mid-Jan, comms third week of Jan, deploy and implement end of Jan

2. Apply TPAM access to orchestration tool so that parameters can not be bypassed 

Requirements: 
 - Design permissions model for non-priv (read), priv -GCP (job runner), and -SGP (job editor)
 - Implement and test on JENKINS-DEV (UAT style Jenkins in devleopment)
 - Implement on JENKINS-CORE 
 - Raise exception for 'noexternal' email violations

Progress: POC complete on Jenkins-Dev, permissions matrix to be designed and testing w/c 16th December 

Timeline: Implement by 17th Jan

3. Build environment aware continuous delivery tooling scoped to Shared Services within GOOGLE-FOUNDATION-PLATFORM 

Requirements: 
 - POC of Spinnaker for Shared Services in UAT 
 - Plan DEV and PROD implementation
 - Implement in DEV and PROD

Progress: Starting w/c 16th December 

Timeline: POC complete by 3rd Jan, implementation timeline to follow
