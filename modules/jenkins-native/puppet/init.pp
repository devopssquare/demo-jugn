include jenkins

# Jenkins needs some packages for misc. Jobs
$packages = [
  'git',
]

package { $packages :
  ensure	=>	installed,
}

$plugins = [
  'ansicolor',
  'build-pipeline-plugin',
  'conditional-buildstep',
  'disk-usage',
  'display-url-api',
  'envinject',
  'git',
  'git-client',
  'github',
  'github-api',
  'javadoc',
  'jobConfigHistory',
  'job-dsl',
  'jquery',
  'junit',
  'mailer',
  'maven-plugin',
  'matrix-project',
  'monitoring',
  'parameterized-trigger',
  'plain-credentials',
  'run-condition',
  'scm-api',
  'script-security',
  'ssh-credentials',
  'structs',
  'token-macro',
  'workflow-scm-step',
  'workflow-step-api',
]

jenkins::plugin { $plugins : }

$jenkins_users_admin_config = "/var/lib/jenkins/users/admin/config.xml"
augeas {"Set admin password":
  require  => Class['jenkins'],
  lens       => 'Xml.lns',
  incl       => $jenkins_users_admin_config,
  context    => "/files$jenkins_users_admin_config",
  changes    => [
    'set user/properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash/#text "#jbcrypt:$2a$10$SAi.psdqzo1zKBmZ8rLH6.RcBRlcWI4QqtaLWnDYe.ORXU7d4e.DW"',
  ]
}

# Enable CLI access via SSH credentials
augeas {"Set admin ssh key":
  lens       => 'Xml.lns',
  incl       => $jenkins_users_admin_config,
  context    => "/files$jenkins_users_admin_config",
  changes    => [
    'set user/properties/org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl/authorizedKeys/#text "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCodR+WmWcNvw+LIPoNrJ8xT2+4gJOvOh4Zj/ExGdHAG+eZAEMAmZ/z3x1c+I33w6TlxaSE09AqkjatKnae5yev3qSK4fsgEUp1n36WWPrc5V5i1yXuT6Eex+w5SaHUhD9IhyjySyAfZR4NxryiluWL/w9f3AaBVyPHNyf1C8BI3wVPL4H0ZAeBSxms0PW5YLhvXlRSfZhcSuSEeGM+yZPqr9bS3Ifr3dDXV4MUhP643G/Nu5EMzo6iCNU/oRrA2CNs1UZG4UO/H56sCiTrG3pUzxwesST8COMb+vGdQsrp6JfBkurCASATNQZW2jHGL+sw5M/QoOVKEt0UZ73NZFiB jenkins@develop"',
  ],
  require    => Augeas['Set admin password']
}

$jenkins_configfile = "/var/lib/jenkins/config.xml"
augeas {"Set slave port and enable anonymous access":
  require  => Class['jenkins'],
  lens       => 'Xml.lns',
  incl       => $jenkins_configfile,
  context    => "/files$jenkins_configfile",
  changes    => [
    'set hudson/slaveAgentPort/#text "0"',
    'set hudson/authorizationStrategy/denyAnonymousReadAccess/#text "false"',
  ]
}

$jenkins_globalJobDslSecurityConfig = "/var/lib/jenkins/javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration.xml"
file {$jenkins_globalJobDslSecurityConfig:
  owner    => 'jenkins',
  group    => 'jenkins',
  mode     => '0600',
  require  => Class['jenkins'],
  content  => "<?xml version='1.0' encoding='UTF-8'?>
<javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration>
  <category class=\"jenkins.model.GlobalConfigurationCategory\$Security\"/>
  <useScriptSecurity>false</useScriptSecurity>
</javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration>"
}
->
augeas {"Disable Jenkins Job DSL security":
  lens       => 'Xml.lns',
  incl       => $jenkins_globalJobDslSecurityConfig,
  context    => "/files$jenkins_globalJobDslSecurityConfig",
  changes    => [
    'set javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration/useScriptSecurity/#text "false"',
  ]
}

