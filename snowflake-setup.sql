USE DB_TEAM_JENKINS.KL_TEST_JENKINS;  
PUT 'file://C:\\Users\\klonergan\\Documents\\MyVSCodeRepo\\AIScribeSnowflake\\jenkins_spec.yml' '@KL_YAML_FILES' AUTO_COMPRESS=false OVERWRITE=true;

SHOW IMAGE REPOSITORIES;

CALL SYSTEM$REGISTRY_LIST_IMAGES('/DB_TEAM_JENKINS/KL_TEST_JENKINS/KL_JENKINS_REPOSITORY');

ALTER SERVICE JENKINS_APP SUSPEND;
ALTER SERVICE JENKINS_APP
FROM @KL_YAML_FILES
SPECIFICATION_FILE = 'jenkins_spec.yml';

ALTER SERVICE JENKINS_APP RESUME;

SHOW SERVICES;

--Check Service Status
select 
  v.value:containerName::varchar container_name
  ,v.value:status::varchar status  
  ,v.value:message::varchar message
from (select parse_json(system$get_service_status('JENKINS_APP'))) t, 
lateral flatten(input => t.$1) v;

--Error logs
SELECT SYSTEM$GET_SERVICE_LOGS('JENKINS_APP', '0', 'jenkins-service-container', 1000);

SHOW ENDPOINTS IN SERVICE JENKINS_APP;

show grants to user JAKE.HAYWARD@ALBERTAHEALTHSERVICES.CA;
   /* docker build commands 
      docker build --platform linux/amd64 -t ahsorg-ahsprod.registry.snowflakecomputing.com/db_team_jenkins/kl_test_jenkins/kl_jenkins_repository/jenkins_app .
      docker login ahsorg-ahsprod.registry.snowflakecomputing.com -u SVC_TEAM_JENKINS
      docker push ahsorg-ahsprod.registry.snowflakecomputing.com/db_team_jenkins/kl_test_jenkins/kl_jenkins_repository/jenkins_app
    */