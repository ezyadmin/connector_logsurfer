# Ansible Playbook Logsurfer for EzyAdmin Connectors

## Configuration

| key | description |
| --- | ----------- |
|     |             |

- paths

'''
paths:

- monitorfile: "/usr/local/apache/logs/error_log"
  configfile: "apache.error_log.conf"
  data: "'\[(error)\].\*Too many connections' - - - 0\n open "$2" - 2000 60 10\n    report \"/usr/bin/ezyAdminApi -i 5dd5d6486f2798012c588804 -S \\\"MYSQL error, too many connections reached on {HOST.NAME}\\\"\" \"$2\""
  '''