$jenkins_cliConfig = "/var/lib/jenkins/jenkins.CLI.xml"
file {$jenkins_cliConfig:
  owner    => 'jenkins',
  group    => 'jenkins',
  mode     => '0600',
  require  => Class['jenkins'],
  content  => "<?xml version='1.0' encoding='UTF-8'?>
<jenkins.CLI>
  <enabled>true</enabled>
</jenkins.CLI>"
}
->
augeas {"Enable Jenkins CLI":
  lens       => 'Xml.lns',
  incl       => $jenkins_cliConfig,
  context    => "/files$jenkins_cliConfig",
  changes    => [
    'set jenkins.CLI/enabled/#text "true"',
  ]
}


file { '/var/lib/jenkins/.ssh':
  ensure   => directory,
  owner    => 'jenkins',
  group    => 'jenkins',
  mode     => '0755',
  require  => Class['jenkins'],
}

file { '/var/lib/jenkins/.ssh/id_rsa':
  owner    => 'jenkins',
  group    => 'jenkins',
  mode     => '0600',
  require  => File['/var/lib/jenkins/.ssh'],
  content  => "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAqHUflplnDb8PiyD6DayfMU9vuICTrzoeGY/xMRnRwBvnmQBD
AJmf898dXPiN98Ok5cWkhNPQKpI2rSp2nucnr96kiuH7IBFKdZ9+llj63OVeYtcl
7k+hHsfsOUmh1IQ/SIco8ksgH2UeDca8opbli/8PX9wGgVcjxzcn9QvASN8FTy+B
9GQHgUsZrND1uWC4b15UUn2YXErkhHhjPsmT6q/W0tyH693Q11eDFIT+uNxvzbuR
DM6OogjVP6EawNgjbNVGRuFDvx+erAok6xt6VM8cHrEk/AjjG/rxnULK6eiXwZLq
wgEgEzUGVtoxxi/rMOTP0KDlShLdFGe9zWRYgQIDAQABAoIBAHG5wH2XSq9JEWFH
/ghFRaOwkSfqBcoCXle7iYUwfR5IuG3ec11wWT/2nIgrdQyTlDta1tqldJ+I3kjB
phtYyr48fLEWJsdbZP1Lk9ZEc/e1EaeAwCbGs2toZN24C/zA20hHlykb9q+7QDLk
vGy3mniM1QBONkYTYiAX6G3SZRnL/bkc8UPrOteqC30vyS/QWIM+RFkPPM4CI6rz
R5hATyVaiqbz0Ehkfr2bQsnu1rEMrxOubL1s0a+RQpVdJsiSUEKtKScRGI3Iga4/
cE0hMmQ74oTbByJHTomr0sQgNbahA6GRsQ9cmBY3qscq7ggQkCooWBwdRLqefAfP
VdmPG5ECgYEA2iy4Irn9L9okmN5tdEDgBKswzyrEAqobKpqjfc89i+W/Q+8n5jna
SQhQ9YJ0zpI/J3IZvRwcDv6vRmMPOM6GyUwkUViVfR2fu78xETbwpb5Zssz04QYW
zduS/ovdwdxe3ccncd9H2S8fOJVFznx58nji6RIyY3zBVeq+TY/nALMCgYEAxanM
mVa0VkJUDmKEVXm+YU4mBhLCLwU2IKUfPpFE17sBvzPLRXDPwvQdTTjm01HCVgi+
UPGjHNsKk7Ts0Ob+a8ILrwiTM5/NyyPVIK86mDIdVMNF1fKrDFXY5DuR1Q3ej4oj
hjXw/Rckoi6aWibXItlVF59Fd5iTtKDQFHexM/sCgYEAqH0opwjjkvTwlm4QMVt4
paJfS15HiZc866YI5LwLV+LR1vD260F6ZjRZ8YASHQWsaBYh8n2m3Z2qVr1hoAk+
5m47DedPaxRZq3B3wEehiR57vy2xX6aILeqIlrQFShWZ3cRTnglFP2C4x8Xf5xsS
QkNBWaWH7HUICgYDeXrMdykCgYEAoMMHSreAGJ/9qW1q3/ISayWaO1pKYN/GNCrY
DJUt/p90PkQr0SB9ebv9kO70nW5jtoGJ+F9vIGruYU/HQ+h7iLzbr9IzlsskH1HX
Z6vc5ifsPyJKzEV/5Jp1urrQUw3is6/QULnSdKW7/8QTebsZQpisYngBkdGgYEpi
siLfFr0CgYBtvm+d8WgTT0CprpQBg9eiLLKFAUd8gITtf0K61qtTkMhljInqz9Gc
/tz0DmWvhyxSbRyaVGiN73laeZpcsTlzumDEwC1QGtvhQKYveS5W5macAHapLnIj
iN7Xbd1jwzN+z0izalW/4GL5COSuqbAH/CSZhPMoccucNeKl1ASXaQ==
-----END RSA PRIVATE KEY-----
",
}

