# Fry role (runtime)

This role is not run during Packer build. It describes the boot-time (fry) contract.

At instance launch, user data or cloud-init should:

1. Write runtime variables to `/etc/default/nginx-app`, e.g.:
   - APP_NAME
   - ENVIRONMENT
   - MESSAGE

2. Run `/usr/local/bin/render-index.sh` to regenerate the nginx landing page from those variables.

3. Restart nginx: `systemctl restart nginx`.

The EC2 launch template user data in the Terraform ec2-app stack implements this fry step.
