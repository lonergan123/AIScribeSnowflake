USE ROLE RL_TEAM_JENKINS;
USE DB_TEAM_JENKINS.KL_TEST_JENKINS;  

--Create Image Repository
CREATE IMAGE REPOSITORY KL_JENKINS_REPOSITORY;
SHOW IMAGE REPOSITORIES;

--Upload image to this repo. Do this locally or on another machine with docker installed.
-- 1. Build the Docker image
--    docker build --rm --platform linux/amd64 -t jenkins_app .
                             
-- 2. Tag and push it to SPCS
--    docker tag ahsorg-ahsprod.registry.snowflakecomputing.com/db_team_jenkins/kl_test_jenkins/kl_jenkins_repository
--    docker login 
--    docker push ahsorg-ahsprod.registry.snowflakecomputing.com/db_team_jenkins/kl_test_jenkins/kl_jenkins_repository
   
--Confirm image uploaded
CALL SYSTEM$REGISTRY_LIST_IMAGES('/DB_TEAM_JENKINS/KL_TEST_JENKINS/KL_JENKINS_REPOSITORY');

--Create a stage to hold YAML FILES (IF NOT ALREADY THERE)
SHOW STAGES;
CREATE STAGE KL_YAML_FILES ENCRYPTION = (type = 'SNOWFLAKE_SSE');


--Put the yaml file in the stage
PUT 'file://C:\\Users\\klonergan\\Documents\\MyVSCodeRepo\\AIScribeSnowflake\\jenkins_spec.yml' '@KL_YAML_FILES' AUTO_COMPRESS=false OVERWRITE=true;

--Confirm compute pool available (Kamran / Snowflake Admin needs to create this)
SHOW COMPUTE POOLS;

CREATE SERVICE KL_VLLM_MISTRAL
IN COMPUTE POOL TUTORIAL_COMPUTE_POOL --App container only needs small CPU compute pool
FROM @KL_YAML_FILES
SPECIFICATION_FILE = 'jenkins_spec.yml'
MIN_INSTANCES = 1
MAX_INSTANCES = 1; 

--Confirm Service Created
SHOW SERVICES;
SHOW ENDPOINTS IN SERVICE JENKINS_APP;

--Check Service Status
select 
  v.value:containerName::varchar container_name
  ,v.value:status::varchar status  
  ,v.value:message::varchar message
from (select parse_json(system$get_service_status('JENKINS_APP'))) t, 
lateral flatten(input => t.$1) v;

--Run this if making update to image
ALTER SERVICE JENKINS_APP
FROM @KL_YAML_FILES
SPECIFICATION_FILE = 'jenkins_spec.yml';

--Error logs
SELECT SYSTEM$GET_SERVICE_LOGS('JENKINS_APP', '0', 'jenkins-service-container', 1000);