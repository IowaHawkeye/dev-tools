import sys
import pexpect
import re


child = pexpect.spawn('docker exec --user build -it 4k_1.9 /bin/bash', encoding='utf-8')

prompt="build@4k_1\.9"
child.logfile = sys.stdout
child.expect(prompt)

child.sendline('x86')
child.expect(prompt)

child.sendline('cd /home/build/workspace/br/4K_TRUNK/blade4000/aci4235-e24-1')
child.expect(prompt)

child.sendline('make sim_install')
child.expect(prompt)

child.sendline('exit')
child.expect(prompt)

child.sendline('exit')
print(child.read())

#child.interact()