file { '/var/lib/jenkins/.ssh/id_rsa.pub':
  owner    => 'jenkins',
  group    => 'jenkins',
  mode     => '0644',
  require  => File['/var/lib/jenkins/.ssh'],
  content  => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCodR+WmWcNvw+LIPoNrJ8xT2+4gJOvOh4Zj/ExGdHAG+eZAEMAmZ/z3x1c+I33w6TlxaSE09AqkjatKnae5yev3qSK4fsgEUp1n36WWPrc5V5i1yXuT6Eex+w5SaHUhD9IhyjySyAfZR4NxryiluWL/w9f3AaBVyPHNyf1C8BI3wVPL4H0ZAeBSxms0PW5YLhvXlRSfZhcSuSEeGM+yZPqr9bS3Ifr3dDXV4MUhP643G/Nu5EMzo6iCNU/oRrA2CNs1UZG4UO/H56sCiTrG3pUzxwesST8COMb+vGdQsrp6JfBkurCASATNQZW2jHGL+sw5M/QoOVKEt0UZ73NZFiB jenkins@develop
",
}

file { '/etc/puppet/hieradata/common.yaml':
  require  => File['/var/lib/jenkins/.ssh/id_rsa'],
  owner    => 'root',
  group    => 'root',
  mode     => '0644',
  replace  => 'no',
  content  => "jenkins::cli_ssh_keyfile: '/var/lib/jenkins/.ssh/id_rsa'",
}

file_line {"Hieradata Jenkins CLI SSH Key":
  require           => File['/etc/puppet/hieradata/common.yaml'],
  path              => "/etc/puppet/hieradata/common.yaml",
  # This is a very ugly hack: just add more parameters to the the file name to add them to the Jenkins CLI call
  line              => "jenkins::cli_ssh_keyfile: '/var/lib/jenkins/.ssh/id_rsa -remoting'",
  match             => 'jenkins::cli_ssh_keyfile',
  match_for_absence => true,
}

# Prepare Maven (automatic) installation
file { '/var/lib/jenkins/hudson.tasks.Maven.xml':
  owner    => 'jenkins',
  group    => 'jenkins',
  mode     => '0644',
  require  => Class['jenkins'],
  # notify   => Service['jenkins'],
  content  => "<?xml version='1.0' encoding='UTF-8'?>
<hudson.tasks.Maven_-DescriptorImpl>
  <installations>
    <hudson.tasks.Maven_-MavenInstallation>
      <name>maven-3.3.9</name>
      <properties>
        <hudson.tools.InstallSourceProperty>
          <installers>
            <hudson.tasks.Maven_-MavenInstaller>
              <id>3.3.9</id>
            </hudson.tasks.Maven_-MavenInstaller>
          </installers>
        </hudson.tools.InstallSourceProperty>
      </properties>
    </hudson.tasks.Maven_-MavenInstallation>
  </installations>
</hudson.tasks.Maven_-DescriptorImpl>
",
}
